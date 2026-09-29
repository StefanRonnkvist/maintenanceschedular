import 'package:sqflite_common/sqlite_api.dart';

const String machineTable = 'machines';
const String subAssemblyTable = 'sub_assemblies';
const String maintenanceTaskTable = 'maintenance_tasks';
const String componentTypeTable = 'component_types';
const String superCategoryTypeTable = 'super_category_types';
const String maintenanceTaskTypeTable = 'maintenance_task_types';
const String licenseTypeTable = 'license_types';
const String machineRequiredLicenseTable = 'machine_required_licenses';
const String machineDetailHistoryTable = 'machine_detail_history';
const String subAssemblyDetailHistoryTable = 'sub_assembly_detail_history';
const String workOrderStatusTable = 'work_order_status';
const String workOrderTaskAssignmentTable = 'work_order_task_assignments';
const String employeeTable = 'employees';
const String skillTypeTable = 'skill_types';
const String employeeSkillTable = 'employee_skills';
const String employeeRequiredLicenseTable = 'employee_required_licenses';
const String dbName = 'machine_registry.db';
const int dbVersion = 23;

const String createMachineTableSql = '''
  CREATE TABLE machines(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    modelName TEXT NOT NULL,
    modelNumber TEXT NOT NULL,
    operatingHours TEXT NOT NULL,
    idleHours TEXT NOT NULL,
    lastCheckDate TEXT NOT NULL,
    serialNumber TEXT NOT NULL,
    location TEXT NOT NULL,
    manufacturer TEXT NOT NULL,
    maintenanceDocumentName TEXT NOT NULL,
    maintenanceDocumentNumber TEXT NOT NULL,
    maintenancePublisher TEXT NOT NULL,
    requiresHvacLicense INTEGER NOT NULL DEFAULT 0,
    requiresRefrigerationLicense INTEGER NOT NULL DEFAULT 0,
    requiresPlumberLicense INTEGER NOT NULL DEFAULT 0,
    requiresElectricianLicense INTEGER NOT NULL DEFAULT 0,
    requiresBoilerLicense INTEGER NOT NULL DEFAULT 0
  )
''';

const String createSubAssemblyTableSql = '''
  CREATE TABLE sub_assemblies(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    machineId INTEGER NOT NULL,
    name TEXT NOT NULL,
    modelName TEXT NOT NULL,
    modelNumber TEXT NOT NULL,
    operatingHours TEXT NOT NULL,
    idleHours TEXT NOT NULL,
    serialNumber TEXT NOT NULL,
    location TEXT NOT NULL,
    manufacturer TEXT NOT NULL,
    maintenanceDocumentName TEXT NOT NULL,
    maintenanceDocumentNumber TEXT NOT NULL,
    maintenancePublisher TEXT NOT NULL,
    superCategory TEXT NOT NULL DEFAULT '',
    componentType TEXT NOT NULL DEFAULT ''
  )
''';

const String createMaintenanceTaskTableSql = '''
  CREATE TABLE maintenance_tasks(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    subAssemblyId INTEGER NOT NULL,
    taskType TEXT NOT NULL,
    timeCategory TEXT NOT NULL,
    timeValue INTEGER NOT NULL DEFAULT 0
  )
''';

const String createComponentTypeTableSql = '''
  CREATE TABLE component_types(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
  )
''';

const String createSuperCategoryTypeTableSql = '''
  CREATE TABLE super_category_types(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
  )
''';

const String createMaintenanceTaskTypeTableSql = '''
  CREATE TABLE maintenance_task_types(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
  )
''';

const String createLicenseTypeTableSql = '''
  CREATE TABLE license_types(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
  )
''';

const String createMachineRequiredLicenseTableSql = '''
  CREATE TABLE machine_required_licenses(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    machineId INTEGER NOT NULL,
    licenseName TEXT NOT NULL,
    UNIQUE(machineId, licenseName)
  )
''';

const String createMachineDetailHistoryTableSql = '''
  CREATE TABLE machine_detail_history(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    machineId INTEGER NOT NULL,
    operatingHours TEXT NOT NULL,
    idleHours TEXT NOT NULL,
    lastCheckDate TEXT NOT NULL,
    recordedAtUtc TEXT NOT NULL
  )
''';

const String createSubAssemblyDetailHistoryTableSql = '''
  CREATE TABLE sub_assembly_detail_history(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    subAssemblyId INTEGER NOT NULL,
    operatingHours TEXT NOT NULL,
    idleHours TEXT NOT NULL,
    recordedAtUtc TEXT NOT NULL
  )
''';

