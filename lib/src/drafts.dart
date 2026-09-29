part of 'package:maintenanceschedular/main.dart';

/// Mutable form state used to create or edit a [Machine].
///
/// This object owns every controller it creates; callers must invoke [dispose]
/// when the form is permanently removed.
class MachineDraft {
  MachineDraft({Machine? machine})
    : nameController = TextEditingController(text: machine?.name ?? ''),
      modelNameController = TextEditingController(
        text: machine?.modelName ?? '',
      ),
      modelNumberController = TextEditingController(
        text: machine?.modelNumber ?? '',
      ),
      operatingHoursController = TextEditingController(
        text: machine?.operatingHours ?? '',
      ),
      idleHoursController = TextEditingController(
        text: machine?.idleHours ?? '',
      ),
      lastCheckDateController = TextEditingController(
        text: machine?.lastCheckDate ?? '',
      ),
      serialNumberController = TextEditingController(
        text: machine?.serialNumber ?? '',
      ),
      locationController = TextEditingController(text: machine?.location ?? ''),
      manufacturerController = TextEditingController(
        text: machine?.manufacturer ?? '',
      ),
      maintenanceDocumentNameController = TextEditingController(
        text: machine?.maintenanceDocumentName ?? '',
      ),
      maintenanceDocumentNumberController = TextEditingController(
        text: machine?.maintenanceDocumentNumber ?? '',
      ),
      maintenancePublisherController = TextEditingController(
        text: machine?.maintenancePublisher ?? '',
      ),
      requiresHvacLicense = machine?.requiresHvacLicense ?? false,
      requiresRefrigerationLicense =
          machine?.requiresRefrigerationLicense ?? false,
      requiresPlumberLicense = machine?.requiresPlumberLicense ?? false,
      requiresElectricianLicense = machine?.requiresElectricianLicense ?? false,
      requiresBoilerLicense = machine?.requiresBoilerLicense ?? false,
      additionalRequiredLicenses = Set<String>.from(
        machine?.additionalRequiredLicenses ?? const [],
      );

  final TextEditingController nameController;
  final TextEditingController modelNameController;
  final TextEditingController modelNumberController;
  final TextEditingController operatingHoursController;
  final TextEditingController idleHoursController;
  final TextEditingController lastCheckDateController;
  final TextEditingController serialNumberController;
  final TextEditingController locationController;
  final TextEditingController manufacturerController;
  final TextEditingController maintenanceDocumentNameController;
  final TextEditingController maintenanceDocumentNumberController;
  final TextEditingController maintenancePublisherController;
  bool requiresHvacLicense;
  bool requiresRefrigerationLicense;
  bool requiresPlumberLicense;
  bool requiresElectricianLicense;
  bool requiresBoilerLicense;
  final Set<String> additionalRequiredLicenses;

  /// Builds an immutable machine after trimming text and empty license names.
  Machine toMachine({int? id, List<SubAssembly> subAssemblies = const []}) {
    return Machine(
      id: id,
      name: nameController.text.trim(),
      modelName: modelNameController.text.trim(),
      modelNumber: modelNumberController.text.trim(),
      operatingHours: operatingHoursController.text.trim(),
      idleHours: idleHoursController.text.trim(),
      lastCheckDate: lastCheckDateController.text.trim(),
      serialNumber: serialNumberController.text.trim(),
      location: locationController.text.trim(),
      manufacturer: manufacturerController.text.trim(),
      maintenanceDocumentName: maintenanceDocumentNameController.text.trim(),
      maintenanceDocumentNumber: maintenanceDocumentNumberController.text
          .trim(),
      maintenancePublisher: maintenancePublisherController.text.trim(),
      requiresHvacLicense: requiresHvacLicense,
      requiresRefrigerationLicense: requiresRefrigerationLicense,
      requiresPlumberLicense: requiresPlumberLicense,
      requiresElectricianLicense: requiresElectricianLicense,
      requiresBoilerLicense: requiresBoilerLicense,
      additionalRequiredLicenses: additionalRequiredLicenses
          .map((license) => license.trim())
          .where((license) => license.isNotEmpty)
          .toList(growable: false),
      subAssemblies: subAssemblies,
    );
  }

  /// Resets the form for reuse while keeping its controllers alive.
  void clear() {
    nameController.clear();
    modelNameController.clear();
    modelNumberController.clear();
    operatingHoursController.clear();
    idleHoursController.clear();
    lastCheckDateController.clear();
    serialNumberController.clear();
    locationController.clear();
    manufacturerController.clear();
    maintenanceDocumentNameController.clear();
    maintenanceDocumentNumberController.clear();
    maintenancePublisherController.clear();
    requiresHvacLicense = false;
    requiresRefrigerationLicense = false;
    requiresPlumberLicense = false;
    requiresElectricianLicense = false;
    requiresBoilerLicense = false;
    additionalRequiredLicenses.clear();
  }

  /// Releases all text controllers owned by this draft.
  void dispose() {
    nameController.dispose();
    modelNameController.dispose();
    modelNumberController.dispose();
    operatingHoursController.dispose();
    idleHoursController.dispose();
    lastCheckDateController.dispose();
    serialNumberController.dispose();
    locationController.dispose();
    manufacturerController.dispose();
    maintenanceDocumentNameController.dispose();
    maintenanceDocumentNumberController.dispose();
    maintenancePublisherController.dispose();
  }
}

