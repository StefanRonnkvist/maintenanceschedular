part of 'package:maintenanceschedular/main.dart';

/// A machine and the licensing and maintenance data attached to it.
///
/// Instances loaded through [MachineDatabase.getMachines] also contain their
/// related licenses and [subAssemblies].
class Machine {
  const Machine({
    this.id,
    required this.name,
    required this.modelName,
    required this.modelNumber,
    required this.operatingHours,
    required this.idleHours,
    required this.lastCheckDate,
    required this.serialNumber,
    required this.location,
    required this.manufacturer,
    required this.maintenanceDocumentName,
    required this.maintenanceDocumentNumber,
    required this.maintenancePublisher,
    this.requiresHvacLicense = false,
    this.requiresRefrigerationLicense = false,
    this.requiresPlumberLicense = false,
    this.requiresElectricianLicense = false,
    this.requiresBoilerLicense = false,
    this.additionalRequiredLicenses = const [],
    this.subAssemblies = const [],
  });

  final int? id;
  final String name;
  final String modelName;
  final String modelNumber;
  final String operatingHours;
  final String idleHours;
  final String lastCheckDate;
  final String serialNumber;
  final String location;
  final String manufacturer;
  final String maintenanceDocumentName;
  final String maintenanceDocumentNumber;
  final String maintenancePublisher;
  final bool requiresHvacLicense;
  final bool requiresRefrigerationLicense;
  final bool requiresPlumberLicense;
  final bool requiresElectricianLicense;
  final bool requiresBoilerLicense;
  final List<String> additionalRequiredLicenses;
  final List<SubAssembly> subAssemblies;

  /// Serializes the columns stored directly in the machine table.
  ///
  /// Related licenses and sub-assemblies are stored in separate tables.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'modelName': modelName,
      'modelNumber': modelNumber,
      'operatingHours': operatingHours,
      'idleHours': idleHours,
      'lastCheckDate': lastCheckDate,
      'serialNumber': serialNumber,
      'location': location,
      'manufacturer': manufacturer,
      'maintenanceDocumentName': maintenanceDocumentName,
      'maintenanceDocumentNumber': maintenanceDocumentNumber,
      'maintenancePublisher': maintenancePublisher,
      'requiresHvacLicense': requiresHvacLicense ? 1 : 0,
      'requiresRefrigerationLicense': requiresRefrigerationLicense ? 1 : 0,
      'requiresPlumberLicense': requiresPlumberLicense ? 1 : 0,
      'requiresElectricianLicense': requiresElectricianLicense ? 1 : 0,
      'requiresBoilerLicense': requiresBoilerLicense ? 1 : 0,
    };
  }

  /// Creates a machine from a database row.
  ///
  /// The legacy `idolHours` spelling remains supported so databases created by
  /// older app versions can still be opened.
  factory Machine.fromMap(Map<String, Object?> map) {
    return Machine(
      id: map['id'] as int?,
      name: map['name'] as String,
      modelName: (map['modelName'] as String?) ?? '',
      modelNumber: (map['modelNumber'] as String?) ?? '',
      operatingHours: (map['operatingHours'] as String?) ?? '',
      idleHours:
          (map['idleHours'] as String?) ?? (map['idolHours'] as String?) ?? '',
      lastCheckDate: (map['lastCheckDate'] as String?) ?? '',
      serialNumber: (map['serialNumber'] as String?) ?? '',
      location: (map['location'] as String?) ?? '',
      manufacturer: (map['manufacturer'] as String?) ?? '',
      maintenanceDocumentName:
          (map['maintenanceDocumentName'] as String?) ?? '',
      maintenanceDocumentNumber:
          (map['maintenanceDocumentNumber'] as String?) ?? '',
      maintenancePublisher: (map['maintenancePublisher'] as String?) ?? '',
      requiresHvacLicense: _asBool(map['requiresHvacLicense']),
      requiresRefrigerationLicense: _asBool(
        map['requiresRefrigerationLicense'],
      ),
      requiresPlumberLicense: _asBool(map['requiresPlumberLicense']),
      requiresElectricianLicense: _asBool(map['requiresElectricianLicense']),
      requiresBoilerLicense: _asBool(map['requiresBoilerLicense']),
    );
  }

  /// Returns a copy with only the supplied values replaced.
  Machine copyWith({
    int? id,
    String? name,
    String? modelName,
    String? modelNumber,
    String? operatingHours,
    String? idleHours,
    String? lastCheckDate,
    String? serialNumber,
    String? location,
    String? manufacturer,
    String? maintenanceDocumentName,
    String? maintenanceDocumentNumber,
    String? maintenancePublisher,
    bool? requiresHvacLicense,
    bool? requiresRefrigerationLicense,
    bool? requiresPlumberLicense,
    bool? requiresElectricianLicense,
    bool? requiresBoilerLicense,
    List<String>? additionalRequiredLicenses,
    List<SubAssembly>? subAssemblies,
  }) {
    return Machine(
      id: id ?? this.id,
      name: name ?? this.name,
      modelName: modelName ?? this.modelName,
      modelNumber: modelNumber ?? this.modelNumber,
      operatingHours: operatingHours ?? this.operatingHours,
      idleHours: idleHours ?? this.idleHours,
      lastCheckDate: lastCheckDate ?? this.lastCheckDate,
      serialNumber: serialNumber ?? this.serialNumber,
      location: location ?? this.location,
      manufacturer: manufacturer ?? this.manufacturer,
      maintenanceDocumentName:
          maintenanceDocumentName ?? this.maintenanceDocumentName,
      maintenanceDocumentNumber:
          maintenanceDocumentNumber ?? this.maintenanceDocumentNumber,
      maintenancePublisher: maintenancePublisher ?? this.maintenancePublisher,
      requiresHvacLicense: requiresHvacLicense ?? this.requiresHvacLicense,
      requiresRefrigerationLicense:
          requiresRefrigerationLicense ?? this.requiresRefrigerationLicense,
      requiresPlumberLicense:
          requiresPlumberLicense ?? this.requiresPlumberLicense,
      requiresElectricianLicense:
          requiresElectricianLicense ?? this.requiresElectricianLicense,
      requiresBoilerLicense:
          requiresBoilerLicense ?? this.requiresBoilerLicense,
      additionalRequiredLicenses:
          additionalRequiredLicenses ?? this.additionalRequiredLicenses,
      subAssemblies: subAssemblies ?? this.subAssemblies,
    );
  }

  /// Normalizes SQLite, CSV, and native boolean representations.
  static bool _asBool(Object? value) {
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
}