const String createWorkOrderStatusTableSql = '''
  CREATE TABLE work_order_status(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    subAssemblyId INTEGER NOT NULL UNIQUE,
    status TEXT NOT NULL,
    isRescheduled INTEGER NOT NULL DEFAULT 0,
    isLicensedWork INTEGER NOT NULL DEFAULT 0,
    notes TEXT NOT NULL DEFAULT '',
    enteredAtUtc TEXT NOT NULL
  )
''';

const String createWorkOrderTaskAssignmentTableSql = '''
  CREATE TABLE work_order_task_assignments(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    subAssemblyId INTEGER NOT NULL,
    taskId INTEGER NOT NULL,
    assigneeValue TEXT NOT NULL,
    enteredAtUtc TEXT NOT NULL,
    UNIQUE(subAssemblyId, taskId)
  )
''';

const String createEmployeeTableSql = '''
  CREATE TABLE employees(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
  )
''';

const String createSkillTypeTableSql = '''
  CREATE TABLE skill_types(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
  )
''';

const String createEmployeeSkillTableSql = '''
  CREATE TABLE employee_skills(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employeeId INTEGER NOT NULL,
    skillName TEXT NOT NULL,
    UNIQUE(employeeId, skillName)
  )
''';

const String createEmployeeRequiredLicenseTableSql = '''
  CREATE TABLE employee_required_licenses(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employeeId INTEGER NOT NULL,
    licenseName TEXT NOT NULL,
    UNIQUE(employeeId, licenseName)
  )
''';

/// Returns whether [tableName] exists in the current SQLite schema.
Future<bool> hasTable(Database db, String tableName) async {
  final tables = await db.query(
    'sqlite_master',
    columns: ['name'],
    where: 'type = ? AND name = ?',
    whereArgs: ['table', tableName],
    limit: 1,
  );
  return tables.isNotEmpty;
}

Future<void> ensureMachineTable(Database db) async {
  if (!await hasTable(db, machineTable)) {
    await db.execute(createMachineTableSql);
  }
}

/// Adds `idleHours` when missing and copies values from the legacy
/// misspelled `idolHours` column when present.
Future<void> ensureIdleHoursColumn(Database db, String tableName) async {
  if (!await hasTable(db, tableName)) {
    return;
  }

  final columns = await db.rawQuery('PRAGMA table_info($tableName)');
  final hasIdleHours = columns.any((column) => column['name'] == 'idleHours');
  final hasIdolHours = columns.any((column) => column['name'] == 'idolHours');

  if (!hasIdleHours) {
    await db.execute(
      'ALTER TABLE $tableName ADD COLUMN idleHours TEXT NOT NULL DEFAULT ""',
    );
  }

  if (hasIdolHours) {
    await db.execute(
      'UPDATE $tableName SET idleHours = idolHours WHERE idleHours = ""',
    );
  }
}

/// Adds any missing maintenance-document columns to an existing table.
Future<void> ensureMaintenanceDocumentColumns(
  Database db,
  String tableName,
) async {
  if (!await hasTable(db, tableName)) {
    return;
  }

  final columns = await db.rawQuery('PRAGMA table_info($tableName)');
  final hasDocumentName = columns.any(
    (column) => column['name'] == 'maintenanceDocumentName',
  );
  final hasDocumentNumber = columns.any(
    (column) => column['name'] == 'maintenanceDocumentNumber',
  );
  final hasPublisher = columns.any(
    (column) => column['name'] == 'maintenancePublisher',
  );

  if (!hasDocumentName) {
    await db.execute(
      'ALTER TABLE $tableName ADD COLUMN maintenanceDocumentName TEXT NOT NULL DEFAULT ""',
    );
  }
  if (!hasDocumentNumber) {
    await db.execute(
      'ALTER TABLE $tableName ADD COLUMN maintenanceDocumentNumber TEXT NOT NULL DEFAULT ""',
    );
  }
  if (!hasPublisher) {
    await db.execute(
      'ALTER TABLE $tableName ADD COLUMN maintenancePublisher TEXT NOT NULL DEFAULT ""',
    );
  }
}

Future<void> ensureSubAssembliesTable(Database db) async {
  if (!await hasTable(db, subAssemblyTable)) {
    await db.execute(createSubAssemblyTableSql);
  }
}

