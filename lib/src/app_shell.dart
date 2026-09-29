part of 'package:maintenanceschedular/main.dart';

enum MachineAction { edit, delete }

enum DatabaseAction {
  exportBackup,
  importBackup,
  exportEmployeesCsv,
  exportMachinesCsv,
  exportEmployeeTemplateCsv,
  exportMachineTemplateCsv,
  importEmployeesCsv,
  importMachinesCsv,
  csvImportHelp,
  deleteDatabase,
}

enum _ResponsiveLayout { phone, tablet, desktop }

enum _EmployeeSortMode { nameAsc, nameDesc, skillCountDesc }

enum _AppTab {
  addMachine,
  machinesList,
  employees,
  maintenanceDue,
  workOrders,
  calendar,
  editMachines,
  help,
  information,
}

/// A sub-assembly projected to require a work order on a known date.
class _WorkOrderItem {
  const _WorkOrderItem({
    required this.machine,
    required this.subAssembly,
    required this.projectedNextDate,
    required this.daysUntilDue,
  });

  final Machine machine;
  final SubAssembly subAssembly;
  final DateTime projectedNextDate;
  final int daysUntilDue;
}

/// A maintenance task paired with its optional projected due date.
class _EstimatedTaskItem {
  const _EstimatedTaskItem({
    required this.machine,
    required this.subAssembly,
    required this.task,
    this.projectedDate,
    this.daysUntilDue,
  });

  final Machine machine;
  final SubAssembly subAssembly;
  final MaintenanceTask task;
  final DateTime? projectedDate;
  final int? daysUntilDue;
}

/// Root application widget that owns and persists the selected theme mode.
class MainApp extends StatefulWidget {
  const MainApp({super.key, this.home});

  final Widget? home;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  static const String _themePreferenceKey = 'themeMode';
  static const String _legacyThemePreferenceKey = 'isDarkMode';
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  /// Restores the current theme, migrating the former boolean preference when
  /// no modern theme-mode value exists.
  Future<void> _loadThemePreference() async {
    ThemeMode resolvedThemeMode;
    try {
      final preferences = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 8),
      );
      final savedThemeMode = preferences.getString(_themePreferenceKey);

      switch (savedThemeMode) {
        case 'light':
          resolvedThemeMode = ThemeMode.light;
        case 'dark':
          resolvedThemeMode = ThemeMode.dark;
        case 'system':
          resolvedThemeMode = ThemeMode.system;
        default:
          final legacyIsDarkMode = preferences.getBool(
            _legacyThemePreferenceKey,
          );
          resolvedThemeMode = legacyIsDarkMode == null
              ? ThemeMode.system
              : (legacyIsDarkMode ? ThemeMode.dark : ThemeMode.light);
      }
    } catch (_) {
      // Prevent permanent splash-spinner if preferences are unavailable.
      resolvedThemeMode = ThemeMode.system;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _themeMode = resolvedThemeMode;
    });
  }

  /// Stores the named theme mode and removes the obsolete boolean preference.
  Future<void> _persistThemePreference(ThemeMode themeMode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themePreferenceKey, themeMode.name);
    await preferences.remove(_legacyThemePreferenceKey);
  }

  void _setThemeMode(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });

    _persistThemePreference(themeMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Scheduler',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home:
          widget.home ??
          SplashScreen(
            nextScreen: MachineEntryPage(
              themeMode: _themeMode,
              onThemeModeChanged: _setThemeMode,
            ),
          ),
    );
  }
}