/// An employee together with skills and licenses used for work assignment.
class Employee {
  const Employee({
    this.id,
    required this.name,
    this.skills = const [],
    this.licenses = const [],
  });

  final int? id;
  final String name;
  final List<String> skills;
  final List<String> licenses;

  Map<String, Object?> toMap() {
    return {'id': id, 'name': name};
  }

  factory Employee.fromMap(Map<String, Object?> map) {
    return Employee(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
    );
  }

  Employee copyWith({
    int? id,
    String? name,
    List<String>? skills,
    List<String>? licenses,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      skills: skills ?? this.skills,
      licenses: licenses ?? this.licenses,
    );
  }
}

/// A maintainable component belonging to a [Machine].
class SubAssembly {
  const SubAssembly({
    this.id,
    this.machineId,
    required this.name,
    required this.modelName,
    required this.modelNumber,
    required this.operatingHours,
    required this.idleHours,
    required this.serialNumber,
    required this.location,
    required this.manufacturer,
    required this.maintenanceDocumentName,
    required this.maintenanceDocumentNumber,
    required this.maintenancePublisher,
    this.superCategory = '',
    this.subCategory = '',
    this.maintenanceTasks = const [],
  });

  final int? id;
  final int? machineId;
  final String name;
  final String modelName;
  final String modelNumber;
  final String operatingHours;
  final String idleHours;
  final String serialNumber;
  final String location;
  final String manufacturer;
  final String maintenanceDocumentName;
  final String maintenanceDocumentNumber;
  final String maintenancePublisher;
  final String superCategory;
  final String subCategory;
  final List<MaintenanceTask> maintenanceTasks;