Future<void> ensureMaintenanceTaskTable(Database db) async {
  if (!await hasTable(db, maintenanceTaskTable)) {
    await db.execute(createMaintenanceTaskTableSql);
  }
}

Future<void> ensureComponentTypeTable(Database db) async {
  if (!await hasTable(db, componentTypeTable)) {
    await db.execute(createComponentTypeTableSql);
  }
}

Future<void> ensureSuperCategoryTypeTable(Database db) async {
  if (!await hasTable(db, superCategoryTypeTable)) {
    await db.execute(createSuperCategoryTypeTableSql);
  }
}

Future<void> ensureMaintenanceTaskTypeTable(Database db) async {
  if (!await hasTable(db, maintenanceTaskTypeTable)) {
    await db.execute(createMaintenanceTaskTypeTableSql);
  }
}

Future<void> ensureLicenseTypeTable(Database db) async {
  if (!await hasTable(db, licenseTypeTable)) {
    await db.execute(createLicenseTypeTableSql);
  }
}

Future<void> ensureMachineRequiredLicenseTable(Database db) async {
  if (!await hasTable(db, machineRequiredLicenseTable)) {
    await db.execute(createMachineRequiredLicenseTableSql);
  }
}

Future<void> ensureMachineDetailHistoryTable(Database db) async {
  if (!await hasTable(db, machineDetailHistoryTable)) {
    await db.execute(createMachineDetailHistoryTableSql);
  }
}

Future<void> ensureSubAssemblyDetailHistoryTable(Database db) async {
  if (!await hasTable(db, subAssemblyDetailHistoryTable)) {
    await db.execute(createSubAssemblyDetailHistoryTableSql);
  }
}

Future<void> ensureWorkOrderStatusTable(Database db) async {
  if (!await hasTable(db, workOrderStatusTable)) {
    await db.execute(createWorkOrderStatusTableSql);
  }
}

Future<void> ensureWorkOrderTaskAssignmentTable(Database db) async {
  if (!await hasTable(db, workOrderTaskAssignmentTable)) {
    await db.execute(createWorkOrderTaskAssignmentTableSql);
  }
}

Future<void> ensureEmployeeTable(Database db) async {
  if (!await hasTable(db, employeeTable)) {
    await db.execute(createEmployeeTableSql);
  }
}

Future<void> ensureSkillTypeTable(Database db) async {
  if (!await hasTable(db, skillTypeTable)) {
    await db.execute(createSkillTypeTableSql);
  }
}

Future<void> ensureEmployeeSkillTable(Database db) async {
  if (!await hasTable(db, employeeSkillTable)) {
    await db.execute(createEmployeeSkillTableSql);
  }
}

Future<void> ensureEmployeeRequiredLicenseTable(Database db) async {
  if (!await hasTable(db, employeeRequiredLicenseTable)) {
    await db.execute(createEmployeeRequiredLicenseTableSql);
  }
}

/// Adds optional work-order metadata introduced after the original table.
Future<void> ensureWorkOrderStatusMetadataColumns(Database db) async {
  if (!await hasTable(db, workOrderStatusTable)) {
    return;
  }

  final columns = await db.rawQuery('PRAGMA table_info($workOrderStatusTable)');
  final hasRescheduled = columns.any(
    (column) => column['name'] == 'isRescheduled',
  );
  final hasLicensedWork = columns.any(
    (column) => column['name'] == 'isLicensedWork',
  );
  final hasNotes = columns.any((column) => column['name'] == 'notes');

  if (!hasRescheduled) {
    await db.execute(
      'ALTER TABLE $workOrderStatusTable ADD COLUMN isRescheduled INTEGER NOT NULL DEFAULT 0',
    );
  }

  if (!hasLicensedWork) {
    await db.execute(
      'ALTER TABLE $workOrderStatusTable ADD COLUMN isLicensedWork INTEGER NOT NULL DEFAULT 0',
    );
  }

  if (!hasNotes) {
    await db.execute(
      'ALTER TABLE $workOrderStatusTable ADD COLUMN notes TEXT NOT NULL DEFAULT ""',
    );
  }
}

Future<void> ensureSubAssemblyComponentTypeColumn(Database db) async {
  if (!await hasTable(db, subAssemblyTable)) return;
  final columns = await db.rawQuery('PRAGMA table_info($subAssemblyTable)');
  final hasColumn = columns.any((c) => c['name'] == 'componentType');
  if (!hasColumn) {
    await db.execute(
      'ALTER TABLE $subAssemblyTable ADD COLUMN componentType TEXT NOT NULL DEFAULT ""',
    );
  }
}

