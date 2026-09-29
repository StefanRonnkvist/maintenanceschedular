part of 'package:maintenanceschedular/main.dart';

class MachineEntryPage extends StatefulWidget {
  const MachineEntryPage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<MachineEntryPage> createState() => _MachineEntryPageState();
}

class _MachineEntryPageState extends State<MachineEntryPage> {
  static const ValueKey<String> _licenseTypeSectionKey = ValueKey<String>(
    'license-type-section',
  );
  static const String _tabOrderPreferenceKey = 'machineRegistryTabOrderV1';
  static const String _employeeSearchPreferenceKey = 'employeeSearchQueryV1';
  static const String _employeeFilterSkillPreferenceKey =
      'employeeFilterSkillV1';
  static const String _employeeSortPreferenceKey = 'employeeSortModeV1';
  static const List<_AppTab> _defaultTabOrder = [
    _AppTab.addMachine,
    _AppTab.machinesList,
    _AppTab.employees,
    _AppTab.maintenanceDue,
    _AppTab.workOrders,
    _AppTab.calendar,
    _AppTab.editMachines,
    _AppTab.help,
    _AppTab.information,
  ];

  static const List<String> _workOrderStatusOptions = [
    'Work Complete',
    'Partial',
    'Bypass',
  ];
  static const List<String> _baseLicenseTypes = [
    'HVAC',
    'Refrigeration',
    'Plumber',
    'Electrician',
    'Boiler',
  ];
  static const List<String> _defaultEmployeeSkills = [
    'Mechanic',
    'Electronics Technician',
    'General Labor',
  ];
  static const Set<String> _reschedulableWorkStatuses = {'Partial', 'Bypass'};

  final _formKey = GlobalKey<FormState>();
  final MachineDraft _machineDraft = MachineDraft();
  final List<SubAssemblyDraft> _subAssemblyDrafts = [];
  final TextEditingController _taskSearchController = TextEditingController();
  final Map<int, _MachineDetailEditDraft> _maintenanceDueDetailDrafts = {};
  final Map<int, Future<List<MachineDetailHistoryEntry>>>
  _machineDetailHistoryFutures = {};
  final Map<int, _SubAssemblyDetailEditDraft> _subAssemblyDetailDrafts = {};
  final Map<int, Future<List<SubAssemblyDetailHistoryEntry>>>
  _subAssemblyDetailHistoryFutures = {};
  final Map<int, Future<WorkOrderStatusEntry?>> _workOrderStatusFutures = {};
  final Map<int, Future<Map<int, String>>> _workOrderTaskAssignmentFutures = {};
  final Map<int, String> _workOrderStatusSelectionDrafts = {};
  final Map<int, bool> _workOrderRescheduledDrafts = {};
  final Map<int, bool> _workOrderLicensedWorkDrafts = {};
  final Map<int, String> _workOrderStatusNotesDrafts = {};
  final Map<String, String> _workOrderTaskAssigneeDrafts = {};

  final List<Machine> _machines = [];
  final List<Employee> _employees = [];
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _employeeSearchController =
      TextEditingController();
  final Set<String> _selectedEmployeeSkills = <String>{};
  final Set<String> _selectedEmployeeLicenses = <String>{};
  bool _isLoading = false;
  bool _hasLoadedSkillTypes = false;
  BuildContext? _tabSwitcherContext;
  bool _hasAttemptedAutoReload = true;
  bool _hasShownStartupPrompt = false;
  bool _showWebDatabaseNotice = kIsWeb;
  String? _selectedTaskType;
  String? _selectedTaskTimeCategory;
  String? _selectedSubCategory;
  String? _selectedSuperCategory;
  final List<String> _superCategoryOptions = List<String>.from(
    _maintenanceSuperCategory,
  );
  final List<String> _subCategoryOptions = List<String>.from(_subCategories);
  final List<String> _maintenanceTaskTypeOptions = List<String>.from(
    _maintenanceTaskTypes,
  );
  final List<String> _licenseTypeOptions = List<String>.from(_baseLicenseTypes);
  final List<String> _skillTypeOptions = [];
  String _employeeSearchQuery = '';
  String? _selectedEmployeeFilterSkill;
  _EmployeeSortMode _employeeSortMode = _EmployeeSortMode.nameAsc;
  String _taskSearchQuery = '';
  List<_AppTab> _tabOrder = List<_AppTab>.from(_defaultTabOrder);

  _ResponsiveLayout _layoutForWidth(double width) {
    if (width >= 1200) {
      return _ResponsiveLayout.desktop;
    }
    if (width >= 700) {
      return _ResponsiveLayout.tablet;
    }
    return _ResponsiveLayout.phone;
  }

  double _maxContentWidthForLayout(_ResponsiveLayout layout) {
    switch (layout) {
      case _ResponsiveLayout.phone:
        return double.infinity;
      case _ResponsiveLayout.tablet:
        return 960;
      case _ResponsiveLayout.desktop:
        return 1400;
    }
  }

  EdgeInsets _contentPaddingForLayout(_ResponsiveLayout layout) {
    switch (layout) {
      case _ResponsiveLayout.phone:
        return const EdgeInsets.all(12);
      case _ResponsiveLayout.tablet:
        return const EdgeInsets.all(18);
      case _ResponsiveLayout.desktop:
        return const EdgeInsets.all(24);
    }
  }

  _ResponsiveLayout _layoutForContext(BuildContext context) {
    return _layoutForWidth(MediaQuery.sizeOf(context).width);
  }

  double _cardPaddingForLayout(_ResponsiveLayout layout) {
    switch (layout) {
      case _ResponsiveLayout.phone:
        return 12;
      case _ResponsiveLayout.tablet:
        return 16;
      case _ResponsiveLayout.desktop:
        return 20;
    }
  }

  double _fieldGapForLayout(_ResponsiveLayout layout) {
    switch (layout) {
      case _ResponsiveLayout.phone:
        return 10;
      case _ResponsiveLayout.tablet:
        return 12;
      case _ResponsiveLayout.desktop:
        return 14;
    }
  }

  VisualDensity _visualDensityForLayout(_ResponsiveLayout layout) {
    switch (layout) {
      case _ResponsiveLayout.phone:
        return VisualDensity.compact;
      case _ResponsiveLayout.tablet:
        return VisualDensity.standard;
      case _ResponsiveLayout.desktop:
        return VisualDensity.comfortable;
    }
  }

  double _dialogMaxWidthForLayout(_ResponsiveLayout layout) {
    switch (layout) {
      case _ResponsiveLayout.phone:
        return 520;
      case _ResponsiveLayout.tablet:
        return 860;
      case _ResponsiveLayout.desktop:
        return 1040;
    }
  }