  /// Serializes this component using the database's `componentType` column for
  /// the domain-level [subCategory] value.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'machineId': machineId,
      'name': name,
      'modelName': modelName,
      'modelNumber': modelNumber,
      'operatingHours': operatingHours,
      'idleHours': idleHours,
      'serialNumber': serialNumber,
      'location': location,
      'manufacturer': manufacturer,
      'maintenanceDocumentName': maintenanceDocumentName,
      'maintenanceDocumentNumber': maintenanceDocumentNumber,
      'maintenancePublisher': maintenancePublisher,
      'superCategory': superCategory,
      'componentType': subCategory,
    };
  }

  /// Creates a component from a database row, including legacy hour spelling.
  factory SubAssembly.fromMap(Map<String, Object?> map) {
    return SubAssembly(
      id: map['id'] as int?,
      machineId: map['machineId'] as int?,
      name: (map['name'] as String?) ?? '',
      modelName: (map['modelName'] as String?) ?? '',
      modelNumber: (map['modelNumber'] as String?) ?? '',
      operatingHours: (map['operatingHours'] as String?) ?? '',
      idleHours:
          (map['idleHours'] as String?) ?? (map['idolHours'] as String?) ?? '',
      serialNumber: (map['serialNumber'] as String?) ?? '',
      location: (map['location'] as String?) ?? '',
      manufacturer: (map['manufacturer'] as String?) ?? '',
      maintenanceDocumentName:
          (map['maintenanceDocumentName'] as String?) ?? '',
      maintenanceDocumentNumber:
          (map['maintenanceDocumentNumber'] as String?) ?? '',
      maintenancePublisher: (map['maintenancePublisher'] as String?) ?? '',
      superCategory: (map['superCategory'] as String?) ?? '',
      subCategory: (map['componentType'] as String?) ?? '',
    );
  }

  SubAssembly copyWith({
    int? id,
    int? machineId,
    String? name,
    String? modelName,
    String? modelNumber,
    String? operatingHours,
    String? idleHours,
    String? serialNumber,
    String? location,
    String? manufacturer,
    String? maintenanceDocumentName,
    String? maintenanceDocumentNumber,
    String? maintenancePublisher,
    String? superCategory,
    String? subCategory,
    List<MaintenanceTask>? maintenanceTasks,
  }) {
    return SubAssembly(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      name: name ?? this.name,
      modelName: modelName ?? this.modelName,
      modelNumber: modelNumber ?? this.modelNumber,
      operatingHours: operatingHours ?? this.operatingHours,
      idleHours: idleHours ?? this.idleHours,
      serialNumber: serialNumber ?? this.serialNumber,
      location: location ?? this.location,
      manufacturer: manufacturer ?? this.manufacturer,
      maintenanceDocumentName:
          maintenanceDocumentName ?? this.maintenanceDocumentName,
      maintenanceDocumentNumber:
          maintenanceDocumentNumber ?? this.maintenanceDocumentNumber,
      maintenancePublisher: maintenancePublisher ?? this.maintenancePublisher,
      superCategory: superCategory ?? this.superCategory,
      subCategory: subCategory ?? this.subCategory,
      maintenanceTasks: maintenanceTasks ?? this.maintenanceTasks,
    );
  }
}

/// Recurring maintenance work and the interval used to schedule it.
class MaintenanceTask {
  const MaintenanceTask({
    this.id,
    this.subAssemblyId,
    required this.taskType,
    required this.timeCategory,
    this.timeValue = 0,
  });

  final int? id;
  final int? subAssemblyId;
  final String taskType;
  final String timeCategory;
  final int timeValue;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'subAssemblyId': subAssemblyId,
      'taskType': taskType,
      'timeCategory': timeCategory,
      'timeValue': timeValue,
    };
  }

  factory MaintenanceTask.fromMap(Map<String, Object?> map) {
    return MaintenanceTask(
      id: map['id'] as int?,
      subAssemblyId: map['subAssemblyId'] as int?,
      taskType: (map['taskType'] as String?) ?? '',
      timeCategory: (map['timeCategory'] as String?) ?? '',
      timeValue: (map['timeValue'] as int?) ?? 0,
    );
  }

  MaintenanceTask copyWith({
    int? id,
    int? subAssemblyId,
    String? taskType,
    String? timeCategory,
    int? timeValue,
  }) {
    return MaintenanceTask(
      id: id ?? this.id,
      subAssemblyId: subAssemblyId ?? this.subAssemblyId,
      taskType: taskType ?? this.taskType,
      timeCategory: timeCategory ?? this.timeCategory,
      timeValue: timeValue ?? this.timeValue,
    );
  }
}