Future<void> ensureSubAssemblySuperCategoryColumn(Database db) async {
  if (!await hasTable(db, subAssemblyTable)) return;
  final columns = await db.rawQuery('PRAGMA table_info($subAssemblyTable)');
  final hasColumn = columns.any((c) => c['name'] == 'superCategory');
  if (!hasColumn) {
    await db.execute(
      'ALTER TABLE $subAssemblyTable ADD COLUMN superCategory TEXT NOT NULL DEFAULT ""',
    );
  }
}

Future<void> ensureMaintenanceTaskTimeValueColumn(Database db) async {
  if (!await hasTable(db, maintenanceTaskTable)) return;
  final columns = await db.rawQuery('PRAGMA table_info($maintenanceTaskTable)');
  final hasColumn = columns.any((c) => c['name'] == 'timeValue');
  if (!hasColumn) {
    await db.execute(
      'ALTER TABLE $maintenanceTaskTable ADD COLUMN timeValue INTEGER NOT NULL DEFAULT 0',
    );
  }
}

Future<void> ensureMachineLastCheckDateColumn(Database db) async {
  if (!await hasTable(db, machineTable)) return;
  final columns = await db.rawQuery('PRAGMA table_info($machineTable)');
  final hasColumn = columns.any((c) => c['name'] == 'lastCheckDate');
  if (!hasColumn) {
    await db.execute(
      'ALTER TABLE $machineTable ADD COLUMN lastCheckDate TEXT NOT NULL DEFAULT ""',
    );
  }
}

Future<void> ensureMachineLicenseColumns(Database db) async {
  if (!await hasTable(db, machineTable)) {
    return;
  }

  final columns = await db.rawQuery('PRAGMA table_info($machineTable)');
  final hasHvac = columns.any(
    (column) => column['name'] == 'requiresHvacLicense',
  );
  final hasRefrigeration = columns.any(
    (column) => column['name'] == 'requiresRefrigerationLicense',
  );
  final hasPlumber = columns.any(
    (column) => column['name'] == 'requiresPlumberLicense',
  );
  final hasElectrician = columns.any(
    (column) => column['name'] == 'requiresElectricianLicense',
  );
  final hasBoiler = columns.any(
    (column) => column['name'] == 'requiresBoilerLicense',
  );

  if (!hasHvac) {
    await db.execute(
      'ALTER TABLE $machineTable ADD COLUMN requiresHvacLicense INTEGER NOT NULL DEFAULT 0',
    );
  }
  if (!hasRefrigeration) {
    await db.execute(
      'ALTER TABLE $machineTable ADD COLUMN requiresRefrigerationLicense INTEGER NOT NULL DEFAULT 0',
    );
  }
  if (!hasPlumber) {
    await db.execute(
      'ALTER TABLE $machineTable ADD COLUMN requiresPlumberLicense INTEGER NOT NULL DEFAULT 0',
    );
  }
  if (!hasElectrician) {
    await db.execute(
      'ALTER TABLE $machineTable ADD COLUMN requiresElectricianLicense INTEGER NOT NULL DEFAULT 0',
    );
  }
  if (!hasBoiler) {
    await db.execute(
      'ALTER TABLE $machineTable ADD COLUMN requiresBoilerLicense INTEGER NOT NULL DEFAULT 0',
    );
  }
}

/// Trims document numbers and makes blank or duplicate values unique.
///
/// Duplicate detection is case-insensitive; generated suffixes use row IDs so
/// unique indexes can be created without discarding existing records.
Future<void> normalizeAndDedupeDocumentNumbers(
  Database db,
  String tableName,
) async {
  if (!await hasTable(db, tableName)) {
    return;
  }

  await db.execute(
    'UPDATE $tableName SET maintenanceDocumentNumber = TRIM(maintenanceDocumentNumber)',
  );

  final rows = await db.query(
    tableName,
    columns: ['id', 'maintenanceDocumentNumber'],
    orderBy: 'id ASC',
  );

  final seen = <String>{};
  for (final row in rows) {
    final id = row['id'] as int?;
    if (id == null) {
      continue;
    }

    final originalNumber = (row['maintenanceDocumentNumber'] as String?) ?? '';
    final normalized = originalNumber.trim().toUpperCase();

    if (normalized.isEmpty) {
      final fallback = 'DOC-$id';
      await db.update(
        tableName,
        {'maintenanceDocumentNumber': fallback},
        where: 'id = ?',
        whereArgs: [id],
      );
      seen.add(fallback.toUpperCase());
      continue;
    }

    if (!seen.add(normalized)) {
      final deduped = '${originalNumber.trim()}-$id';
      await db.update(
        tableName,
        {'maintenanceDocumentNumber': deduped},
        where: 'id = ?',
        whereArgs: [id],
      );
      seen.add(deduped.toUpperCase());
    }
  }
}