  EdgeInsets _dialogInsetPaddingForLayout(_ResponsiveLayout layout) {
    switch (layout) {
      case _ResponsiveLayout.phone:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 20);
      case _ResponsiveLayout.tablet:
        return const EdgeInsets.symmetric(horizontal: 28, vertical: 24);
      case _ResponsiveLayout.desktop:
        return const EdgeInsets.symmetric(horizontal: 40, vertical: 28);
    }
  }

  List<Widget> _dialogActionsForContext(
    BuildContext context,
    List<Widget> actions,
  ) {
    final isNarrowPhone = _isNarrowPhoneContext(context);
    if (!isNarrowPhone) {
      return actions;
    }

    return [
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: actions[i]),
          ],
        ],
      ),
    ];
  }

  bool _isNarrowPhoneContext(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 380;
  }

  String _cancelActionLabel(BuildContext context) {
    return _isNarrowPhoneContext(context) ? 'Back' : 'Cancel';
  }

  List<String> _machineLicenseTradeLabels(Machine machine) {
    final labels = <String>[];
    if (machine.requiresHvacLicense) {
      labels.add('HVAC');
    }
    if (machine.requiresRefrigerationLicense) {
      labels.add('Refrigeration');
    }
    if (machine.requiresPlumberLicense) {
      labels.add('Plumber');
    }
    if (machine.requiresElectricianLicense) {
      labels.add('Electrician');
    }
    if (machine.requiresBoilerLicense) {
      labels.add('Boiler');
    }
    for (final license in machine.additionalRequiredLicenses) {
      final trimmed = license.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      if (!labels.contains(trimmed)) {
        labels.add(trimmed);
      }
    }
    return labels;
  }

  Widget _buildMachineLicenseRequirementChips(Machine machine) {
    final labels = _machineLicenseTradeLabels(machine);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'License Required Trades',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: labels.isEmpty
              ? const [Chip(label: Text('None'))]
              : labels
                    .map((label) => Chip(label: Text(label)))
                    .toList(growable: false),
        ),
      ],
    );
  }

  String _deleteActionLabel(BuildContext context) {
    return _isNarrowPhoneContext(context) ? 'Remove' : 'Delete';
  }

  ThemeData _themeForLayout(ThemeData baseTheme, _ResponsiveLayout layout) {
    final textScale = switch (layout) {
      _ResponsiveLayout.phone => 0.95,
      _ResponsiveLayout.tablet => 1.0,
      _ResponsiveLayout.desktop => 1.08,
    };

    TextStyle? scaled(TextStyle? style) {
      if (style == null) {
        return null;
      }
      final fontSize = style.fontSize;
      return style.copyWith(
        fontSize: fontSize == null ? null : fontSize * textScale,
        height: style.height ?? 1.25,
      );
    }

    final textTheme = baseTheme.textTheme;
    final scaledTextTheme = textTheme.copyWith(
      titleLarge: scaled(textTheme.titleLarge),
      titleMedium: scaled(textTheme.titleMedium),
      titleSmall: scaled(textTheme.titleSmall),
      bodyLarge: scaled(textTheme.bodyLarge),
      bodyMedium: scaled(textTheme.bodyMedium),
      labelLarge: scaled(textTheme.labelLarge),
    );

    final inputPadding = switch (layout) {
      _ResponsiveLayout.phone => const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      _ResponsiveLayout.tablet => const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      _ResponsiveLayout.desktop => const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),
    };

    return baseTheme.copyWith(
      visualDensity: _visualDensityForLayout(layout),
      textTheme: scaledTextTheme,
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        isDense: layout == _ResponsiveLayout.phone,
        contentPadding: inputPadding,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadTabOrderPreference();
    _loadEmployeeListViewPreferences();

    if (kIsWeb) {
      _isLoading = false;
      return;
    }

    _initializeStartupData();
  }

  Future<void> _initializeStartupData() async {
    await _loadMachines();

    Future<void>(() async {
      await Future.wait<void>([
        _loadEmployees(),
        _initializeSuperCategories(),
        _initializeSubCategories(),
        _initializeMaintenanceTaskTypes(),
        _initializeLicenseTypes(),
        _initializeEmployeeSkills(),
      ]);
    });
  }

  List<String> get _availableSuperCategories => _superCategoryOptions.isEmpty
      ? List<String>.from(_maintenanceSuperCategory)
      : List<String>.from(_superCategoryOptions);

  List<String> get _customSuperCategories {
    final baseNormalized = _maintenanceSuperCategory
        .map((category) => category.toUpperCase())
        .toSet();
    return _availableSuperCategories
        .where((category) => !baseNormalized.contains(category.toUpperCase()))
        .toList(growable: false);
  }

  List<String> get _availableSubCategories => _subCategoryOptions.isEmpty
      ? List<String>.from(_subCategories)
      : List<String>.from(_subCategoryOptions);

  List<String> get _availableMaintenanceTaskTypes =>
      _maintenanceTaskTypeOptions.isEmpty
      ? List<String>.from(_maintenanceTaskTypes)
      : List<String>.from(_maintenanceTaskTypeOptions);

  List<String> get _customMaintenanceTaskTypes {
    final baseNormalized = _maintenanceTaskTypes
        .map((taskType) => taskType.toUpperCase())
        .toSet();
    return _availableMaintenanceTaskTypes
        .where((taskType) => !baseNormalized.contains(taskType.toUpperCase()))
        .toList(growable: false);
  }

  List<String> get _customSubCategories {
    final baseNormalized = _subCategories
        .map((componentType) => componentType.toUpperCase())
        .toSet();
    return _availableSubCategories
        .where(
          (componentType) =>
              !baseNormalized.contains(componentType.toUpperCase()),
        )
        .toList(growable: false);
  }

  List<String> get _availableLicenseTypes {
    final normalized = <String>{};
    final merged = <String>[];

    for (final type in [..._baseLicenseTypes, ..._licenseTypeOptions]) {
      final trimmed = type.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final key = trimmed.toUpperCase();
      if (normalized.add(key)) {
        merged.add(trimmed);
      }
    }

    return merged;
  }

  List<String> get _customLicenseTypes {
    final baseNormalized = _baseLicenseTypes
        .map((license) => license.toUpperCase())
        .toSet();
    return _availableLicenseTypes
        .where((license) => !baseNormalized.contains(license.toUpperCase()))
        .toList(growable: false);
  }

  List<String> get _availableSkillTypes {
    if (!_hasLoadedSkillTypes) {
      return List<String>.from(_defaultEmployeeSkills);
    }

    final normalized = <String>{};
    final merged = <String>[];

    for (final type in _skillTypeOptions) {
      final trimmed = type.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final key = trimmed.toUpperCase();
      if (normalized.add(key)) {
        merged.add(trimmed);
      }
    }

    return merged;
  }

  Future<void> _initializeLicenseTypes() async {
    try {
      await MachineDatabase.instance.ensureDefaultLicenseTypes(
        _baseLicenseTypes,
      );
      await _refreshLicenseTypes();
    } catch (_) {
      // Keep built-in defaults available even if DB-backed list fails to load.
    }
  }

  Future<void> _refreshLicenseTypes() async {
    final savedTypes = await MachineDatabase.instance.getLicenseTypes();
    if (!mounted) {
      return;
    }

    setState(() {
      _licenseTypeOptions
        ..clear()
        ..addAll(savedTypes);
    });
  }

  Future<void> _showAddLicenseTypeDialog({
    void Function(String type)? onSaved,
  }) async {
    final controller = TextEditingController();
    try {
      final enteredType = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Add License Type'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'License Type',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
            ),
            actions: _dialogActionsForContext(dialogContext, [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(_cancelActionLabel(dialogContext)),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                },
                child: const Text('Save'),
              ),
            ]),
          );
        },
      );

      final normalized = enteredType?.trim() ?? '';
      if (normalized.isEmpty) {
        return;
      }

      final savedType = await MachineDatabase.instance.addLicenseType(
        normalized,
      );
      if (savedType == null || savedType.trim().isEmpty) {
        return;
      }

      final finalType = savedType.trim();
      await _refreshLicenseTypes();
      onSaved?.call(finalType);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('License type "$finalType" saved.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar('Failed to save license type.', error);
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showManageLicenseTypesDialog({
    void Function(String oldName, String newName)? onRenamed,
    void Function(String deletedName)? onDeleted,
  }) async {
    if (_customLicenseTypes.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No custom license types to manage.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final customLicenses = _customLicenseTypes;
            return AlertDialog(
              title: const Text('Manage License Types'),
              content: SizedBox(
                width: 520,
                child: customLicenses.isEmpty
                    ? const Text('No custom license types to manage.')
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: customLicenses.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final license = customLicenses[index];
                          return ListTile(
                            title: Text(license),
                            trailing: Wrap(
                              spacing: 6,
                              children: [
                                IconButton(
                                  tooltip: 'Rename',
                                  onPressed: () async {
                                    final renamedTo =
                                        await _showRenameLicenseTypeDialog(
                                          license,
                                        );
                                    if (renamedTo == null || !mounted) {
                                      return;
                                    }
                                    onRenamed?.call(license, renamedTo);
                                    await _refreshLicenseTypes();
                                    if (dialogContext.mounted) {
                                      setDialogState(() {});
                                    }
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () async {
                                    final shouldDelete =
                                        await _confirmDeleteLicenseType(
                                          license,
                                        );
                                    if (!shouldDelete || !mounted) {
                                      return;
                                    }
                                    onDeleted?.call(license);
                                    await _refreshLicenseTypes();
                                    if (dialogContext.mounted) {
                                      setDialogState(() {});
                                    }
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              actions: _dialogActionsForContext(dialogContext, [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Done'),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  Future<String?> _showRenameLicenseTypeDialog(String currentName) async {
    final controller = TextEditingController(text: currentName);
    try {
      final nextName = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Rename License Type'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'License Type',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
            ),
            actions: _dialogActionsForContext(dialogContext, [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(_cancelActionLabel(dialogContext)),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                },
                child: const Text('Save'),
              ),
            ]),
          );
        },
      );

      final normalized = nextName?.trim() ?? '';
      if (normalized.isEmpty ||
          normalized.toUpperCase() == currentName.toUpperCase()) {
        return null;
      }

      final renamed = await MachineDatabase.instance.renameLicenseType(
        currentName,
        normalized,
      );
      if (renamed == null || renamed.trim().isEmpty) {
        return null;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'License type "$currentName" renamed to "${renamed.trim()}".',
            ),
          ),
        );
      }

      return renamed.trim();
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Failed to rename license type.', error);
      }
      return null;
    } finally {
      controller.dispose();
    }
  }

  Future<bool> _confirmDeleteLicenseType(String licenseType) async {
    try {
      final usageCount = await MachineDatabase.instance
          .getMachineRequiredLicenseUsageCount(licenseType);
      if (!mounted) {
        return false;
      }

      if (usageCount > 0) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Cannot Delete License Type'),
              content: Text(
                '"$licenseType" is currently used by $usageCount machine(s). Remove it from those machines before deleting this license type.',
              ),
              actions: _dialogActionsForContext(dialogContext, [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ]),
            );
          },
        );
        return false;
      }

      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Delete License Type'),
            content: Text('Delete "$licenseType"?'),
            actions: _dialogActionsForContext(dialogContext, [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(_cancelActionLabel(dialogContext)),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(_deleteActionLabel(dialogContext)),
              ),
            ]),
          );
        },
      );

      if (shouldDelete != true) {
        return false;
      }

      await MachineDatabase.instance.deleteLicenseType(licenseType);
      await _loadMachines(seedSampleData: false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('License type "$licenseType" deleted.')),
        );
      }

      return true;
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Failed to delete license type.', error);
      }
      return false;
    }
  }

  Future<void> _initializeSuperCategories() async {
    try {
      await MachineDatabase.instance.ensureDefaultSuperCategoryTypes(
        _maintenanceSuperCategory,
      );
      await MachineDatabase.instance.syncSuperCategoryTypesFromSubAssemblies();
      await _refreshSuperCategories();
    } catch (_) {
      // Keep built-in defaults available even if DB-backed list fails to load.
    }
  }

  Future<void> _refreshSuperCategories({String? selectedCategory}) async {
    final savedTypes = await MachineDatabase.instance.getSuperCategoryTypes();
    if (!mounted) {
      return;
    }

    setState(() {
      _superCategoryOptions
        ..clear()
        ..addAll(savedTypes);

      if (selectedCategory != null && selectedCategory.trim().isNotEmpty) {
        _selectedSuperCategory = selectedCategory.trim();
      } else if (_selectedSuperCategory != null &&
          !_superCategoryOptions.contains(_selectedSuperCategory)) {
        _selectedSuperCategory = null;
      }
    });
  }

  Future<void> _showAddSuperCategoryDialog({
    void Function(String type)? onSaved,
  }) async {
    final controller = TextEditingController();
    try {
      final enteredType = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Add Super Category'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Super Category',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
            ),
            actions: _dialogActionsForContext(dialogContext, [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(_cancelActionLabel(dialogContext)),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                },
                child: const Text('Save'),
              ),
            ]),
          );
        },
      );

      final normalized = enteredType?.trim() ?? '';
      if (normalized.isEmpty) {
        return;
      }

      final savedType = await MachineDatabase.instance.addSuperCategoryType(
        normalized,
      );
      if (savedType == null || savedType.trim().isEmpty) {
        return;
      }

      final finalType = savedType.trim();
      await _refreshSuperCategories(selectedCategory: finalType);
      onSaved?.call(finalType);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Super category "$finalType" saved.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar('Failed to save super category.', error);
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showManageSuperCategoriesDialog({
    void Function(String deletedName)? onDeleted,
  }) async {
    if (_customSuperCategories.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No custom super categories to manage.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final customTypes = _customSuperCategories;
            return AlertDialog(
              title: const Text('Manage Super Categories'),
              content: SizedBox(
                width: 520,
                child: customTypes.isEmpty
                    ? const Text('No custom super categories to manage.')
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: customTypes.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final superCategory = customTypes[index];
                          return ListTile(
                            title: Text(superCategory),
                            trailing: IconButton(
                              tooltip: 'Delete',
                              onPressed: () async {
                                final shouldDelete =
                                    await _confirmDeleteSuperCategory(
                                      superCategory,
                                    );
                                if (!shouldDelete || !mounted) {
                                  return;
                                }
                                onDeleted?.call(superCategory);
                                await _refreshSuperCategories();
                                if (dialogContext.mounted) {
                                  setDialogState(() {});
                                }
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          );
                        },
                      ),
              ),
              actions: _dialogActionsForContext(dialogContext, [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Done'),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmDeleteSuperCategory(String superCategory) async {
    try {
      final usageCount = await MachineDatabase.instance
          .getSubAssemblySuperCategoryUsageCount(superCategory);
      if (!mounted) {
        return false;
      }

      if (usageCount > 0) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Cannot Delete Super Category'),
              content: Text(
                '"$superCategory" is currently used by $usageCount sub-assemblies. Remove it from those records before deleting this super category.',
              ),
              actions: _dialogActionsForContext(dialogContext, [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ]),
            );
          },
        );
        return false;
      }

      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Delete Super Category'),
            content: Text('Delete "$superCategory"?'),
            actions: _dialogActionsForContext(dialogContext, [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(_cancelActionLabel(dialogContext)),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(_deleteActionLabel(dialogContext)),
              ),
            ]),
          );
        },
      );

      if (shouldDelete != true) {
        return false;
      }

      await MachineDatabase.instance.deleteSuperCategoryType(superCategory);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Super category "$superCategory" deleted.')),
        );
      }
      return true;
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Failed to delete super category.', error);
      }
      return false;
    }
  }

  Future<void> _initializeMaintenanceTaskTypes() async {
    try {
      await MachineDatabase.instance.ensureDefaultMaintenanceTaskTypes(
        _maintenanceTaskTypes,
      );
      await MachineDatabase.instance.syncMaintenanceTaskTypesFromTasks();
      await _refreshMaintenanceTaskTypes();
    } catch (_) {
      // Keep built-in defaults available even if DB-backed list fails to load.
    }
  }

  Future<void> _refreshMaintenanceTaskTypes() async {
    final savedTypes = await MachineDatabase.instance.getMaintenanceTaskTypes();
    if (!mounted) {
      return;
    }

    setState(() {
      _maintenanceTaskTypeOptions
        ..clear()
        ..addAll(savedTypes);

      if (_selectedTaskType != null &&
          !_maintenanceTaskTypeOptions.contains(_selectedTaskType)) {
        _selectedTaskType = null;
      }
    });
  }

  Future<void> _showAddMaintenanceTaskTypeDialog({
    void Function(String type)? onSaved,
  }) async {
    final controller = TextEditingController();
    try {
      final enteredType = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Add Maintenance Task Type'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Task Type',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
            ),
            actions: _dialogActionsForContext(dialogContext, [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(_cancelActionLabel(dialogContext)),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                },
                child: const Text('Save'),
              ),
            ]),
          );
        },
      );

      final normalized = enteredType?.trim() ?? '';
      if (normalized.isEmpty) {
        return;
      }

      final savedType = await MachineDatabase.instance.addMaintenanceTaskType(
        normalized,
      );
      if (savedType == null || savedType.trim().isEmpty) {
        return;
      }

      final finalType = savedType.trim();
      await _refreshMaintenanceTaskTypes();
      onSaved?.call(finalType);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Task type "$finalType" saved.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar('Failed to save task type.', error);
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showManageMaintenanceTaskTypesDialog({
    void Function(String deletedName)? onDeleted,
  }) async {
    if (_customMaintenanceTaskTypes.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No custom task types to manage.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final customTypes = _customMaintenanceTaskTypes;
            return AlertDialog(
              title: const Text('Manage Maintenance Task Types'),
              content: SizedBox(
                width: 520,
                child: customTypes.isEmpty
                    ? const Text('No custom task types to manage.')
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: customTypes.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final taskType = customTypes[index];
                          return ListTile(
                            title: Text(taskType),
                            trailing: IconButton(
                              tooltip: 'Delete',
                              onPressed: () async {
                                final shouldDelete =
                                    await _confirmDeleteMaintenanceTaskType(
                                      taskType,
                                    );
                                if (!shouldDelete || !mounted) {
                                  return;
                                }
                                onDeleted?.call(taskType);
                                await _refreshMaintenanceTaskTypes();
                                if (dialogContext.mounted) {
                                  setDialogState(() {});
                                }
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          );
                        },
                      ),
              ),
              actions: _dialogActionsForContext(dialogContext, [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Done'),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmDeleteMaintenanceTaskType(String taskType) async {
    try {
      final usageCount = await MachineDatabase.instance
          .getMaintenanceTaskTypeUsageCount(taskType);
      if (!mounted) {
        return false;
      }

      if (usageCount > 0) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Cannot Delete Task Type'),
              content: Text(
                '"$taskType" is currently used by $usageCount maintenance task(s). Remove it from those records before deleting this task type.',
              ),
              actions: _dialogActionsForContext(dialogContext, [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ]),
            );
          },
        );
        return false;
      }

      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Delete Task Type'),
            content: Text('Delete "$taskType"?'),
            actions: _dialogActionsForContext(dialogContext, [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(_cancelActionLabel(dialogContext)),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(_deleteActionLabel(dialogContext)),
              ),
            ]),
          );
        },
      );

      if (shouldDelete != true) {
        return false;
      }

      await MachineDatabase.instance.deleteMaintenanceTaskType(taskType);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task type "$taskType" deleted.')),
        );
      }
      return true;
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Failed to delete task type.', error);
      }
      return false;
    }
  }

  Future<void> _initializeSubCategories() async {
    try {
      await MachineDatabase.instance.ensureDefaultComponentTypes(
        _subCategories,
      );
      await MachineDatabase.instance.syncComponentTypesFromSubAssemblies();
      await _refreshSubCategories();
    } catch (_) {
      // Keep built-in defaults available even if DB-backed list fails to load.
    }
  }

  Future<void> _refreshSubCategories({String? selectedType}) async {
    final savedTypes = await MachineDatabase.instance.getComponentTypes();
    if (!mounted) {
      return;
    }

    setState(() {
      _subCategoryOptions
        ..clear()
        ..addAll(savedTypes);

      if (selectedType != null && selectedType.trim().isNotEmpty) {
        _selectedSubCategory = selectedType.trim();
      } else if (_selectedSubCategory != null &&
          !_subCategoryOptions.contains(_selectedSubCategory)) {
        _selectedSubCategory = null;
      }
    });
  }

  Future<void> _showAddSubCategoryDialog({
    void Function(String type)? onSaved,
  }) async {
    final controller = TextEditingController();
    try {
      final enteredType = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Add Sub Category'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Sub Category',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
            ),
            actions: _dialogActionsForContext(dialogContext, [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(_cancelActionLabel(dialogContext)),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                },
                child: const Text('Save'),
              ),
            ]),
          );
        },
      );

      final normalized = enteredType?.trim() ?? '';
      if (normalized.isEmpty) {
        return;
      }

      final savedType = await MachineDatabase.instance.addComponentType(
        normalized,
      );
      if (savedType == null || savedType.trim().isEmpty) {
        return;
      }

      final finalType = savedType.trim();
      await _refreshSubCategories(selectedType: finalType);
      onSaved?.call(finalType);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sub category "$finalType" saved.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar('Failed to save sub category.', error);
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showManageSubCategoriesDialog({
    void Function(String deletedName)? onDeleted,
  }) async {
    if (_customSubCategories.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No custom sub categories to manage.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final customSubCategories = _customSubCategories;
            return AlertDialog(
              title: const Text('Manage Sub Categories'),
              content: SizedBox(
                width: 520,
                child: customSubCategories.isEmpty
                    ? const Text('No custom sub categories to manage.')
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: customSubCategories.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final subCategory = customSubCategories[index];
                          return ListTile(
                            title: Text(subCategory),
                            trailing: IconButton(
                              tooltip: 'Delete',
                              onPressed: () async {
                                final shouldDelete =
                                    await _confirmDeleteSubCategory(
                                      subCategory,
                                    );
                                if (!shouldDelete || !mounted) {
                                  return;
                                }
                                onDeleted?.call(subCategory);
                                await _refreshSubCategories();
                                if (dialogContext.mounted) {
                                  setDialogState(() {});
                                }
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          );
                        },
                      ),
              ),
              actions: _dialogActionsForContext(dialogContext, [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Done'),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmDeleteSubCategory(String subCategory) async {
    try {
      final usageCount = await MachineDatabase.instance
          .getSubAssemblyComponentTypeUsageCount(subCategory);
      if (!mounted) {
        return false;
      }

      if (usageCount > 0) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Cannot Delete Sub Category'),
              content: Text(
                '"$subCategory" is currently used by $usageCount sub-assemblies. Remove it from those records before deleting this sub category.',
              ),
              actions: _dialogActionsForContext(dialogContext, [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ]),
            );
          },
        );
        return false;
      }

      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Delete Sub Category'),
            content: Text('Delete "$subCategory"?'),
            actions: _dialogActionsForContext(dialogContext, [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(_cancelActionLabel(dialogContext)),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(_deleteActionLabel(dialogContext)),
              ),
            ]),
          );
        },
      );

      if (shouldDelete != true) {
        return false;
      }

      await MachineDatabase.instance.deleteComponentType(subCategory);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sub category "$subCategory" deleted.')),
        );
      }
      return true;
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Failed to delete sub category.', error);
      }
      return false;
    }
  }

  Future<void> _loadTabOrderPreference() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getStringList(_tabOrderPreferenceKey);
    if (stored == null || stored.isEmpty) {
      return;
    }

    final parsed = <_AppTab>[];
    for (final value in stored) {
      try {
        parsed.add(_AppTab.values.byName(value));
      } catch (_) {
        // Ignore unknown values and fallback to default order if invalid.
      }
    }

    final normalized = _normalizeTabOrder(parsed);
    if (!mounted) {
      return;
    }

    setState(() {
      _tabOrder = normalized;
    });
  }

  List<_AppTab> _normalizeTabOrder(List<_AppTab> input) {
    final unique = input.toSet();
    if (!_defaultTabOrder.every(unique.contains)) {
      return List<_AppTab>.from(_defaultTabOrder);
    }
    // Preserve user order while dropping any duplicates.
    final seen = <_AppTab>{};
    return input.where(seen.add).toList(growable: false);
  }

  Future<void> _persistTabOrder(List<_AppTab> order) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _tabOrderPreferenceKey,
      order.map((tab) => tab.name).toList(growable: false),
    );
  }

  void _showInitialDatabaseSetupPrompt() {
    if (!mounted || _hasShownStartupPrompt) return;
    _hasShownStartupPrompt = true;
    _switchToTabWhenReady(_AppTab.help);
  }

  void _switchToTabWhenReady(_AppTab tab) {
    final tabIndex = _normalizeTabOrder(_tabOrder).indexOf(tab);
    if (tabIndex < 0) return;

    void trySwitch() {
      if (!mounted) return;
      final ctx = _tabSwitcherContext;
      if (ctx == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => trySwitch());
        return;
      }
      final controller = DefaultTabController.maybeOf(ctx);
      if (controller == null || tabIndex >= controller.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) => trySwitch());
        return;
      }
      controller.animateTo(tabIndex);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => trySwitch());
  }

  String _tabTitle(_AppTab tab) {
    switch (tab) {
      case _AppTab.addMachine:
        return 'Add Machine';
      case _AppTab.machinesList:
        return 'Machines List';
      case _AppTab.employees:
        return 'Employees';
      case _AppTab.maintenanceDue:
        return 'Schedule';
      case _AppTab.workOrders:
        return 'Work Orders';
      case _AppTab.calendar:
        return 'Forecast';
      case _AppTab.editMachines:
        return 'Edit Machines';
      case _AppTab.help:
        return 'Help';
      case _AppTab.information:
        return 'Information';
    }
  }

  IconData _tabIcon(_AppTab tab) {
    switch (tab) {
      case _AppTab.addMachine:
        return Icons.add_circle_outline;
      case _AppTab.machinesList:
        return Icons.list_alt;
      case _AppTab.employees:
        return Icons.group_outlined;
      case _AppTab.maintenanceDue:
        return Icons.build_circle_outlined;
      case _AppTab.workOrders:
        return Icons.assignment_outlined;
      case _AppTab.calendar:
        return Icons.calendar_month_outlined;
      case _AppTab.editMachines:
        return Icons.edit_note;
      case _AppTab.help:
        return Icons.help_outline;
      case _AppTab.information:
        return Icons.info_outline;
    }
  }

  Widget _tabViewFor(_AppTab tab) {
    switch (tab) {
      case _AppTab.addMachine:
        return _buildAddMachineTab();
      case _AppTab.machinesList:
        return _buildMachinesListTab();
      case _AppTab.employees:
        return _buildEmployeesTab();
      case _AppTab.maintenanceDue:
        return _buildMaintenanceDueTab();
      case _AppTab.workOrders:
        return _buildWorkOrdersTab();
      case _AppTab.calendar:
        return _buildCalendarTab();
      case _AppTab.editMachines:
        return _buildEditMachinesTab();
      case _AppTab.help:
        return _buildHelpTab();
      case _AppTab.information:
        return _buildInformationTab();
    }
  }

  Future<void> _showTabOrderDialog() async {
    final workingOrder = List<_AppTab>.from(_tabOrder);
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogLayout = _layoutForContext(dialogContext);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding: _dialogInsetPaddingForLayout(dialogLayout),
              title: const Text('Customize Tab Order'),
              content: SizedBox(
                width: _dialogMaxWidthForLayout(dialogLayout),
                height: 360,
                child: ReorderableListView.builder(
                  itemCount: workingOrder.length,
                  onReorderItem: (oldIndex, newIndex) {
                    setDialogState(() {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final item = workingOrder.removeAt(oldIndex);
                      workingOrder.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final tab = workingOrder[index];
                    return ListTile(
                      key: ValueKey(tab),
                      leading: Icon(_tabIcon(tab)),
                      title: Text(_tabTitle(tab)),
                      trailing: const Icon(Icons.drag_handle),
                    );
                  },
                ),
              ),
              actions: _dialogActionsForContext(dialogContext, [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(_cancelActionLabel(dialogContext)),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Save'),
                ),
              ]),
            );
          },
        );
      },
    );

    if (shouldSave != true) {
      return;
    }

    final normalized = _normalizeTabOrder(workingOrder);
    if (!mounted) {
      return;
    }

    setState(() {
      _tabOrder = normalized;
    });
    await _persistTabOrder(normalized);
  }

  @override
  void dispose() {
    _machineDraft.dispose();
    _taskSearchController.dispose();
    _employeeNameController.dispose();
    _employeeSearchController.dispose();
    _disposeSubAssemblyDrafts(_subAssemblyDrafts);
    _disposeMaintenanceDueDetailDrafts();
    super.dispose();
  }

  void _disposeSubAssemblyDrafts(List<SubAssemblyDraft> drafts) {
    for (final draft in drafts) {
      draft.dispose();
    }
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatHistoryTimestamp(String rawUtcIso) {
    final parsed = DateTime.tryParse(rawUtcIso);
    if (parsed == null) {
      return rawUtcIso;
    }

    final local = parsed.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }

  String _randomLastCheckDate(Random rng, {int maxDaysBack = 730}) {
    final daysBack = rng.nextInt(maxDaysBack + 1);
    final date = DateTime.now().subtract(Duration(days: daysBack));
    return _formatDate(date);
  }

  List<String> _buildSampleAdditionalRequiredLicenses(Random rng) {
    final choices = List<String>.from(_customLicenseTypes);
    if (choices.isEmpty) {
      return const [];
    }

    choices.shuffle(rng);
    final limit = choices.length < 3 ? choices.length : 3;
    final count = rng.nextInt(limit + 1);
    return choices.take(count).toList(growable: false);
  }

  List<SubAssembly> _buildSampleSubAssemblies({
    required String machineSerial,
    required String manufacturer,
    required String location,
    required int startIndex,
    required int count,
    Random? rng,
  }) {
    const subCategories = [
      'Hydraulic Pump',
      'Cooling Fan',
      'Control Panel',
      'Drive Motor',
      'Fuel Module',
      'Gearbox',
      'Valve Block',
      'Sensor Array',
      'Compressor',
      'Power Unit',
    ];

    final random = rng ?? Random(20260318);
    final subCategoryChoices = _availableSubCategories;
    final superCategoryChoices = _availableSuperCategories;

    return List<SubAssembly>.generate(count, (offset) {
      final sequence = startIndex + offset + 1;
      final componentName = subCategories[random.nextInt(subCategories.length)];
      final serialBase = machineSerial.replaceAll('SIM-', 'SUB');

      return SubAssembly(
        name: '$componentName ${sequence.toString().padLeft(2, '0')}',
        modelName: componentName,
        modelNumber: 'SA-${machineSerial.substring(4)}-$sequence',
        operatingHours: '${100 + random.nextInt(1800)}',
        idleHours: '${10 + random.nextInt(350)}',
        serialNumber: '$serialBase-${sequence.toString().padLeft(2, '0')}',
        location: location,
        manufacturer: manufacturer,
        maintenanceDocumentName: 'Sub-Assembly Manual $machineSerial-$sequence',
        maintenanceDocumentNumber: 'SUBDOC-$machineSerial-$sequence',
        maintenancePublisher: 'Internal Engineering',
        superCategory:
            superCategoryChoices[random.nextInt(superCategoryChoices.length)],
        subCategory:
            subCategoryChoices[random.nextInt(subCategoryChoices.length)],
        maintenanceTasks: List<MaintenanceTask>.generate(
          _availableMaintenanceTaskTypes.length,
          (taskIndex) => MaintenanceTask(
            taskType: _availableMaintenanceTaskTypes[taskIndex],
            timeCategory:
                _maintenanceTimeCategories[random.nextInt(
                  _maintenanceTimeCategories.length,
                )],
            timeValue: random.nextInt(23) + 1,
          ),
        ),
      );
    });
  }

  Future<void> _loadMachines({bool seedSampleData = true}) async {
    try {
      var machines = await _withDatabaseLoadTimeout(
        MachineDatabase.instance.getMachines(),
      );

      if (!seedSampleData) {
        if (!mounted) {
          return;
        }

        setState(() {
          _machines
            ..clear()
            ..addAll(machines);
          _pruneMaintenanceDueState();
          _isLoading = false;
          _hasAttemptedAutoReload = false;
        });
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _machines
          ..clear()
          ..addAll(machines);
        _pruneMaintenanceDueState();
        _isLoading = false;
        _hasAttemptedAutoReload = false;
      });

      if (machines.isEmpty) {
        _showInitialDatabaseSetupPrompt();
        return;
      }

      unawaited(_runSampleDataBackfills(machines));
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showErrorSnackBar('Failed to load saved machines.', error);
    }
  }

  Future<void> _reloadMachinesFromDatabase({bool showFeedback = false}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final machines = await _withDatabaseLoadTimeout(
        MachineDatabase.instance.getMachines(),
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _machines
          ..clear()
          ..addAll(machines);
        _pruneMaintenanceDueState();
        _isLoading = false;
      });

      if (showFeedback) {
        final subAssemblyCount = machines.expand((m) => m.subAssemblies).length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reloaded ${machines.length} machines and $subAssemblyCount sub-assemblies.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to reload database data.', error);
    }
  }

  Future<T> _withDatabaseLoadTimeout<T>(Future<T> operation) {
    return operation.timeout(
      const Duration(seconds: 45),
      onTimeout: () => throw TimeoutException(
        'Timed out while waiting for the local database.',
      ),
    );
  }

  void _ensureMachinesVisible() {
    if (_isLoading || _machines.isNotEmpty || _hasAttemptedAutoReload) {
      return;
    }

    _hasAttemptedAutoReload = true;
    Future<void>(() async {
      await _reloadMachinesFromDatabase();
    });
  }

  Future<void> _runSampleDataBackfills(List<Machine> machines) async {
    try {
      final dateRng = Random(20260318);
      final missingLastCheckDate = machines
          .where((machine) => machine.lastCheckDate.trim().isEmpty)
          .toList(growable: false);
      if (missingLastCheckDate.isNotEmpty) {
        for (final machine in missingLastCheckDate) {
          final machineId = machine.id;
          if (machineId == null) {
            continue;
          }
          await MachineDatabase.instance.updateMachineLastCheckDate(
            machineId,
            _randomLastCheckDate(dateRng),
          );
        }
        machines = await MachineDatabase.instance.getMachines();
      }

      final sampleMachines = machines
          .where((machine) => machine.serialNumber.startsWith('SIM-'))
          .toList(growable: false);
      final missingSampleSubAssemblies = sampleMachines.where(
        (machine) => machine.subAssemblies.isEmpty,
      );

      if (missingSampleSubAssemblies.isNotEmpty) {
        for (final machine in missingSampleSubAssemblies) {
          final machineId = machine.id;
          if (machineId == null) {
            continue;
          }

          const missingCount = 8;
          final additions = _buildSampleSubAssemblies(
            machineSerial: machine.serialNumber,
            manufacturer: machine.manufacturer,
            location: machine.location,
            startIndex: machine.subAssemblies.length,
            count: missingCount,
          );

          final updatedMachine = machine.copyWith(
            subAssemblies: [...machine.subAssemblies, ...additions],
          );

          await MachineDatabase.instance.updateMachine(updatedMachine);
        }

        machines = await MachineDatabase.instance.getMachines();
      }

      final sampleMissingTasks = sampleMachines.where(
        (machine) => machine.subAssemblies.any(
          (subAssembly) => subAssembly.maintenanceTasks.isEmpty,
        ),
      );

      if (sampleMissingTasks.isNotEmpty) {
        for (final machine in sampleMissingTasks) {
          final updatedSubAssemblies = machine.subAssemblies
              .map((subAssembly) {
                if (subAssembly.maintenanceTasks.isNotEmpty) {
                  return subAssembly;
                }

                final generatedTasks = List<MaintenanceTask>.generate(
                  _availableMaintenanceTaskTypes.length,
                  (taskIndex) => MaintenanceTask(
                    taskType: _availableMaintenanceTaskTypes[taskIndex],
                    timeCategory:
                        _maintenanceTimeCategories[taskIndex %
                            _maintenanceTimeCategories.length],
                    timeValue: (taskIndex * 7 + 3) % 23 + 1,
                  ),
                );

                return subAssembly.copyWith(maintenanceTasks: generatedTasks);
              })
              .toList(growable: false);

          await MachineDatabase.instance.updateMachine(
            machine.copyWith(subAssemblies: updatedSubAssemblies),
          );
        }

        machines = await MachineDatabase.instance.getMachines();
      }

      // Backfill subCategory for sample sub-assemblies that have none.
      final sampleMissingSubCategory = machines
          .where((m) => m.serialNumber.startsWith('SIM-'))
          .where((m) => m.subAssemblies.any((sa) => sa.subCategory.isEmpty))
          .toList(growable: false);

      if (sampleMissingSubCategory.isNotEmpty) {
        final subCategoryChoices = _availableSubCategories;
        for (final machine in sampleMissingSubCategory) {
          final updatedSubAssemblies = machine.subAssemblies
              .asMap()
              .entries
              .map((entry) {
                final sa = entry.value;
                if (sa.subCategory.isNotEmpty) return sa;
                return sa.copyWith(
                  subCategory:
                      subCategoryChoices[entry.key % subCategoryChoices.length],
                );
              })
              .toList(growable: false);
          await MachineDatabase.instance.updateMachine(
            machine.copyWith(subAssemblies: updatedSubAssemblies),
          );
        }
        machines = await MachineDatabase.instance.getMachines();
      }

      final customLicenseChoices = _customLicenseTypes;
      final sampleMissingAdditionalLicenses = customLicenseChoices.isEmpty
          ? const <Machine>[]
          : machines
                .where((m) => m.serialNumber.startsWith('SIM-'))
                .where((m) => m.additionalRequiredLicenses.isEmpty)
                .toList(growable: false);

      if (sampleMissingAdditionalLicenses.isNotEmpty) {
        final licenseRng = Random(20260318 ^ 0x51A7);
        for (final machine in sampleMissingAdditionalLicenses) {
          final generatedLicenses = _buildSampleAdditionalRequiredLicenses(
            licenseRng,
          );
          if (generatedLicenses.isEmpty) {
            continue;
          }

          await MachineDatabase.instance.updateMachine(
            machine.copyWith(additionalRequiredLicenses: generatedLicenses),
          );
        }
        machines = await MachineDatabase.instance.getMachines();
      }

      // Backfill timeValue for sample tasks that still have the default 0.
      final rng = Random(42);
      final sampleMissingTimeValue = machines
          .where((m) => m.serialNumber.startsWith('SIM-'))
          .where(
            (m) => m.subAssemblies.any(
              (sa) => sa.maintenanceTasks.any((t) => t.timeValue == 0),
            ),
          )
          .toList(growable: false);

      if (sampleMissingTimeValue.isNotEmpty) {
        for (final machine in sampleMissingTimeValue) {
          final updatedSubAssemblies = machine.subAssemblies
              .map((sa) {
                final hasMissing = sa.maintenanceTasks.any(
                  (t) => t.timeValue == 0,
                );
                if (!hasMissing) return sa;
                final tasks = sa.maintenanceTasks
                    .map(
                      (t) => t.timeValue == 0
                          ? t.copyWith(timeValue: rng.nextInt(23) + 1)
                          : t,
                    )
                    .toList(growable: false);
                return sa.copyWith(maintenanceTasks: tasks);
              })
              .toList(growable: false);
          await MachineDatabase.instance.updateMachine(
            machine.copyWith(subAssemblies: updatedSubAssemblies),
          );
        }
        machines = await MachineDatabase.instance.getMachines();
      }

      // Seed history for sample machines on first launch.
      final historySampleMachines = machines
          .where((m) => m.serialNumber.startsWith('SIM-'))
          .toList(growable: false);
      if (historySampleMachines.isNotEmpty) {
        final hasHistory = await MachineDatabase.instance
            .hasMachineDetailHistory();
        if (!hasHistory) {
          final historyRng = Random(20260318 ^ 0xABCD1234);
          await MachineDatabase.instance.insertSampleHistory(
            historySampleMachines,
            historyRng,
          );
          machines = await MachineDatabase.instance.getMachines();
        }
      }

      if (!mounted) {
        return;
      }

      // Avoid stale async backfill runs from clobbering newly visible data.
      if (machines.isEmpty && _machines.isNotEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _machines
          ..clear()
          ..addAll(machines);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showErrorSnackBar('Failed to load saved machines.', error);
    }
  }

  List<SubAssembly> _currentSubAssembliesFromDrafts(
    List<SubAssemblyDraft> drafts,
  ) {
    return drafts.map((draft) => draft.toSubAssembly()).toList(growable: false);
  }

  String _normalizeDocumentNumber(String value) {
    return value.trim().toUpperCase();
  }

  bool get _hasTaskFilter {
    return _selectedTaskType != null ||
        _selectedTaskTimeCategory != null ||
        _selectedSuperCategory != null ||
        _selectedSubCategory != null ||
        _taskSearchQuery.trim().isNotEmpty;
  }

  bool _containsIgnoreCase(String source, String query) {
    return source.toLowerCase().contains(query.toLowerCase());
  }

  List<Machine> _getFilteredMachines() {
    if (!_hasTaskFilter) {
      return _machines;
    }

    final query = _taskSearchQuery.trim().toLowerCase();

    return _machines
        .map((machine) {
          final filteredSubAssemblies = machine.subAssemblies
              .map((subAssembly) {
                final matchesSuperCategory =
                    _selectedSuperCategory == null ||
                    subAssembly.superCategory == _selectedSuperCategory;
                if (!matchesSuperCategory) {
                  return null;
                }

                final filteredTasks = subAssembly.maintenanceTasks
                    .where((task) {
                      final matchesTaskType =
                          _selectedTaskType == null ||
                          task.taskType == _selectedTaskType;
                      final matchesTimeCategory =
                          _selectedTaskTimeCategory == null ||
                          task.timeCategory == _selectedTaskTimeCategory;

                      final matchesSearch =
                          query.isEmpty ||
                          _containsIgnoreCase(machine.name, query) ||
                          _containsIgnoreCase(machine.serialNumber, query) ||
                          _containsIgnoreCase(subAssembly.name, query) ||
                          _containsIgnoreCase(
                            subAssembly.serialNumber,
                            query,
                          ) ||
                          _containsIgnoreCase(task.taskType, query) ||
                          _containsIgnoreCase(task.timeCategory, query);

                      return matchesTaskType &&
                          matchesTimeCategory &&
                          matchesSearch;
                    })
                    .toList(growable: false);

                if (filteredTasks.isEmpty) {
                  return null;
                }

                final matchesSubCategory =
                    _selectedSubCategory == null ||
                    subAssembly.subCategory == _selectedSubCategory;

                if (!matchesSubCategory) {
                  return null;
                }

                return subAssembly.copyWith(maintenanceTasks: filteredTasks);
              })
              .whereType<SubAssembly>()
              .toList(growable: false);

          if (filteredSubAssemblies.isEmpty) {
            return null;
          }

          return machine.copyWith(subAssemblies: filteredSubAssemblies);
        })
        .whereType<Machine>()
        .toList(growable: false);
  }

  String? _checkInternalDocumentNumberDuplicates(Machine machine) {
    final allNumbers = <String>[];

    final machineDocumentNumber = _normalizeDocumentNumber(
      machine.maintenanceDocumentNumber,
    );
    if (machineDocumentNumber.isNotEmpty) {
      allNumbers.add(machineDocumentNumber);
    }

    for (final subAssembly in machine.subAssemblies) {
      final subDocumentNumber = _normalizeDocumentNumber(
        subAssembly.maintenanceDocumentNumber,
      );
      if (subDocumentNumber.isNotEmpty) {
        allNumbers.add(subDocumentNumber);
      }
    }

    final unique = allNumbers.toSet();
    if (unique.length != allNumbers.length) {
      return 'Maintenance document numbers must be unique for the machine and its sub-assemblies.';
    }

    return null;
  }

  Future<String?> _checkPersistedDocumentNumberConflicts(
    Machine machine, {
    int? editingMachineId,
  }) async {
    final machineNumber = machine.maintenanceDocumentNumber.trim();

    final machineConflict = await MachineDatabase.instance
        .hasMachineDocumentNumber(
          machineNumber,
          excludeMachineId: editingMachineId,
        );
    if (machineConflict) {
      return 'Maintenance document number already used by another machine.';
    }

    final machineVsSubConflict = await MachineDatabase.instance
        .hasSubAssemblyDocumentNumber(
          machineNumber,
          excludeMachineId: editingMachineId,
        );
    if (machineVsSubConflict) {
      return 'Maintenance document number already used by another sub-assembly.';
    }

    for (final subAssembly in machine.subAssemblies) {
      final subNumber = subAssembly.maintenanceDocumentNumber.trim();

      final subVsMachineConflict = await MachineDatabase.instance
          .hasMachineDocumentNumber(
            subNumber,
            excludeMachineId: editingMachineId,
          );
      if (subVsMachineConflict) {
        return 'A sub-assembly maintenance document number is already used by another machine.';
      }

      final subVsSubConflict = await MachineDatabase.instance
          .hasSubAssemblyDocumentNumber(
            subNumber,
            excludeMachineId: editingMachineId,
          );
      if (subVsSubConflict) {
        return 'A sub-assembly maintenance document number is already used by another sub-assembly.';
      }
    }

    return null;
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _numericRequiredValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) {
      return requiredError;
    }

    if (!RegExp(r'^\d+$').hasMatch(value!.trim())) {
      return 'Numbers only';
    }

    return null;
  }

  String? _dateRequiredValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) {
      return requiredError;
    }

    final text = value!.trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
      return 'Use YYYY-MM-DD';
    }

    final parts = text.split('-');
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return 'Use YYYY-MM-DD';
    }

    final parsed = DateTime.tryParse(text);
    if (parsed == null ||
        parsed.year != year ||
        parsed.month != month ||
        parsed.day != day) {
      return 'Enter a valid date';
    }

    return null;
  }

  void _showErrorSnackBar(String message, Object error) {
    final errorText = error.toString();
    final content = errorText.isEmpty ? message : '$message $errorText';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(content)));
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage(context);
  }
}