/// A point-in-time snapshot of a machine's usage details.
class MachineDetailHistoryEntry {
  const MachineDetailHistoryEntry({
    this.id,
    required this.machineId,
    required this.operatingHours,
    required this.idleHours,
    required this.lastCheckDate,
    required this.recordedAtUtc,
  });

  final int? id;
  final int machineId;
  final String operatingHours;
  final String idleHours;
  final String lastCheckDate;
  final String recordedAtUtc;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'machineId': machineId,
      'operatingHours': operatingHours,
      'idleHours': idleHours,
      'lastCheckDate': lastCheckDate,
      'recordedAtUtc': recordedAtUtc,
    };
  }

  factory MachineDetailHistoryEntry.fromMap(Map<String, Object?> map) {
    return MachineDetailHistoryEntry(
      id: map['id'] as int?,
      machineId: (map['machineId'] as int?) ?? 0,
      operatingHours: (map['operatingHours'] as String?) ?? '',
      idleHours:
          (map['idleHours'] as String?) ?? (map['idolHours'] as String?) ?? '',
      lastCheckDate: (map['lastCheckDate'] as String?) ?? '',
      recordedAtUtc: (map['recordedAtUtc'] as String?) ?? '',
    );
  }
}

/// A point-in-time snapshot of a sub-assembly's usage details.
class SubAssemblyDetailHistoryEntry {
  const SubAssemblyDetailHistoryEntry({
    this.id,
    required this.subAssemblyId,
    required this.operatingHours,
    required this.idleHours,
    required this.recordedAtUtc,
  });

  final int? id;
  final int subAssemblyId;
  final String operatingHours;
  final String idleHours;
  final String recordedAtUtc;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'subAssemblyId': subAssemblyId,
      'operatingHours': operatingHours,
      'idleHours': idleHours,
      'recordedAtUtc': recordedAtUtc,
    };
  }

  factory SubAssemblyDetailHistoryEntry.fromMap(Map<String, Object?> map) {
    return SubAssemblyDetailHistoryEntry(
      id: map['id'] as int?,
      subAssemblyId: (map['subAssemblyId'] as int?) ?? 0,
      operatingHours: (map['operatingHours'] as String?) ?? '',
      idleHours:
          (map['idleHours'] as String?) ?? (map['idolHours'] as String?) ?? '',
      recordedAtUtc: (map['recordedAtUtc'] as String?) ?? '',
    );
  }
}

/// Persisted status and notes for work performed on a sub-assembly.
class WorkOrderStatusEntry {
  const WorkOrderStatusEntry({
    this.id,
    required this.subAssemblyId,
    required this.status,
    required this.enteredAtUtc,
    this.isRescheduled = false,
    this.isLicensedWork = false,
    this.notes = '',
  });

  final int? id;
  final int subAssemblyId;
  final String status;
  final String enteredAtUtc;
  final bool isRescheduled;
  final bool isLicensedWork;
  final String notes;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'subAssemblyId': subAssemblyId,
      'status': status,
      'enteredAtUtc': enteredAtUtc,
      'isRescheduled': isRescheduled ? 1 : 0,
      'isLicensedWork': isLicensedWork ? 1 : 0,
      'notes': notes,
    };
  }

  factory WorkOrderStatusEntry.fromMap(Map<String, Object?> map) {
    return WorkOrderStatusEntry(
      id: map['id'] as int?,
      subAssemblyId: (map['subAssemblyId'] as int?) ?? 0,
      status: (map['status'] as String?) ?? '',
      enteredAtUtc: (map['enteredAtUtc'] as String?) ?? '',
      isRescheduled: ((map['isRescheduled'] as num?) ?? 0) == 1,
      isLicensedWork: ((map['isLicensedWork'] as num?) ?? 0) == 1,
      notes: (map['notes'] as String?) ?? '',
    );
  }
}