/// Normalizes existing data before enforcing case-insensitive uniqueness.
Future<void> ensureDocumentNumberIndexes(Database db) async {
  await ensureMaintenanceDocumentColumns(db, machineTable);
  await ensureMaintenanceDocumentColumns(db, subAssemblyTable);
  await normalizeAndDedupeDocumentNumbers(db, machineTable);
  await normalizeAndDedupeDocumentNumbers(db, subAssemblyTable);

  await db.execute('''
    CREATE UNIQUE INDEX IF NOT EXISTS idx_machines_doc_number_unique_nocase
    ON machines(maintenanceDocumentNumber COLLATE NOCASE)
    ''');
  await db.execute('''
    CREATE UNIQUE INDEX IF NOT EXISTS idx_sub_assemblies_doc_number_unique_nocase
    ON sub_assemblies(maintenanceDocumentNumber COLLATE NOCASE)
    ''');
}

Future<bool> dbHasMachineDocumentNumber(
  Database db,
  String documentNumber, {
  int? excludeMachineId,
}) async {
  final normalized = documentNumber.trim().toUpperCase();
  if (normalized.isEmpty) {
    return false;
  }

  final where = excludeMachineId != null
      ? 'UPPER(maintenanceDocumentNumber) = ? AND id != ?'
      : 'UPPER(maintenanceDocumentNumber) = ?';
  final whereArgs = excludeMachineId != null
      ? <Object?>[normalized, excludeMachineId]
      : <Object?>[normalized];

  final rows = await db.query(
    machineTable,
    columns: ['id'],
    where: where,
    whereArgs: whereArgs,
    limit: 1,
  );

  return rows.isNotEmpty;
}

Future<bool> dbHasSubAssemblyDocumentNumber(
  Database db,
  String documentNumber, {
  int? excludeMachineId,
}) async {
  final normalized = documentNumber.trim().toUpperCase();
  if (normalized.isEmpty) {
    return false;
  }

  final where = excludeMachineId != null
      ? 'UPPER(maintenanceDocumentNumber) = ? AND machineId != ?'
      : 'UPPER(maintenanceDocumentNumber) = ?';
  final whereArgs = excludeMachineId != null
      ? <Object?>[normalized, excludeMachineId]
      : <Object?>[normalized];

  final rows = await db.query(
    subAssemblyTable,
    columns: ['id'],
    where: where,
    whereArgs: whereArgs,
    limit: 1,
  );

  return rows.isNotEmpty;
}

