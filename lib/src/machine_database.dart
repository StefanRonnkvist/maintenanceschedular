part of 'package:maintenanceschedular/main.dart';

/// Owns the application database and all persistence operations.
///
/// The singleton lazily opens one shared connection. Public methods keep SQL
/// details and related-table hydration out of the UI layer.
class MachineDatabase {
  MachineDatabase._();

  static const Duration _legacyScoreTimeout = Duration(seconds: 2);

  static final MachineDatabase instance = MachineDatabase._();

  Database? _database;
  Future<Database>? _openingDatabase;

  /// Returns the shared database, coalescing concurrent open requests.
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    if (_openingDatabase != null) {
      return _openingDatabase!;
    }

    _openingDatabase = _open();
    try {
      final opened = await _openingDatabase!;
      _database = opened;
      return opened;
    } finally {
      _openingDatabase = null;
    }
  }

  /// Opens the first viable database path with busy retries and corruption
  /// recovery, then falls back to any existing legacy locations.
  Future<Database> _open() async {
    final candidatePaths = await _databaseFilePaths();
    await _promoteLegacyDatabaseIfNeeded(candidatePaths);
    final openPaths = await _prioritizedOpenPaths(candidatePaths);
    const retryDelays = <Duration>[
      Duration(milliseconds: 150),
      Duration(milliseconds: 350),
      Duration(milliseconds: 700),
      Duration(milliseconds: 1200),
    ];
    const primaryOpenTimeout = Duration(seconds: 5);
    const fallbackOpenTimeout = Duration(seconds: 2);
    Object? lastError;

    for (var index = 0; index < openPaths.length; index++) {
      final fullPath = openPaths[index];
      final isPrimaryPath = index == 0;
      final openTimeout = isPrimaryPath
          ? primaryOpenTimeout
          : fallbackOpenTimeout;

      if (isPrimaryPath) {
        final parentDir = Directory(path.dirname(fullPath));
        try {
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }
        } on Object catch (error) {
          lastError = error;
          continue;
        }
      }

      for (var attempt = 0; attempt <= retryDelays.length; attempt++) {
        try {
          return await _openDatabaseWithTimeout(fullPath, openTimeout);
        } on TimeoutException catch (error) {
          lastError = error;
          break; // Skip to next path if timeout
        } on Object catch (error) {
          lastError = error;

          if (_isDatabaseBusyError(error) && attempt < retryDelays.length) {
            await Future<void>.delayed(retryDelays[attempt]);
            continue;
          }

          if (_isCorruptOrMalformedDatabaseError(error)) {
            try {
              await databaseFactory.deleteDatabase(fullPath);
              return await _openDatabaseWithTimeout(fullPath, openTimeout);
            } catch (_) {
              break; // Skip to next path
            }
          }

          if (_isCannotOpenDatabaseError(error)) {
            break;
          }

          // For any other error, try next path instead of crashing
          break;
        }
      }
    }

    if (lastError != null) {
      throw lastError;
    }
    throw StateError('No candidate database paths were available.');
  }

  /// Copies the best populated legacy database to the preferred location when
  /// the preferred database is missing or empty.
  Future<void> _promoteLegacyDatabaseIfNeeded(
    List<String> candidatePaths,
  ) async {
    if (candidatePaths.length < 2) {
      return;
    }

    final primaryPath = candidatePaths.first;
    final primaryExists = await databaseFactory.databaseExists(primaryPath);
    final primaryDataScore = primaryExists
        ? await _databaseDataScoreWithTimeout(primaryPath)
        : -1;

    if (primaryDataScore > 0) {
      return;
    }

    for (final legacyPath in candidatePaths.skip(1)) {
      if (!await databaseFactory.databaseExists(legacyPath)) {
        continue;
      }

      final legacyDataScore = await _databaseDataScoreWithTimeout(legacyPath);
      final shouldPromote =
          !primaryExists || legacyDataScore > primaryDataScore;
      if (!shouldPromote) {
        continue;
      }

      try {
        final primaryDir = Directory(path.dirname(primaryPath));
        if (!await primaryDir.exists()) {
          await primaryDir.create(recursive: true);
        }

        if (await File(primaryPath).exists()) {
          await File(primaryPath).delete();
        }
        final primaryWal = File('$primaryPath-wal');
        if (await primaryWal.exists()) {
          await primaryWal.delete();
        }
        final primaryShm = File('$primaryPath-shm');
        if (await primaryShm.exists()) {
          await primaryShm.delete();
        }

        await File(legacyPath).copy(primaryPath);

        // WAL/SHM files are optional; copy failures must not block DB open.
        final legacyWal = File('$legacyPath-wal');
        if (await legacyWal.exists()) {
          try {
            await legacyWal.copy('$primaryPath-wal');
          } catch (_) {}
        }

        final legacyShm = File('$legacyPath-shm');
        if (await legacyShm.exists()) {
          try {
            await legacyShm.copy('$primaryPath-shm');
          } catch (_) {}
        }

        return;
      } catch (_) {
        // Best-effort migration only; opening can still proceed via legacy paths.
        continue;
      }
    }
  }

  Future<int> _databaseDataScoreWithTimeout(String fullPath) {
    return _databaseDataScore(
      fullPath,
    ).timeout(_legacyScoreTimeout, onTimeout: () => -1);
  }

  /// Scores useful data with machines taking precedence over components and
  /// tasks, allowing legacy candidates to be compared without full hydration.
  Future<int> _databaseDataScore(String fullPath) async {
    Database? db;
    try {
      db = await databaseFactory.openDatabase(
        fullPath,
        options: OpenDatabaseOptions(readOnly: true),
      );
      final machineCount = await _safeRowCount(db, machineTable);
      final subAssemblyCount = await _safeRowCount(db, subAssemblyTable);
      final taskCount = await _safeRowCount(db, maintenanceTaskTable);
      return machineCount * 1000000 + subAssemblyCount * 1000 + taskCount;
    } catch (_) {
      return -1;
    } finally {
      if (db != null) {
        await db.close();
      }
    }
  }

  Future<int> _safeRowCount(Database db, String tableName) async {
    try {
      final rows = await db.rawQuery('SELECT COUNT(*) AS cnt FROM $tableName');
      return (rows.firstOrNull?['cnt'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  bool _isDatabaseBusyError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('database is locked') ||
        message.contains('database locked') ||
        message.contains('database_busy') ||
        message.contains('busy timeout') ||
        message.contains('sql_busy');
  }

  bool _isCorruptOrMalformedDatabaseError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('database disk image is malformed') ||
        message.contains('file is not a database') ||
        message.contains('database corrupt') ||
        message.contains('sql_corrupt');
  }

  bool _isCannotOpenDatabaseError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('unable to open database file') ||
        message.contains('sql_cantopen') ||
        message.contains('cannot open') ||
        message.contains('permission denied') ||
        message.contains('access is denied');
  }

  Future<List<String>> _prioritizedOpenPaths(
    List<String> candidatePaths,
  ) async {
    if (candidatePaths.isEmpty) {
      return const [];
    }

    final openPaths = <String>[candidatePaths.first];
    for (final fullPath in candidatePaths.skip(1)) {
      if (await databaseFactory.databaseExists(fullPath)) {
        openPaths.add(fullPath);
      }
    }
    return openPaths;
  }

  Future<Database> _openDatabaseWithTimeout(String fullPath, Duration timeout) {
    return _openDatabaseAtPath(fullPath).timeout(
      timeout,
      onTimeout: () {
        throw TimeoutException('Database open timeout at $fullPath', timeout);
      },
    );
  }

  Future<Database> _openDatabaseAtPath(String fullPath) {
    return openRegistryDatabase(databaseFactory, fullPath);
  }

  Future<String> _databaseFilePath() async {
    if (kIsWeb) {
      return dbName;
    }

    final candidates = await _databaseFilePaths();
    final fullPath = candidates.first;
    final dir = Directory(path.dirname(fullPath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return fullPath;
  }

  /// Returns de-duplicated database locations in preferred opening order.
  Future<List<String>> _databaseFilePaths() async {
    if (kIsWeb) {
      return [dbName];
    }

    final candidates = <String>[];

    // Use an app-owned, stable location first on Windows so debug/release
    // builds resolve to the same database path.
    if (Platform.isWindows) {
      candidates.add(path.join(_fallbackDatabaseDirectoryPath(), dbName));
    }

    try {
      final dbPath = await getDatabasesPath();
      if (dbPath.trim().isNotEmpty) {
        candidates.add(path.join(dbPath, dbName));
      }
    } catch (_) {
      // Fall through to explicit fallback candidates.
    }

    if (!Platform.isWindows) {
      candidates.add(path.join(_fallbackDatabaseDirectoryPath(), dbName));
    }
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null && localAppData.trim().isNotEmpty) {
      candidates.add(
        path.join(localAppData, 'maintenanceschedular', 'databases', dbName),
      );
    }
    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.trim().isNotEmpty) {
      candidates.add(
        path.join(appData, 'maintenanceschedular', 'databases', dbName),
      );
    }
    candidates.add(
      path.join(
        Directory.systemTemp.path,
        'maintenanceschedular',
        'databases',
        dbName,
      ),
    );
    candidates.add(path.join(Directory.current.path, 'databases', dbName));
    candidates.addAll(_legacyWorkspaceDatabaseCandidates());

    final seen = <String>{};
    return candidates.where((candidate) => seen.add(candidate)).toList();
  }

  List<String> _legacyWorkspaceDatabaseCandidates() {
    final candidates = <String>[];
    var current = Directory.current;

    // Walk up a few parent folders so release binaries launched from
    // build/windows/... can still locate DB files created at workspace level.
    for (var depth = 0; depth < 8; depth++) {
      final currentPath = current.path;
      candidates.add(path.join(currentPath, 'databases', dbName));
      candidates.add(
        path.join(
          currentPath,
          '.dart_tool',
          'sqflite_common_ffi',
          'databases',
          dbName,
        ),
      );

      final parent = current.parent;
      if (parent.path == currentPath) {
        break;
      }
      current = parent;
    }

    return candidates;
  }

  String _fallbackDatabaseDirectoryPath() {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null && localAppData.trim().isNotEmpty) {
      return path.join(localAppData, 'maintenanceschedular', 'databases');
    }

    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null && userProfile.trim().isNotEmpty) {
      return path.join(
        userProfile,
        'AppData',
        'Local',
        'maintenanceschedular',
        'databases',
      );
    }

    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.trim().isNotEmpty) {
      return path.join(appData, 'maintenanceschedular', 'databases');
    }

    return path.join(
      Directory.systemTemp.path,
      'maintenanceschedular',
      'databases',
    );
  }

  Future<bool> databaseFileExists() async {
    if (kIsWeb) {
      return false;
    }

    final fullPath = await _databaseFilePath();
    return databaseFactory.databaseExists(fullPath);
  }

  /// Loads machines and hydrates their licenses, components, and tasks in
  /// grouped queries to avoid one query per parent record.
  Future<List<Machine>> getMachines() async {
    final db = await database;
    final machineRows = await db.query(machineTable, orderBy: 'id DESC');
    if (machineRows.isEmpty) {
      return [];
    }

    final machineIds = machineRows
        .map((row) => row['id'])
        .whereType<int>()
        .toList(growable: false);
    final placeholders = List.filled(machineIds.length, '?').join(', ');
    final machineLicenseRows = await db.rawQuery(
      'SELECT machineId, licenseName FROM $machineRequiredLicenseTable WHERE machineId IN ($placeholders) ORDER BY licenseName COLLATE NOCASE ASC',
      machineIds,
    );

    final groupedMachineLicenses = <int, List<String>>{};
    for (final row in machineLicenseRows) {
      final machineId = row['machineId'] as int?;
      final licenseName = (row['licenseName'] as String?)?.trim() ?? '';
      if (machineId == null || licenseName.isEmpty) {
        continue;
      }

      groupedMachineLicenses.putIfAbsent(machineId, () => []).add(licenseName);
    }

    final subAssemblyRows = await db.rawQuery(
      'SELECT * FROM $subAssemblyTable WHERE machineId IN ($placeholders) ORDER BY id ASC',
      machineIds,
    );

    final subAssemblyIds = subAssemblyRows
        .map((row) => row['id'])
        .whereType<int>()
        .toList(growable: false);
    final groupedTasks = <int, List<MaintenanceTask>>{};

    if (subAssemblyIds.isNotEmpty) {
      final taskPlaceholders = List.filled(
        subAssemblyIds.length,
        '?',
      ).join(', ');
      final taskRows = await db.rawQuery(
        'SELECT * FROM $maintenanceTaskTable WHERE subAssemblyId IN ($taskPlaceholders) ORDER BY id ASC',
        subAssemblyIds,
      );

      for (final row in taskRows) {
        final task = MaintenanceTask.fromMap(row);
        final subAssemblyId = task.subAssemblyId;
        if (subAssemblyId == null) {
          continue;
        }

        groupedTasks.putIfAbsent(subAssemblyId, () => []).add(task);
      }
    }

    final groupedSubAssemblies = <int, List<SubAssembly>>{};
    for (final row in subAssemblyRows) {
      final subAssemblyBase = SubAssembly.fromMap(row);
      final subAssembly = subAssemblyBase.copyWith(
        maintenanceTasks: groupedTasks[subAssemblyBase.id] ?? const [],
      );
      final machineId = subAssembly.machineId;
      if (machineId == null) {
        continue;
      }

      groupedSubAssemblies.putIfAbsent(machineId, () => []).add(subAssembly);
    }

    return machineRows
        .map((row) {
          final machine = Machine.fromMap(row);
          return machine.copyWith(
            additionalRequiredLicenses:
                groupedMachineLicenses[machine.id] ?? const [],
            subAssemblies: groupedSubAssemblies[machine.id] ?? const [],
          );
        })
        .toList(growable: false);
  }

  /// Loads employees and attaches their skills and licenses.
  Future<List<Employee>> getEmployees() async {
    final db = await database;
    final employeeRows = await db.query(
      employeeTable,
      orderBy: 'name COLLATE NOCASE ASC, id ASC',
    );
    if (employeeRows.isEmpty) {
      return const [];
    }

    final employeeIds = employeeRows
        .map((row) => row['id'])
        .whereType<int>()
        .toList(growable: false);
    final placeholders = List.filled(employeeIds.length, '?').join(', ');
    final skillRows = await db.rawQuery(
      'SELECT employeeId, skillName FROM $employeeSkillTable WHERE employeeId IN ($placeholders) ORDER BY skillName COLLATE NOCASE ASC',
      employeeIds,
    );
    final licenseRows = await db.rawQuery(
      'SELECT employeeId, licenseName FROM $employeeRequiredLicenseTable WHERE employeeId IN ($placeholders) ORDER BY licenseName COLLATE NOCASE ASC',
      employeeIds,
    );

    final groupedSkills = <int, List<String>>{};
    for (final row in skillRows) {
      final employeeId = row['employeeId'] as int?;
      final skillName = (row['skillName'] as String?)?.trim() ?? '';
      if (employeeId == null || skillName.isEmpty) {
        continue;
      }
      groupedSkills.putIfAbsent(employeeId, () => []).add(skillName);
    }

    final groupedLicenses = <int, List<String>>{};
    for (final row in licenseRows) {
      final employeeId = row['employeeId'] as int?;
      final licenseName = (row['licenseName'] as String?)?.trim() ?? '';
      if (employeeId == null || licenseName.isEmpty) {
        continue;
      }
      groupedLicenses.putIfAbsent(employeeId, () => []).add(licenseName);
    }

    return employeeRows
        .map((row) {
          final employee = Employee.fromMap(row);
          return employee.copyWith(
            skills: groupedSkills[employee.id] ?? const [],
            licenses: groupedLicenses[employee.id] ?? const [],
          );
        })
        .toList(growable: false);
  }

  Future<List<String>> getSkillTypes() async {
    final db = await database;
    final rows = await db.query(
      skillTypeTable,
      columns: ['name'],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows
        .map((row) => (row['name'] as String?)?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> ensureDefaultSkillTypes(List<String> defaults) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final candidate in defaults) {
        final normalized = candidate.trim();
        if (normalized.isEmpty) {
          continue;
        }

        final existing = await txn.query(
          skillTypeTable,
          columns: ['id'],
          where: 'UPPER(name) = ?',
          whereArgs: [normalized.toUpperCase()],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          continue;
        }

        await txn.insert(skillTypeTable, {
          'name': normalized,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<String?> addSkillType(String skillType) async {
    final normalized = skillType.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final db = await database;
    return db.transaction((txn) async {
      final existing = await txn.query(
        skillTypeTable,
        columns: ['name'],
        where: 'UPPER(name) = ?',
        whereArgs: [normalized.toUpperCase()],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return (existing.first['name'] as String?)?.trim() ?? normalized;
      }

      await txn.insert(skillTypeTable, {
        'name': normalized,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      return normalized;
    });
  }

  Future<String?> renameSkillType(String oldName, String newName) async {
    final oldNormalized = oldName.trim();
    final newNormalized = newName.trim();
    if (oldNormalized.isEmpty || newNormalized.isEmpty) {
      return null;
    }

    final oldUpper = oldNormalized.toUpperCase();
    final newUpper = newNormalized.toUpperCase();

    final db = await database;
    return db.transaction((txn) async {
      final existingOldType = await txn.query(
        skillTypeTable,
        columns: ['name'],
        where: 'UPPER(name) = ?',
        whereArgs: [oldUpper],
        limit: 1,
      );
      final existingNewType = await txn.query(
        skillTypeTable,
        columns: ['name'],
        where: 'UPPER(name) = ?',
        whereArgs: [newUpper],
        limit: 1,
      );

      final canonicalNewName = existingNewType.isNotEmpty
          ? ((existingNewType.first['name'] as String?)?.trim() ??
                newNormalized)
          : newNormalized;

      final oldEmployeeRows = await txn.query(
        employeeSkillTable,
        columns: ['employeeId'],
        where: 'UPPER(skillName) = ?',
        whereArgs: [oldUpper],
      );

      for (final row in oldEmployeeRows) {
        final employeeId = row['employeeId'] as int?;
        if (employeeId == null) {
          continue;
        }

        await txn.insert(employeeSkillTable, {
          'employeeId': employeeId,
          'skillName': canonicalNewName,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      await txn.delete(
        employeeSkillTable,
        where: 'UPPER(skillName) = ?',
        whereArgs: [oldUpper],
      );

      if (existingOldType.isNotEmpty) {
        if (existingNewType.isEmpty) {
          await txn.update(
            skillTypeTable,
            {'name': canonicalNewName},
            where: 'UPPER(name) = ?',
            whereArgs: [oldUpper],
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        } else {
          await txn.delete(
            skillTypeTable,
            where: 'UPPER(name) = ?',
            whereArgs: [oldUpper],
          );
        }
      } else if (existingNewType.isEmpty) {
        await txn.insert(skillTypeTable, {
          'name': canonicalNewName,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      return canonicalNewName;
    });
  }

  Future<int> getEmployeeSkillUsageCount(String skillType) async {
    final normalized = skillType.trim();
    if (normalized.isEmpty) {
      return 0;
    }

    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(DISTINCT employeeId) AS cnt FROM $employeeSkillTable WHERE UPPER(skillName) = ?',
      [normalized.toUpperCase()],
    );
    return (rows.firstOrNull?['cnt'] as int?) ?? 0;
  }

  Future<int> deleteSkillType(String skillType) async {
    final normalized = skillType.trim();
    if (normalized.isEmpty) {
      return 0;
    }

    final upper = normalized.toUpperCase();
    final db = await database;
    return db.transaction((txn) async {
      final removedMappings = await txn.delete(
        employeeSkillTable,
        where: 'UPPER(skillName) = ?',
        whereArgs: [upper],
      );
      await txn.delete(
        skillTypeTable,
        where: 'UPPER(name) = ?',
        whereArgs: [upper],
      );
      return removedMappings;
    });
  }

  Future<List<String>> getLicenseTypes() async {
    final db = await database;
    final rows = await db.query(
      licenseTypeTable,
      columns: ['name'],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows
        .map((row) => (row['name'] as String?)?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> ensureDefaultLicenseTypes(List<String> defaults) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final candidate in defaults) {
        final normalized = candidate.trim();
        if (normalized.isEmpty) {
          continue;
        }

        final existing = await txn.query(
          licenseTypeTable,
          columns: ['id'],
          where: 'UPPER(name) = ?',
          whereArgs: [normalized.toUpperCase()],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          continue;
        }

        await txn.insert(licenseTypeTable, {
          'name': normalized,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<String?> addLicenseType(String licenseType) async {
    final normalized = licenseType.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final db = await database;
    return db.transaction((txn) async {
      final existing = await txn.query(
        licenseTypeTable,
        columns: ['name'],
        where: 'UPPER(name) = ?',
        whereArgs: [normalized.toUpperCase()],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return (existing.first['name'] as String?)?.trim() ?? normalized;
      }

      await txn.insert(licenseTypeTable, {
        'name': normalized,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      return normalized;
    });
  }

  Future<int> getMachineRequiredLicenseUsageCount(String licenseType) async {
    final normalized = licenseType.trim();
    if (normalized.isEmpty) {
      return 0;
    }

    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(DISTINCT machineId) AS cnt FROM $machineRequiredLicenseTable WHERE UPPER(licenseName) = ?',
      [normalized.toUpperCase()],
    );
    return (rows.firstOrNull?['cnt'] as int?) ?? 0;
  }

  Future<String?> renameLicenseType(String oldName, String newName) async {
    final oldNormalized = oldName.trim();
    final newNormalized = newName.trim();
    if (oldNormalized.isEmpty || newNormalized.isEmpty) {
      return null;
    }

    final oldUpper = oldNormalized.toUpperCase();
    final newUpper = newNormalized.toUpperCase();

    final db = await database;
    return db.transaction((txn) async {
      final existingOldType = await txn.query(
        licenseTypeTable,
        columns: ['name'],
        where: 'UPPER(name) = ?',
        whereArgs: [oldUpper],
        limit: 1,
      );
      final existingNewType = await txn.query(
        licenseTypeTable,
        columns: ['name'],
        where: 'UPPER(name) = ?',
        whereArgs: [newUpper],
        limit: 1,
      );

      final canonicalNewName = existingNewType.isNotEmpty
          ? ((existingNewType.first['name'] as String?)?.trim() ??
                newNormalized)
          : newNormalized;

      final oldMachineRows = await txn.query(
        machineRequiredLicenseTable,
        columns: ['machineId'],
        where: 'UPPER(licenseName) = ?',
        whereArgs: [oldUpper],
      );

      for (final row in oldMachineRows) {
        final machineId = row['machineId'] as int?;
        if (machineId == null) {
          continue;
        }

        await txn.insert(machineRequiredLicenseTable, {
          'machineId': machineId,
          'licenseName': canonicalNewName,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      await txn.delete(
        machineRequiredLicenseTable,
        where: 'UPPER(licenseName) = ?',
        whereArgs: [oldUpper],
      );

      if (existingOldType.isNotEmpty) {
        if (existingNewType.isEmpty) {
          await txn.update(
            licenseTypeTable,
            {'name': canonicalNewName},
            where: 'UPPER(name) = ?',
            whereArgs: [oldUpper],
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        } else {
          await txn.delete(
            licenseTypeTable,
            where: 'UPPER(name) = ?',
            whereArgs: [oldUpper],
          );
        }
      } else if (existingNewType.isEmpty) {
        await txn.insert(licenseTypeTable, {
          'name': canonicalNewName,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      return canonicalNewName;
    });
  }

  Future<int> deleteLicenseType(String licenseType) async {
    final normalized = licenseType.trim();
    if (normalized.isEmpty) {
      return 0;
    }

    final upper = normalized.toUpperCase();
    final db = await database;
    return db.transaction((txn) async {
      final removedMappings = await txn.delete(
        machineRequiredLicenseTable,
        where: 'UPPER(licenseName) = ?',
        whereArgs: [upper],
      );
      await txn.delete(
        licenseTypeTable,
        where: 'UPPER(name) = ?',
        whereArgs: [upper],
      );
      return removedMappings;
    });
  }

  Future<void> _replaceMachineRequiredLicenses(
    Transaction txn,
    int machineId,
    Iterable<String> licenseNames,
  ) async {
    await txn.delete(
      machineRequiredLicenseTable,
      where: 'machineId = ?',
      whereArgs: [machineId],
    );

    final uniqueNames = <String>{
      for (final name in licenseNames)
        if (name.trim().isNotEmpty) name.trim(),
    };

    for (final licenseName in uniqueNames) {
      final existingType = await txn.query(
        licenseTypeTable,
        columns: ['id'],
        where: 'UPPER(name) = ?',
        whereArgs: [licenseName.toUpperCase()],
        limit: 1,
      );
      if (existingType.isEmpty) {
        await txn.insert(licenseTypeTable, {
          'name': licenseName,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      await txn.insert(machineRequiredLicenseTable, {
        'machineId': machineId,
        'licenseName': licenseName,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _replaceEmployeeSkills(
    Transaction txn,
    int employeeId,
    Iterable<String> skills,
  ) async {
    await txn.delete(
      employeeSkillTable,
      where: 'employeeId = ?',
      whereArgs: [employeeId],
    );

    final uniqueSkills = <String>{
      for (final skill in skills)
        if (skill.trim().isNotEmpty) skill.trim(),
    };

    for (final skillName in uniqueSkills) {
      final existingType = await txn.query(
        skillTypeTable,
        columns: ['id'],
        where: 'UPPER(name) = ?',
        whereArgs: [skillName.toUpperCase()],
        limit: 1,
      );
      if (existingType.isEmpty) {
        await txn.insert(skillTypeTable, {
          'name': skillName,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      await txn.insert(employeeSkillTable, {
        'employeeId': employeeId,
        'skillName': skillName,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _replaceEmployeeRequiredLicenses(
    Transaction txn,
    int employeeId,
    Iterable<String> licenseNames,
  ) async {
    await txn.delete(
      employeeRequiredLicenseTable,
      where: 'employeeId = ?',
      whereArgs: [employeeId],
    );

    final uniqueNames = <String>{
      for (final name in licenseNames)
        if (name.trim().isNotEmpty) name.trim(),
    };

    for (final licenseName in uniqueNames) {
      final existingType = await txn.query(
        licenseTypeTable,
        columns: ['id'],
        where: 'UPPER(name) = ?',
        whereArgs: [licenseName.toUpperCase()],
        limit: 1,
      );
      if (existingType.isEmpty) {
        await txn.insert(licenseTypeTable, {
          'name': licenseName,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      await txn.insert(employeeRequiredLicenseTable, {
        'employeeId': employeeId,
        'licenseName': licenseName,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<Employee> insertEmployee(Employee employee) async {
    final db = await database;
    return db.transaction((txn) async {
      final employeeId = await txn.insert(
        employeeTable,
        employee.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      await _replaceEmployeeSkills(txn, employeeId, employee.skills);
      await _replaceEmployeeRequiredLicenses(
        txn,
        employeeId,
        employee.licenses,
      );
      return employee.copyWith(id: employeeId);
    });
  }

  Future<void> insertEmployees(List<Employee> employees) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final employee in employees) {
        final employeeId = await txn.insert(
          employeeTable,
          employee.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        await _replaceEmployeeSkills(txn, employeeId, employee.skills);
        await _replaceEmployeeRequiredLicenses(
          txn,
          employeeId,
          employee.licenses,
        );
      }
    });
  }

  Future<void> replaceAllEmployees(List<Employee> employees) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(employeeRequiredLicenseTable);
      await txn.delete(employeeSkillTable);
      await txn.delete(employeeTable);

      for (final employee in employees) {
        final employeeId = await txn.insert(
          employeeTable,
          employee.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        await _replaceEmployeeSkills(txn, employeeId, employee.skills);
        await _replaceEmployeeRequiredLicenses(
          txn,
          employeeId,
          employee.licenses,
        );
      }
    });
  }

  Future<int> updateEmployee(Employee employee) async {
    final db = await database;
    return db.transaction((txn) async {
      final changed = await txn.update(
        employeeTable,
        employee.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [employee.id],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      if (employee.id != null) {
        await _replaceEmployeeSkills(txn, employee.id!, employee.skills);
        await _replaceEmployeeRequiredLicenses(
          txn,
          employee.id!,
          employee.licenses,
        );
      }

      return changed;
    });
  }

  Future<int> deleteEmployee(int id) async {
    final db = await database;
    return db.transaction((txn) async {
      await txn.delete(
        employeeSkillTable,
        where: 'employeeId = ?',
        whereArgs: [id],
      );
      await txn.delete(
        employeeRequiredLicenseTable,
        where: 'employeeId = ?',
        whereArgs: [id],
      );
      await txn.delete(
        workOrderTaskAssignmentTable,
        where: 'assigneeValue LIKE ?',
        whereArgs: ['$id|%'],
      );
      return txn.delete(employeeTable, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<String>> getComponentTypes() async {
    final db = await database;
    final rows = await db.query(
      componentTypeTable,
      columns: ['name'],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows
        .map((row) => (row['name'] as String?)?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> ensureDefaultComponentTypes(List<String> defaults) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final candidate in defaults) {
        final normalized = candidate.trim();
        if (normalized.isEmpty) {
          continue;
        }

        final existing = await txn.query(
          componentTypeTable,
          columns: ['id'],
          where: 'UPPER(name) = ?',
          whereArgs: [normalized.toUpperCase()],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          continue;
        }

        await txn.insert(componentTypeTable, {
          'name': normalized,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<String?> addComponentType(String componentType) async {
    final normalized = componentType.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final db = await database;
    return db.transaction((txn) async {
      final existing = await txn.query(
        componentTypeTable,
        columns: ['name'],
        where: 'UPPER(name) = ?',
        whereArgs: [normalized.toUpperCase()],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return (existing.first['name'] as String?)?.trim() ?? normalized;
      }

      await txn.insert(componentTypeTable, {
        'name': normalized,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      return normalized;
    });
  }

  Future<List<String>> getSuperCategoryTypes() async {
    final db = await database;
    final rows = await db.query(
      superCategoryTypeTable,
      columns: ['name'],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows
        .map((row) => (row['name'] as String?)?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> ensureDefaultSuperCategoryTypes(List<String> defaults) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final candidate in defaults) {
        final normalized = candidate.trim();
        if (normalized.isEmpty) {
          continue;
        }

        final existing = await txn.query(
          superCategoryTypeTable,
          columns: ['id'],
          where: 'UPPER(name) = ?',
          whereArgs: [normalized.toUpperCase()],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          continue;
        }

        await txn.insert(superCategoryTypeTable, {
          'name': normalized,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<String?> addSuperCategoryType(String superCategory) async {
    final normalized = superCategory.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final db = await database;
    return db.transaction((txn) async {
      final existing = await txn.query(
        superCategoryTypeTable,
        columns: ['name'],
        where: 'UPPER(name) = ?',
        whereArgs: [normalized.toUpperCase()],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return (existing.first['name'] as String?)?.trim() ?? normalized;
      }

      await txn.insert(superCategoryTypeTable, {
        'name': normalized,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      return normalized;
    });
  }

  Future<int> updateSubAssemblySuperCategory({
    required int subAssemblyId,
    required String superCategory,
  }) async {
    final normalized = superCategory.trim();
    final db = await database;
    return db.transaction((txn) async {
      if (normalized.isNotEmpty) {
        final existing = await txn.query(
          superCategoryTypeTable,
          columns: ['id'],
          where: 'UPPER(name) = ?',
          whereArgs: [normalized.toUpperCase()],
          limit: 1,
        );
        if (existing.isEmpty) {
          await txn.insert(superCategoryTypeTable, {
            'name': normalized,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }

      return txn.update(
        subAssemblyTable,
        {'superCategory': normalized},
        where: 'id = ?',
        whereArgs: [subAssemblyId],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });
  }

  Future<int> getSubAssemblySuperCategoryUsageCount(
    String superCategory,
  ) async {
    final normalized = superCategory.trim();
    if (normalized.isEmpty) {
      return 0;
    }

    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM $subAssemblyTable WHERE UPPER(superCategory) = ?',
      [normalized.toUpperCase()],
    );
    return (rows.firstOrNull?['cnt'] as int?) ?? 0;
  }

  Future<int> deleteSuperCategoryType(String superCategory) async {
    final normalized = superCategory.trim();
    if (normalized.isEmpty) {
      return 0;
    }

    final db = await database;
    return db.delete(
      superCategoryTypeTable,
      where: 'UPPER(name) = ?',
      whereArgs: [normalized.toUpperCase()],
    );
  }

  Future<void> syncSuperCategoryTypesFromSubAssemblies() async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT TRIM(superCategory) AS name FROM $subAssemblyTable WHERE TRIM(superCategory) != ''",
    );

    await db.transaction((txn) async {
      for (final row in rows) {
        final candidate = (row['name'] as String?)?.trim() ?? '';
        if (candidate.isEmpty) {
          continue;
        }

        final existing = await txn.query(
          superCategoryTypeTable,
          columns: ['id'],
          where: 'UPPER(name) = ?',
          whereArgs: [candidate.toUpperCase()],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          continue;
        }

        await txn.insert(superCategoryTypeTable, {
          'name': candidate,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<List<String>> getMaintenanceTaskTypes() async {
    final db = await database;
    final rows = await db.query(
      maintenanceTaskTypeTable,
      columns: ['name'],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows
        .map((row) => (row['name'] as String?)?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> ensureDefaultMaintenanceTaskTypes(List<String> defaults) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final candidate in defaults) {
        final normalized = candidate.trim();
        if (normalized.isEmpty) {
          continue;
        }

        final existing = await txn.query(
          maintenanceTaskTypeTable,
          columns: ['id'],
          where: 'UPPER(name) = ?',
          whereArgs: [normalized.toUpperCase()],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          continue;
        }

        await txn.insert(maintenanceTaskTypeTable, {
          'name': normalized,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<String?> addMaintenanceTaskType(String taskType) async {
    final normalized = taskType.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final db = await database;
    return db.transaction((txn) async {
      final existing = await txn.query(
        maintenanceTaskTypeTable,
        columns: ['name'],
        where: 'UPPER(name) = ?',
        whereArgs: [normalized.toUpperCase()],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        return (existing.first['name'] as String?)?.trim() ?? normalized;
      }

      await txn.insert(maintenanceTaskTypeTable, {
        'name': normalized,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      return normalized;
    });
  }

  Future<int> getMaintenanceTaskTypeUsageCount(String taskType) async {
    final normalized = taskType.trim();
    if (normalized.isEmpty) {
      return 0;
    }

    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM $maintenanceTaskTable WHERE UPPER(taskType) = ?',
      [normalized.toUpperCase()],
    );
    return (rows.firstOrNull?['cnt'] as int?) ?? 0;
  }

  Future<int> deleteMaintenanceTaskType(String taskType) async {
    final normalized = taskType.trim();
    if (normalized.isEmpty) {
      return 0;
    }

    final db = await database;
    return db.delete(
      maintenanceTaskTypeTable,
      where: 'UPPER(name) = ?',
      whereArgs: [normalized.toUpperCase()],
    );
  }

  Future<void> syncMaintenanceTaskTypesFromTasks() async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT TRIM(taskType) AS name FROM $maintenanceTaskTable WHERE TRIM(taskType) != ''",
    );

    await db.transaction((txn) async {
      for (final row in rows) {
        final candidate = (row['name'] as String?)?.trim() ?? '';
        if (candidate.isEmpty) {
          continue;
        }

        final existing = await txn.query(
          maintenanceTaskTypeTable,
          columns: ['id'],
          where: 'UPPER(name) = ?',
          whereArgs: [candidate.toUpperCase()],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          continue;
        }

        await txn.insert(maintenanceTaskTypeTable, {
          'name': candidate,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<int> updateSubAssemblyComponentType({
    required int subAssemblyId,
    required String componentType,
  }) async {
    final normalized = componentType.trim();
    final db = await database;
    return db.transaction((txn) async {
      if (normalized.isNotEmpty) {
        final existing = await txn.query(
          componentTypeTable,
          columns: ['id'],
          where: 'UPPER(name) = ?',
          whereArgs: [normalized.toUpperCase()],
          limit: 1,
        );
        if (existing.isEmpty) {
          await txn.insert(componentTypeTable, {
            'name': normalized,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }

      return txn.update(
        subAssemblyTable,
        {'componentType': normalized},
        where: 'id = ?',
        whereArgs: [subAssemblyId],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });
  }

  Future<int> getSubAssemblyComponentTypeUsageCount(
    String componentType,
  ) async {
    final normalized = componentType.trim();
    if (normalized.isEmpty) {
      return 0;
    }

    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM $subAssemblyTable WHERE UPPER(componentType) = ?',
      [normalized.toUpperCase()],
    );
    return (rows.firstOrNull?['cnt'] as int?) ?? 0;
  }

  Future<int> deleteComponentType(String componentType) async {
    final normalized = componentType.trim();
    if (normalized.isEmpty) {
      return 0;
    }

    final db = await database;
    return db.delete(
      componentTypeTable,
      where: 'UPPER(name) = ?',
      whereArgs: [normalized.toUpperCase()],
    );
  }

  Future<void> syncComponentTypesFromSubAssemblies() async {
    final db = await database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT TRIM(componentType) AS name FROM $subAssemblyTable WHERE TRIM(componentType) != ''",
    );

    await db.transaction((txn) async {
      for (final row in rows) {
        final candidate = (row['name'] as String?)?.trim() ?? '';
        if (candidate.isEmpty) {
          continue;
        }

        final existing = await txn.query(
          componentTypeTable,
          columns: ['id'],
          where: 'UPPER(name) = ?',
          whereArgs: [candidate.toUpperCase()],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          continue;
        }

        await txn.insert(componentTypeTable, {
          'name': candidate,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<Machine> insertMachine(Machine machine) async {
    final db = await database;
    return db.transaction((txn) async {
      final machineId = await txn.insert(
        machineTable,
        machine.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      await _replaceMachineRequiredLicenses(
        txn,
        machineId,
        machine.additionalRequiredLicenses,
      );

      for (final subAssembly in machine.subAssemblies) {
        final subAssemblyId = await txn.insert(
          subAssemblyTable,
          subAssembly.copyWith(machineId: machineId).toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        for (final task in subAssembly.maintenanceTasks) {
          await txn.insert(
            maintenanceTaskTable,
            task.copyWith(subAssemblyId: subAssemblyId).toMap()..remove('id'),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
      }

      return machine.copyWith(id: machineId);
    });
  }

  Future<void> insertMachines(List<Machine> machines) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final machine in machines) {
        final machineId = await txn.insert(
          machineTable,
          machine.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        if (machineId <= 0) {
          continue;
        }

        await _replaceMachineRequiredLicenses(
          txn,
          machineId,
          machine.additionalRequiredLicenses,
        );

        for (final subAssembly in machine.subAssemblies) {
          final subAssemblyId = await txn.insert(
            subAssemblyTable,
            subAssembly.copyWith(machineId: machineId).toMap()..remove('id'),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );

          if (subAssemblyId <= 0) {
            continue;
          }

          for (final task in subAssembly.maintenanceTasks) {
            await txn.insert(
              maintenanceTaskTable,
              task.copyWith(subAssemblyId: subAssemblyId).toMap()..remove('id'),
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
          }
        }
      }
    });
  }

  Future<void> replaceAllMachines(List<Machine> machines) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(workOrderStatusTable);
      await txn.delete(workOrderTaskAssignmentTable);
      await txn.delete(machineDetailHistoryTable);
      await txn.delete(subAssemblyDetailHistoryTable);
      await txn.delete(maintenanceTaskTable);
      await txn.delete(subAssemblyTable);
      await txn.delete(machineRequiredLicenseTable);
      await txn.delete(machineTable);

      for (final machine in machines) {
        final machineId = await txn.insert(
          machineTable,
          machine.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        await _replaceMachineRequiredLicenses(
          txn,
          machineId,
          machine.additionalRequiredLicenses,
        );

        for (final subAssembly in machine.subAssemblies) {
          final subAssemblyId = await txn.insert(
            subAssemblyTable,
            subAssembly.copyWith(machineId: machineId).toMap()..remove('id'),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );

          for (final task in subAssembly.maintenanceTasks) {
            await txn.insert(
              maintenanceTaskTable,
              task.copyWith(subAssemblyId: subAssemblyId).toMap()..remove('id'),
              conflictAlgorithm: ConflictAlgorithm.abort,
            );
          }
        }
      }
    });
  }

  Future<bool> hasMachineDetailHistory() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM $machineDetailHistoryTable',
    );
    return rows.isNotEmpty && (rows.first['cnt'] as int? ?? 0) > 0;
  }

  static String _isoDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// Inserts randomly generated historical detail entries for [machines] and
  /// all of their sub-assemblies. Designed to be called once on first launch
  /// to populate plausible back-dated history for sample/demo data.
  Future<void> insertSampleHistory(List<Machine> machines, Random rng) async {
    final db = await database;
    final now = DateTime.now().toUtc();
    await db.transaction((txn) async {
      for (final machine in machines) {
        final machineId = machine.id;
        if (machineId == null) continue;

        final baseOpHours = int.tryParse(machine.operatingHours) ?? 1200;
        final baseIdleHours = int.tryParse(machine.idleHours) ?? 150;
        final machineHistoryCount = rng.nextInt(7) + 2; // 2–8 entries
        var daysAccumulated = 0;
        for (int i = machineHistoryCount; i >= 1; i--) {
          daysAccumulated += rng.nextInt(31) + 15; // 15–45 days per step
          final opHours = (baseOpHours - i * (rng.nextInt(51) + 20)).clamp(
            0,
            999999,
          );
          final idleHours = (baseIdleHours - i * (rng.nextInt(11) + 3)).clamp(
            0,
            999999,
          );
          final checkDate = DateTime.now().subtract(
            Duration(days: daysAccumulated),
          );
          final recordedAt = now.subtract(
            Duration(days: daysAccumulated, hours: rng.nextInt(24)),
          );
          await txn.insert(machineDetailHistoryTable, {
            'machineId': machineId,
            'operatingHours': '$opHours',
            'idleHours': '$idleHours',
            'lastCheckDate': _isoDate(checkDate),
            'recordedAtUtc': recordedAt.toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }

        for (final subAssembly in machine.subAssemblies) {
          final subId = subAssembly.id;
          if (subId == null) continue;

          final baseSubOpHours =
              int.tryParse(subAssembly.operatingHours) ?? 200;
          final baseSubIdleHours = int.tryParse(subAssembly.idleHours) ?? 25;
          final subHistoryCount = rng.nextInt(5) + 1; // 1–5 entries
          var subDaysAccumulated = 0;
          for (int i = subHistoryCount; i >= 1; i--) {
            subDaysAccumulated += rng.nextInt(46) + 20; // 20–65 days per step
            final opHours = (baseSubOpHours - i * (rng.nextInt(31) + 10)).clamp(
              0,
              999999,
            );
            final idleHours = (baseSubIdleHours - i * (rng.nextInt(6) + 1))
                .clamp(0, 999999);
            final recordedAt = now.subtract(
              Duration(days: subDaysAccumulated, hours: rng.nextInt(24)),
            );
            await txn.insert(subAssemblyDetailHistoryTable, {
              'subAssemblyId': subId,
              'operatingHours': '$opHours',
              'idleHours': '$idleHours',
              'recordedAtUtc': recordedAt.toIso8601String(),
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
      }
    });
  }

  Future<int> updateMachine(Machine machine) async {
    final db = await database;
    return db.transaction((txn) async {
      final changed = await txn.update(
        machineTable,
        machine.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [machine.id],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      if (machine.id != null) {
        await _replaceMachineRequiredLicenses(
          txn,
          machine.id!,
          machine.additionalRequiredLicenses,
        );

        await txn.delete(
          workOrderStatusTable,
          where:
              'subAssemblyId IN (SELECT id FROM $subAssemblyTable WHERE machineId = ?)',
          whereArgs: [machine.id],
        );

        await txn.delete(
          workOrderTaskAssignmentTable,
          where:
              'subAssemblyId IN (SELECT id FROM $subAssemblyTable WHERE machineId = ?)',
          whereArgs: [machine.id],
        );

        await txn.delete(
          subAssemblyDetailHistoryTable,
          where:
              'subAssemblyId IN (SELECT id FROM $subAssemblyTable WHERE machineId = ?)',
          whereArgs: [machine.id],
        );

        await txn.delete(
          maintenanceTaskTable,
          where:
              'subAssemblyId IN (SELECT id FROM $subAssemblyTable WHERE machineId = ?)',
          whereArgs: [machine.id],
        );

        await txn.delete(
          subAssemblyTable,
          where: 'machineId = ?',
          whereArgs: [machine.id],
        );

        for (final subAssembly in machine.subAssemblies) {
          final subAssemblyId = await txn.insert(
            subAssemblyTable,
            subAssembly.copyWith(machineId: machine.id).toMap()..remove('id'),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );

          for (final task in subAssembly.maintenanceTasks) {
            await txn.insert(
              maintenanceTaskTable,
              task.copyWith(subAssemblyId: subAssemblyId).toMap()..remove('id'),
              conflictAlgorithm: ConflictAlgorithm.abort,
            );
          }
        }
      }

      return changed;
    });
  }

  Future<int> updateMachineLastCheckDate(
    int machineId,
    String lastCheckDate,
  ) async {
    final db = await database;
    return db.update(
      machineTable,
      {'lastCheckDate': lastCheckDate},
      where: 'id = ?',
      whereArgs: [machineId],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> updateMachineDetailsWithHistory({
    required int machineId,
    required String operatingHours,
    required String idleHours,
    required String lastCheckDate,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final currentRows = await txn.query(
        machineTable,
        columns: ['operatingHours', 'idleHours', 'lastCheckDate'],
        where: 'id = ?',
        whereArgs: [machineId],
        limit: 1,
      );

      if (currentRows.isEmpty) {
        return 0;
      }

      final current = currentRows.first;
      final currentOperatingHours =
          (current['operatingHours'] as String?) ?? '';
      final currentIdleHours =
          (current['idleHours'] as String?) ??
          (current['idolHours'] as String?) ??
          '';
      final currentLastCheckDate = (current['lastCheckDate'] as String?) ?? '';

      final hasChanges =
          currentOperatingHours != operatingHours ||
          currentIdleHours != idleHours ||
          currentLastCheckDate != lastCheckDate;
      final lastCheckDateChanged = currentLastCheckDate != lastCheckDate;

      if (hasChanges) {
        await txn.insert(machineDetailHistoryTable, {
          'machineId': machineId,
          'operatingHours': currentOperatingHours,
          'idleHours': currentIdleHours,
          'lastCheckDate': currentLastCheckDate,
          'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.abort);
      }

      if (lastCheckDateChanged) {
        await txn.delete(
          workOrderStatusTable,
          where:
              'subAssemblyId IN (SELECT id FROM $subAssemblyTable WHERE machineId = ?)',
          whereArgs: [machineId],
        );
      }

      return txn.update(
        machineTable,
        {
          'operatingHours': operatingHours,
          'idleHours': idleHours,
          'lastCheckDate': lastCheckDate,
        },
        where: 'id = ?',
        whereArgs: [machineId],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });
  }

  Future<List<MachineDetailHistoryEntry>> getMachineDetailHistory(
    int machineId, {
    int limit = 10,
  }) async {
    final db = await database;
    final rows = await db.query(
      machineDetailHistoryTable,
      where: 'machineId = ?',
      whereArgs: [machineId],
      orderBy: 'id DESC',
      limit: limit,
    );

    return rows
        .map((row) => MachineDetailHistoryEntry.fromMap(row))
        .toList(growable: false);
  }

  Future<int> updateSubAssemblyDetailsWithHistory({
    required int subAssemblyId,
    required String operatingHours,
    required String idleHours,
  }) async {
    final db = await database;
    return db.transaction((txn) async {
      final currentRows = await txn.query(
        subAssemblyTable,
        columns: ['operatingHours', 'idleHours'],
        where: 'id = ?',
        whereArgs: [subAssemblyId],
        limit: 1,
      );

      if (currentRows.isEmpty) {
        return 0;
      }

      final current = currentRows.first;
      final currentOperatingHours =
          (current['operatingHours'] as String?) ?? '';
      final currentIdleHours =
          (current['idleHours'] as String?) ??
          (current['idolHours'] as String?) ??
          '';

      final hasChanges =
          currentOperatingHours != operatingHours ||
          currentIdleHours != idleHours;

      if (hasChanges) {
        await txn.insert(subAssemblyDetailHistoryTable, {
          'subAssemblyId': subAssemblyId,
          'operatingHours': currentOperatingHours,
          'idleHours': currentIdleHours,
          'recordedAtUtc': DateTime.now().toUtc().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.abort);
      }

      return txn.update(
        subAssemblyTable,
        {'operatingHours': operatingHours, 'idleHours': idleHours},
        where: 'id = ?',
        whereArgs: [subAssemblyId],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    });
  }

  Future<List<SubAssemblyDetailHistoryEntry>> getSubAssemblyDetailHistory(
    int subAssemblyId, {
    int limit = 10,
  }) async {
    final db = await database;
    final rows = await db.query(
      subAssemblyDetailHistoryTable,
      where: 'subAssemblyId = ?',
      whereArgs: [subAssemblyId],
      orderBy: 'id DESC',
      limit: limit,
    );

    return rows
        .map((row) => SubAssemblyDetailHistoryEntry.fromMap(row))
        .toList(growable: false);
  }

  Future<int> upsertWorkOrderStatus({
    required int subAssemblyId,
    required String status,
    bool isRescheduled = false,
    bool isLicensedWork = false,
    String notes = '',
    DateTime? enteredAtUtc,
  }) async {
    final db = await database;
    return db.insert(workOrderStatusTable, {
      'subAssemblyId': subAssemblyId,
      'status': status,
      'isRescheduled': isRescheduled ? 1 : 0,
      'isLicensedWork': isLicensedWork ? 1 : 0,
      'notes': notes,
      'enteredAtUtc': (enteredAtUtc ?? DateTime.now().toUtc())
          .toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> upsertWorkOrderTaskAssignment({
    required int subAssemblyId,
    required int taskId,
    required String assigneeValue,
    DateTime? enteredAtUtc,
  }) async {
    final normalized = assigneeValue.trim();
    if (normalized.isEmpty) {
      return 0;
    }

    final db = await database;
    return db.insert(workOrderTaskAssignmentTable, {
      'subAssemblyId': subAssemblyId,
      'taskId': taskId,
      'assigneeValue': normalized,
      'enteredAtUtc': (enteredAtUtc ?? DateTime.now().toUtc())
          .toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<int, String>> getWorkOrderTaskAssignments(
    int subAssemblyId,
  ) async {
    final db = await database;
    final rows = await db.query(
      workOrderTaskAssignmentTable,
      columns: ['taskId', 'assigneeValue'],
      where: 'subAssemblyId = ?',
      whereArgs: [subAssemblyId],
      orderBy: 'taskId ASC',
    );

    final assignments = <int, String>{};
    for (final row in rows) {
      final taskId = row['taskId'] as int?;
      final assigneeValue = (row['assigneeValue'] as String?)?.trim() ?? '';
      if (taskId == null || assigneeValue.isEmpty) {
        continue;
      }
      assignments[taskId] = assigneeValue;
    }

    return assignments;
  }

  Future<int> deleteWorkOrderTaskAssignment({
    required int subAssemblyId,
    required int taskId,
  }) async {
    final db = await database;
    return db.delete(
      workOrderTaskAssignmentTable,
      where: 'subAssemblyId = ? AND taskId = ?',
      whereArgs: [subAssemblyId, taskId],
    );
  }

  Future<WorkOrderStatusEntry?> getWorkOrderStatus(int subAssemblyId) async {
    final db = await database;
    final rows = await db.query(
      workOrderStatusTable,
      where: 'subAssemblyId = ?',
      whereArgs: [subAssemblyId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return WorkOrderStatusEntry.fromMap(rows.first);
  }

  Future<Map<String, int>> getWorkOrderStatusCounts() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT status, COUNT(*) AS cnt FROM $workOrderStatusTable GROUP BY status',
    );

    final counts = <String, int>{};
    for (final row in rows) {
      final status = (row['status'] as String?)?.trim();
      if (status == null || status.isEmpty) {
        continue;
      }
      counts[status] = row['cnt'] as int? ?? 0;
    }

    return counts;
  }

  Future<int> deleteMachine(int id) async {
    final db = await database;
    return db.transaction((txn) async {
      await txn.delete(
        machineDetailHistoryTable,
        where: 'machineId = ?',
        whereArgs: [id],
      );
      await txn.delete(
        workOrderStatusTable,
        where:
            'subAssemblyId IN (SELECT id FROM $subAssemblyTable WHERE machineId = ?)',
        whereArgs: [id],
      );
      await txn.delete(
        workOrderTaskAssignmentTable,
        where:
            'subAssemblyId IN (SELECT id FROM $subAssemblyTable WHERE machineId = ?)',
        whereArgs: [id],
      );
      await txn.delete(
        subAssemblyDetailHistoryTable,
        where:
            'subAssemblyId IN (SELECT id FROM $subAssemblyTable WHERE machineId = ?)',
        whereArgs: [id],
      );
      await txn.delete(
        maintenanceTaskTable,
        where:
            'subAssemblyId IN (SELECT id FROM $subAssemblyTable WHERE machineId = ?)',
        whereArgs: [id],
      );
      await txn.delete(
        machineRequiredLicenseTable,
        where: 'machineId = ?',
        whereArgs: [id],
      );
      await txn.delete(
        subAssemblyTable,
        where: 'machineId = ?',
        whereArgs: [id],
      );
      return txn.delete(machineTable, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<bool> hasMachineDocumentNumber(
    String documentNumber, {
    int? excludeMachineId,
  }) async {
    final db = await database;
    return dbHasMachineDocumentNumber(
      db,
      documentNumber,
      excludeMachineId: excludeMachineId,
    );
  }

  Future<bool> hasSubAssemblyDocumentNumber(
    String documentNumber, {
    int? excludeMachineId,
  }) async {
    final db = await database;
    return dbHasSubAssemblyDocumentNumber(
      db,
      documentNumber,
      excludeMachineId: excludeMachineId,
    );
  }

  Future<String> exportDatabaseJson() async {
    final machines = await getMachines();
    final employees = await getEmployees();
    final skillTypes = await getSkillTypes();
    final payload = <String, Object?>{
      'format': 'machine_registry_backup_v3',
      'exportedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'machineCount': machines.length,
      'employeeCount': employees.length,
      'machines': machines
          .map((machine) => _machineToBackupMap(machine))
          .toList(growable: false),
      'skills': skillTypes,
      'employees': employees
          .map((employee) => _employeeToBackupMap(employee))
          .toList(growable: false),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<int> importDatabaseJson(
    String backupJson, {
    bool clearExisting = true,
  }) async {
    final decoded = jsonDecode(backupJson);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Backup must be a JSON object.');
    }

    final format = (decoded['format'] as String?) ?? '';
    final isV1 = format == 'machine_registry_backup_v1';
    final isV2 = format == 'machine_registry_backup_v2';
    final isV3 = format == 'machine_registry_backup_v3';
    if (!isV1 && !isV2 && !isV3) {
      throw const FormatException('Unsupported backup format.');
    }

    final rawMachines = decoded['machines'];
    if (rawMachines is! List) {
      throw const FormatException('Backup is missing a machines list.');
    }

    final machines = rawMachines
        .map((row) => _machineFromBackupMap(row))
        .toList(growable: false);

    final includeEmployees = isV2 || isV3;
    final skillTypes = includeEmployees
        ? _asStringList(decoded['skills'])
        : const <String>[];
    final rawEmployees = includeEmployees ? decoded['employees'] : null;
    if (includeEmployees && rawEmployees is! List) {
      throw const FormatException('Backup is missing an employees list.');
    }
    final employees = rawEmployees is List
        ? rawEmployees
              .map((row) => _employeeFromBackupMap(row))
              .toList(growable: false)
        : const <Employee>[];

    final db = await database;
    await db.transaction((txn) async {
      if (clearExisting) {
        await txn.delete(machineDetailHistoryTable);
        await txn.delete(subAssemblyDetailHistoryTable);
        await txn.delete(workOrderStatusTable);
        await txn.delete(workOrderTaskAssignmentTable);
        await txn.delete(maintenanceTaskTable);
        await txn.delete(subAssemblyTable);
        await txn.delete(machineRequiredLicenseTable);
        await txn.delete(machineTable);
        await txn.delete(employeeRequiredLicenseTable);
        await txn.delete(employeeSkillTable);
        await txn.delete(employeeTable);
        await txn.delete(skillTypeTable);
      }

      for (final skill in skillTypes) {
        final normalized = skill.trim();
        if (normalized.isEmpty) {
          continue;
        }
        await txn.insert(skillTypeTable, {
          'name': normalized,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      for (final machine in machines) {
        final machineId = await txn.insert(
          machineTable,
          machine.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        await _replaceMachineRequiredLicenses(
          txn,
          machineId,
          machine.additionalRequiredLicenses,
        );

        for (final subAssembly in machine.subAssemblies) {
          final subAssemblyId = await txn.insert(
            subAssemblyTable,
            subAssembly.copyWith(machineId: machineId).toMap()..remove('id'),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );

          for (final task in subAssembly.maintenanceTasks) {
            await txn.insert(
              maintenanceTaskTable,
              task.copyWith(subAssemblyId: subAssemblyId).toMap()..remove('id'),
              conflictAlgorithm: ConflictAlgorithm.abort,
            );
          }
        }
      }

      for (final employee in employees) {
        final employeeId = await txn.insert(
          employeeTable,
          employee.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
        await _replaceEmployeeSkills(txn, employeeId, employee.skills);
        await _replaceEmployeeRequiredLicenses(
          txn,
          employeeId,
          employee.licenses,
        );
      }
    });

    return machines.length;
  }

  Future<void> deleteEntireDatabaseFile() async {
    _openingDatabase = null;
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final fullPath = await _databaseFilePath();
    await databaseFactory.deleteDatabase(fullPath);
  }

  Map<String, Object?> _machineToBackupMap(Machine machine) {
    return {
      ...machine.toMap()..remove('id'),
      'additionalRequiredLicenses': machine.additionalRequiredLicenses,
      'subAssemblies': machine.subAssemblies
          .map((subAssembly) => _subAssemblyToBackupMap(subAssembly))
          .toList(growable: false),
    };
  }

  Map<String, Object?> _employeeToBackupMap(Employee employee) {
    return {
      ...employee.toMap()..remove('id'),
      'skills': employee.skills,
      'licenses': employee.licenses,
    };
  }

  Map<String, Object?> _subAssemblyToBackupMap(SubAssembly subAssembly) {
    return {
      ...subAssembly.toMap()
        ..remove('id')
        ..remove('machineId'),
      'maintenanceTasks': subAssembly.maintenanceTasks
          .map((task) => _taskToBackupMap(task))
          .toList(growable: false),
    };
  }

  Map<String, Object?> _taskToBackupMap(MaintenanceTask task) {
    return {
      ...task.toMap()
        ..remove('id')
        ..remove('subAssemblyId'),
    };
  }

  Machine _machineFromBackupMap(Object? row) {
    if (row is! Map) {
      throw const FormatException('Machine entry must be an object.');
    }

    final map = row.cast<Object?, Object?>();
    final rawSubAssemblies = map['subAssemblies'];
    if (rawSubAssemblies is! List) {
      throw const FormatException('Machine entry is missing subAssemblies.');
    }

    return Machine(
      name: _asString(map['name']),
      modelName: _asString(map['modelName']),
      modelNumber: _asString(map['modelNumber']),
      operatingHours: _asString(map['operatingHours']),
      idleHours: _asString(map['idleHours']),
      lastCheckDate: _asString(map['lastCheckDate']),
      serialNumber: _asString(map['serialNumber']),
      location: _asString(map['location']),
      manufacturer: _asString(map['manufacturer']),
      maintenanceDocumentName: _asString(map['maintenanceDocumentName']),
      maintenanceDocumentNumber: _asString(map['maintenanceDocumentNumber']),
      maintenancePublisher: _asString(map['maintenancePublisher']),
      requiresHvacLicense: _asBool(map['requiresHvacLicense']),
      requiresRefrigerationLicense: _asBool(
        map['requiresRefrigerationLicense'],
      ),
      requiresPlumberLicense: _asBool(map['requiresPlumberLicense']),
      requiresElectricianLicense: _asBool(map['requiresElectricianLicense']),
      requiresBoilerLicense: _asBool(map['requiresBoilerLicense']),
      additionalRequiredLicenses: _asStringList(
        map['additionalRequiredLicenses'],
      ),
      subAssemblies: rawSubAssemblies
          .map((entry) => _subAssemblyFromBackupMap(entry))
          .toList(growable: false),
    );
  }

  SubAssembly _subAssemblyFromBackupMap(Object? row) {
    if (row is! Map) {
      throw const FormatException('Sub-assembly entry must be an object.');
    }

    final map = row.cast<Object?, Object?>();
    final rawTasks = map['maintenanceTasks'];
    if (rawTasks is! List) {
      throw const FormatException(
        'Sub-assembly entry is missing maintenanceTasks.',
      );
    }

    return SubAssembly(
      name: _asString(map['name']),
      modelName: _asString(map['modelName']),
      modelNumber: _asString(map['modelNumber']),
      operatingHours: _asString(map['operatingHours']),
      idleHours: _asString(map['idleHours']),
      serialNumber: _asString(map['serialNumber']),
      location: _asString(map['location']),
      manufacturer: _asString(map['manufacturer']),
      maintenanceDocumentName: _asString(map['maintenanceDocumentName']),
      maintenanceDocumentNumber: _asString(map['maintenanceDocumentNumber']),
      maintenancePublisher: _asString(map['maintenancePublisher']),
      subCategory: _asString(map['componentType']),
      maintenanceTasks: rawTasks
          .map((entry) => _taskFromBackupMap(entry))
          .toList(growable: false),
    );
  }

  MaintenanceTask _taskFromBackupMap(Object? row) {
    if (row is! Map) {
      throw const FormatException('Task entry must be an object.');
    }

    final map = row.cast<Object?, Object?>();

    return MaintenanceTask(
      taskType: _asString(map['taskType']),
      timeCategory: _asString(map['timeCategory']),
      timeValue: _asInt(map['timeValue']),
    );
  }

  Employee _employeeFromBackupMap(Object? row) {
    if (row is! Map) {
      throw const FormatException('Employee entry must be an object.');
    }

    final map = row.cast<Object?, Object?>();
    return Employee(
      name: _asString(map['name']),
      skills: _asStringList(map['skills']),
      licenses: _asStringList(map['licenses']),
    );
  }

  String _asString(Object? value) {
    if (value is String) {
      return value;
    }
    if (value == null) {
      return '';
    }
    return '$value';
  }

  int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  List<String> _asStringList(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .map((entry) => _asString(entry).trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  bool _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is int) {
      return value != 0;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == '1' || normalized == 'true' || normalized == 'yes';
    }
    return false;
  }

  // ============================================================================
  // CSV IMPORT/EXPORT OPERATIONS
  // ============================================================================

  List<String> _employeeCsvHeaders() {
    return const ['id', 'name', 'skills', 'licenses'];
  }

  List<String> _employeeCsvSampleRow() {
    return const ['', 'Jane Doe', 'Welding;Diagnostics', 'HVAC;Electrician'];
  }

  List<String> _machineCsvHeaders() {
    return const [
      'id',
      'name',
      'modelName',
      'modelNumber',
      'operatingHours',
      'idleHours',
      'lastCheckDate',
      'serialNumber',
      'location',
      'manufacturer',
      'maintenanceDocumentName',
      'maintenanceDocumentNumber',
      'maintenancePublisher',
      'requiresHvacLicense',
      'requiresRefrigerationLicense',
      'requiresPlumberLicense',
      'requiresElectricianLicense',
      'requiresBoilerLicense',
    ];
  }

  List<String> _machineCsvSampleRow() {
    return const [
      '',
      'Air Compressor 01',
      'Atlas Copco GA',
      'GA75VSD',
      '1250',
      '80',
      '2026-03-01',
      'AC-001',
      'Plant Room A',
      'Atlas Copco',
      'Compressor Manual',
      'DOC-AC-001',
      'Atlas Copco',
      '1',
      '0',
      '0',
      '1',
      '0',
    ];
  }

  Future<String?> exportEmployeeTemplateToCsv() async {
    try {
      return _generateCsv([_employeeCsvHeaders(), _employeeCsvSampleRow()]);
    } catch (_) {
      return null;
    }
  }

  Future<String?> exportMachineTemplateToCsv() async {
    try {
      return _generateCsv([_machineCsvHeaders(), _machineCsvSampleRow()]);
    } catch (_) {
      return null;
    }
  }

  /// Exported employees to CSV file with headers.
  /// User selects file location via file picker.
  /// CSV format: id,name,skills,licenses
  Future<String?> exportEmployeesToCsv() async {
    try {
      final employees = await getEmployees();

      // Generate CSV with headers
      final csvLines = <List<String>>[_employeeCsvHeaders()];

      for (final employee in employees) {
        csvLines.add([
          _asString(employee.id),
          _asString(employee.name),
          employee.skills.join(';'),
          employee.licenses.join(';'),
        ]);
      }

      return _generateCsv(csvLines);
    } catch (e) {
      return null;
    }
  }

  /// Export machines to CSV file with headers.
  /// User selects file location via file picker.
  /// CSV format: id,name,modelName,modelNumber,operatingHours,idleHours,
  /// lastCheckDate,serialNumber,location,manufacturer,maintenanceDocumentName,
  /// maintenanceDocumentNumber,maintenancePublisher,requiresHvacLicense,
  /// requiresRefrigerationLicense,requiresPlumberLicense,
  /// requiresElectricianLicense,requiresBoilerLicense
  Future<String?> exportMachinesToCsv() async {
    try {
      final machines = await getMachines();

      // Generate CSV with headers
      final csvLines = <List<String>>[_machineCsvHeaders()];

      for (final machine in machines) {
        csvLines.add([
          _asString(machine.id),
          _asString(machine.name),
          _asString(machine.modelName),
          _asString(machine.modelNumber),
          _asString(machine.operatingHours),
          _asString(machine.idleHours),
          _asString(machine.lastCheckDate),
          _asString(machine.serialNumber),
          _asString(machine.location),
          _asString(machine.manufacturer),
          _asString(machine.maintenanceDocumentName),
          _asString(machine.maintenanceDocumentNumber),
          _asString(machine.maintenancePublisher),
          machine.requiresHvacLicense ? '1' : '0',
          machine.requiresRefrigerationLicense ? '1' : '0',
          machine.requiresPlumberLicense ? '1' : '0',
          machine.requiresElectricianLicense ? '1' : '0',
          machine.requiresBoilerLicense ? '1' : '0',
        ]);
      }

      return _generateCsv(csvLines);
    } catch (e) {
      return null;
    }
  }

  /// Imports employees from CSV file.
  /// Expected columns: id, name, skills, licenses
  /// Skills and licenses should be semicolon-separated.
  /// User selects file via file picker.
  Future<int> importEmployeesFromCsv(String csvContent) async {
    try {
      final lines = csvContent.split('\n');
      if (lines.isEmpty) return 0;

      // Parse CSV: simple parser for quoted and unquoted fields
      final parsedRows = _parseCsvContent(csvContent);
      if (parsedRows.isEmpty) return 0;

      // Find header indices
      final headers = parsedRows.first;
      final nameIndex = headers.indexOf('name');
      final skillsIndex = headers.indexOf('skills');
      final licensesIndex = headers.indexOf('licenses');

      if (nameIndex < 0) {
        return 0; // name is required
      }

      int importedCount = 0;

      // Process data rows
      for (int i = 1; i < parsedRows.length; i++) {
        final row = parsedRows[i];
        if (row.isEmpty || row.every((field) => field.trim().isEmpty)) {
          continue;
        }

        final name = row.length > nameIndex ? row[nameIndex].trim() : '';
        if (name.isEmpty) continue;

        final skillsStr = row.length > skillsIndex ? row[skillsIndex] : '';
        final licensesStr = row.length > licensesIndex
            ? row[licensesIndex]
            : '';

        final skills = skillsStr
            .split(';')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        final licenses = licensesStr
            .split(';')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

        final employee = Employee(
          name: name,
          skills: skills,
          licenses: licenses,
        );

        await insertEmployee(employee);
        importedCount++;
      }

      return importedCount;
    } catch (e) {
      return 0;
    }
  }

  /// Imports machines from CSV file.
  /// Expected columns: name,modelName,modelNumber,operatingHours,idleHours,
  /// lastCheckDate,serialNumber,location,manufacturer,maintenanceDocumentName,
  /// maintenanceDocumentNumber,maintenancePublisher,requiresHvacLicense, etc.
  /// User selects file via file picker.
  Future<int> importMachinesFromCsv(String csvContent) async {
    try {
      final parsedRows = _parseCsvContent(csvContent);
      if (parsedRows.isEmpty) return 0;

      // Find header indices
      final headers = parsedRows.first;
      final nameIndex = headers.indexOf('name');
      final modelNameIndex = headers.indexOf('modelName');
      final modelNumberIndex = headers.indexOf('modelNumber');
      final operatingHoursIndex = headers.indexOf('operatingHours');
      final idleHoursIndex = headers.indexOf('idleHours');
      final lastCheckDateIndex = headers.indexOf('lastCheckDate');
      final serialNumberIndex = headers.indexOf('serialNumber');
      final locationIndex = headers.indexOf('location');
      final manufacturerIndex = headers.indexOf('manufacturer');
      final docNameIndex = headers.indexOf('maintenanceDocumentName');
      final docNumberIndex = headers.indexOf('maintenanceDocumentNumber');
      final publisherIndex = headers.indexOf('maintenancePublisher');
      final hvacIndex = headers.indexOf('requiresHvacLicense');
      final refIndex = headers.indexOf('requiresRefrigerationLicense');
      final plumbIndex = headers.indexOf('requiresPlumberLicense');
      final elecIndex = headers.indexOf('requiresElectricianLicense');
      final boilerIndex = headers.indexOf('requiresBoilerLicense');

      if (nameIndex < 0 || modelNameIndex < 0 || modelNumberIndex < 0) {
        return 0; // Required fields
      }

      int importedCount = 0;

      // Process data rows
      for (int i = 1; i < parsedRows.length; i++) {
        final row = parsedRows[i];
        if (row.isEmpty || row.every((field) => field.trim().isEmpty)) {
          continue;
        }

        final name = row.length > nameIndex ? row[nameIndex].trim() : '';
        final modelName = row.length > modelNameIndex
            ? row[modelNameIndex].trim()
            : '';
        final modelNumber = row.length > modelNumberIndex
            ? row[modelNumberIndex].trim()
            : '';

        if (name.isEmpty || modelName.isEmpty || modelNumber.isEmpty) {
          continue;
        }

        final machine = Machine(
          name: name,
          modelName: modelName,
          modelNumber: modelNumber,
          operatingHours: row.length > operatingHoursIndex
              ? row[operatingHoursIndex].trim()
              : '0',
          idleHours: row.length > idleHoursIndex
              ? row[idleHoursIndex].trim()
              : '0',
          lastCheckDate: row.length > lastCheckDateIndex
              ? row[lastCheckDateIndex].trim()
              : _isoDate(DateTime.now()),
          serialNumber: row.length > serialNumberIndex
              ? row[serialNumberIndex].trim()
              : '',
          location: row.length > locationIndex ? row[locationIndex].trim() : '',
          manufacturer: row.length > manufacturerIndex
              ? row[manufacturerIndex].trim()
              : '',
          maintenanceDocumentName: row.length > docNameIndex
              ? row[docNameIndex].trim()
              : '',
          maintenanceDocumentNumber: row.length > docNumberIndex
              ? row[docNumberIndex].trim()
              : '',
          maintenancePublisher: row.length > publisherIndex
              ? row[publisherIndex].trim()
              : '',
          requiresHvacLicense: row.length > hvacIndex
              ? _asBool(row[hvacIndex])
              : false,
          requiresRefrigerationLicense: row.length > refIndex
              ? _asBool(row[refIndex])
              : false,
          requiresPlumberLicense: row.length > plumbIndex
              ? _asBool(row[plumbIndex])
              : false,
          requiresElectricianLicense: row.length > elecIndex
              ? _asBool(row[elecIndex])
              : false,
          requiresBoilerLicense: row.length > boilerIndex
              ? _asBool(row[boilerIndex])
              : false,
        );

        await insertMachine(machine);
        importedCount++;
      }

      return importedCount;
    } catch (e) {
      return 0;
    }
  }

  /// Generates CSV content from rows and saves to file via file picker.
  /// Returns file path if successful, null if cancelled or failed.
  String _generateCsv(List<List<String>> rows) {
    final buffer = StringBuffer();

    for (final row in rows) {
      final escapedRow = row.map((field) {
        // Escape quotes and wrap in quotes if contains comma, newline, or quote
        if (field.contains(',') ||
            field.contains('\n') ||
            field.contains('"')) {
          return '"${field.replaceAll('"', '""')}"';
        }
        return field;
      }).toList();

      buffer.writeln(escapedRow.join(','));
    }

    return buffer.toString();
  }

  /// Parses CSV content into rows.
  /// Handles quoted fields with escaped quotes.
  List<List<String>> _parseCsvContent(String csvContent) {
    final rows = <List<String>>[];
    final lines = csvContent.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final row = <String>[];
      var currentField = StringBuffer();
      var inQuotes = false;

      for (int i = 0; i < line.length; i++) {
        final char = line[i];
        final nextChar = i + 1 < line.length ? line[i + 1] : null;

        if (char == '"') {
          if (inQuotes && nextChar == '"') {
            // Escaped quote
            currentField.write('"');
            i++;
          } else {
            // Toggle quote mode
            inQuotes = !inQuotes;
          }
        } else if (char == ',' && !inQuotes) {
          // Field separator
          row.add(currentField.toString());
          currentField.clear();
        } else {
          currentField.write(char);
        }
      }

      // Add final field
      row.add(currentField.toString());

      if (row.isNotEmpty) {
        rows.add(row);
      }
    }

    return rows;
  }
}