/// Mutable form state for one recurring [MaintenanceTask].
class MaintenanceTaskDraft {
  MaintenanceTaskDraft({MaintenanceTask? task})
    : taskType = task?.taskType ?? _maintenanceTaskTypes.first,
      timeCategory = task?.timeCategory ?? _maintenanceTimeCategories.first,
      timeValueController = TextEditingController(
        text: '${(task?.timeValue ?? 0) > 0 ? task!.timeValue : 1}',
      );

  String taskType;
  String timeCategory;
  final TextEditingController timeValueController;

  /// Returns the entered interval, defaulting invalid input to one unit.
  int get timeValue => int.tryParse(timeValueController.text.trim()) ?? 1;

  MaintenanceTask toMaintenanceTask({int? id, int? subAssemblyId}) {
    return MaintenanceTask(
      id: id,
      subAssemblyId: subAssemblyId,
      taskType: taskType,
      timeCategory: timeCategory,
      timeValue: timeValue,
    );
  }

  void dispose() {
    timeValueController.dispose();
  }
}

/// Mutable form state for a [SubAssembly] and its nested maintenance tasks.
///
/// Disposing this draft also disposes all child [MaintenanceTaskDraft] objects.
class SubAssemblyDraft {
  SubAssemblyDraft({SubAssembly? subAssembly})
    : nameController = TextEditingController(text: subAssembly?.name ?? ''),
      modelNameController = TextEditingController(
        text: subAssembly?.modelName ?? '',
      ),
      modelNumberController = TextEditingController(
        text: subAssembly?.modelNumber ?? '',
      ),
      operatingHoursController = TextEditingController(
        text: subAssembly?.operatingHours ?? '',
      ),
      idleHoursController = TextEditingController(
        text: subAssembly?.idleHours ?? '',
      ),
      serialNumberController = TextEditingController(
        text: subAssembly?.serialNumber ?? '',
      ),
      locationController = TextEditingController(
        text: subAssembly?.location ?? '',
      ),
      manufacturerController = TextEditingController(
        text: subAssembly?.manufacturer ?? '',
      ),
      maintenanceDocumentNameController = TextEditingController(
        text: subAssembly?.maintenanceDocumentName ?? '',
      ),
      maintenanceDocumentNumberController = TextEditingController(
        text: subAssembly?.maintenanceDocumentNumber ?? '',
      ),
      maintenancePublisherController = TextEditingController(
        text: subAssembly?.maintenancePublisher ?? '',
      ),
      superCategory = subAssembly?.superCategory ?? '',
      subCategory = subAssembly?.subCategory ?? '',
      maintenanceTaskDrafts = (subAssembly?.maintenanceTasks ?? const [])
          .map((task) => MaintenanceTaskDraft(task: task))
          .toList(growable: true);

  final TextEditingController nameController;
  final TextEditingController modelNameController;
  final TextEditingController modelNumberController;
  final TextEditingController operatingHoursController;
  final TextEditingController idleHoursController;
  final TextEditingController serialNumberController;
  final TextEditingController locationController;
  final TextEditingController manufacturerController;
  final TextEditingController maintenanceDocumentNameController;
  final TextEditingController maintenanceDocumentNumberController;
  final TextEditingController maintenancePublisherController;
  String superCategory;
  String subCategory;
  bool importDocFromParent = false;
  final List<MaintenanceTaskDraft> maintenanceTaskDrafts;

  /// Builds an immutable component and converts all nested task drafts.
  SubAssembly toSubAssembly({int? id, int? machineId}) {
    return SubAssembly(
      id: id,
      machineId: machineId,
      name: nameController.text.trim(),
      modelName: modelNameController.text.trim(),
      modelNumber: modelNumberController.text.trim(),
      operatingHours: operatingHoursController.text.trim(),
      idleHours: idleHoursController.text.trim(),
      serialNumber: serialNumberController.text.trim(),
      location: locationController.text.trim(),
      manufacturer: manufacturerController.text.trim(),
      maintenanceDocumentName: maintenanceDocumentNameController.text.trim(),
      maintenanceDocumentNumber: maintenanceDocumentNumberController.text
          .trim(),
      maintenancePublisher: maintenancePublisherController.text.trim(),
      superCategory: superCategory,
      subCategory: subCategory,
      maintenanceTasks: maintenanceTaskDrafts
          .map((draft) => draft.toMaintenanceTask())
          .toList(growable: false),
    );
  }

  void dispose() {
    nameController.dispose();
    modelNameController.dispose();
    modelNumberController.dispose();
    operatingHoursController.dispose();
    idleHoursController.dispose();
    serialNumberController.dispose();
    locationController.dispose();
    manufacturerController.dispose();
    maintenanceDocumentNameController.dispose();
    maintenanceDocumentNumberController.dispose();
    maintenancePublisherController.dispose();
    for (final taskDraft in maintenanceTaskDrafts) {
      taskDraft.dispose();
    }
  }
}