/// Opens the registry database and applies all creation, upgrade, and
/// idempotent schema-repair callbacks.
Future<Database> openRegistryDatabase(
  DatabaseFactory dbFactory,
  String dbFilePath,
) {
  return dbFactory.openDatabase(
    dbFilePath,
    options: OpenDatabaseOptions(
      version: dbVersion,
      onCreate: (db, version) async {
        await db.execute(createMachineTableSql);
        await db.execute(createSubAssemblyTableSql);
        await db.execute(createMaintenanceTaskTableSql);
        await db.execute(createComponentTypeTableSql);
        await db.execute(createSuperCategoryTypeTableSql);
        await db.execute(createMaintenanceTaskTypeTableSql);
        await db.execute(createLicenseTypeTableSql);
        await db.execute(createMachineRequiredLicenseTableSql);
        await db.execute(createMachineDetailHistoryTableSql);
        await db.execute(createSubAssemblyDetailHistoryTableSql);
        await db.execute(createWorkOrderStatusTableSql);
        await db.execute(createWorkOrderTaskAssignmentTableSql);
        await db.execute(createEmployeeTableSql);
        await db.execute(createSkillTypeTableSql);
        await db.execute(createEmployeeSkillTableSql);
        await db.execute(createEmployeeRequiredLicenseTableSql);
        await ensureDocumentNumberIndexes(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2 && await hasTable(db, machineTable)) {
          await db.execute(
            'ALTER TABLE $machineTable ADD COLUMN modelName TEXT NOT NULL DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $machineTable ADD COLUMN modelNumber TEXT NOT NULL DEFAULT ""',
          );
        }
        if (oldVersion < 3 && await hasTable(db, machineTable)) {
          await db.execute(
            'ALTER TABLE $machineTable ADD COLUMN operatingHours TEXT NOT NULL DEFAULT ""',
          );
          await db.execute(
            'ALTER TABLE $machineTable ADD COLUMN idolHours TEXT NOT NULL DEFAULT ""',
          );
        }
        if (oldVersion < 4) {
          await ensureIdleHoursColumn(db, machineTable);
        }
        if (oldVersion < 5) {
          await ensureSubAssembliesTable(db);
        }
        if (oldVersion < 6) {
          await ensureMaintenanceDocumentColumns(db, machineTable);
          await ensureMaintenanceDocumentColumns(db, subAssemblyTable);
        }
        if (oldVersion < 7) {
          await ensureDocumentNumberIndexes(db);
        }
        if (oldVersion < 8) {
          await ensureMaintenanceTaskTable(db);
        }
        if (oldVersion < 9) {
          await ensureSubAssemblyComponentTypeColumn(db);
          await ensureMaintenanceTaskTimeValueColumn(db);
        }
        if (oldVersion < 10) {
          await ensureMachineLastCheckDateColumn(db);
        }
        if (oldVersion < 11) {
          await ensureMachineDetailHistoryTable(db);
        }
        if (oldVersion < 12) {
          await ensureSubAssemblyDetailHistoryTable(db);
        }
        if (oldVersion < 13) {
          await ensureWorkOrderStatusTable(db);
        }
        if (oldVersion < 14) {
          await ensureWorkOrderStatusMetadataColumns(db);
        }
        if (oldVersion < 15) {
          await ensureMachineLicenseColumns(db);
        }
        if (oldVersion < 16) {
          await ensureWorkOrderStatusMetadataColumns(db);
        }
        if (oldVersion < 17) {
          await ensureMachineLicenseColumns(db);
        }
        if (oldVersion < 18) {
          await ensureComponentTypeTable(db);
        }
        if (oldVersion < 19) {
          await ensureLicenseTypeTable(db);
          await ensureMachineRequiredLicenseTable(db);
        }
        if (oldVersion < 20) {
          await ensureEmployeeTable(db);
          await ensureSkillTypeTable(db);
          await ensureEmployeeSkillTable(db);
        }
        if (oldVersion < 21) {
          await ensureEmployeeRequiredLicenseTable(db);
        }
        if (oldVersion < 22) {
          await ensureWorkOrderTaskAssignmentTable(db);
        }
        if (oldVersion < 23) {
          await ensureSuperCategoryTypeTable(db);
          await ensureMaintenanceTaskTypeTable(db);
          await ensureSubAssemblySuperCategoryColumn(db);
        }
      },
      onOpen: (db) async {
        await ensureMachineTable(db);
        await ensureIdleHoursColumn(db, machineTable);
        await ensureSubAssembliesTable(db);
        await ensureMaintenanceTaskTable(db);
        await ensureComponentTypeTable(db);
        await ensureSuperCategoryTypeTable(db);
        await ensureMaintenanceTaskTypeTable(db);
        await ensureLicenseTypeTable(db);
        await ensureMachineRequiredLicenseTable(db);
        await ensureMachineDetailHistoryTable(db);
        await ensureSubAssemblyDetailHistoryTable(db);
        await ensureWorkOrderStatusTable(db);
        await ensureWorkOrderTaskAssignmentTable(db);
        await ensureWorkOrderStatusMetadataColumns(db);
        await ensureMaintenanceDocumentColumns(db, machineTable);
        await ensureMaintenanceDocumentColumns(db, subAssemblyTable);
        await ensureDocumentNumberIndexes(db);
        await ensureSubAssemblyComponentTypeColumn(db);
        await ensureSubAssemblySuperCategoryColumn(db);
        await ensureMaintenanceTaskTimeValueColumn(db);
        await ensureMachineLastCheckDateColumn(db);
        await ensureMachineLicenseColumns(db);
        await ensureEmployeeTable(db);
        await ensureSkillTypeTable(db);
        await ensureEmployeeSkillTable(db);
        await ensureEmployeeRequiredLicenseTable(db);
      },
    ),
  );
}
