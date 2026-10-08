// ignore_for_file: invalid_use_of_protected_member, unused_element

part of 'package:maintenanceschedular/main.dart';

extension _MachineEntryPageReportsExtension on _MachineEntryPageState {
  Widget _buildMaintenanceDueTab() {
    _ensureMachinesVisible();
    final visibleMachines = _getFilteredMachines();

    return ListView(
      children: [
        _buildTaskFilterCard(),
        const SizedBox(height: 16),
        _buildMachineList(
          visibleMachines,
          showActions: false,
          editableDetails: true,
          emptyMessage: _hasTaskFilter
              ? 'No machines match the selected task filter.'
              : 'No machines added yet.',
        ),
      ],
    );
  }

  Widget _buildEditMachinesTab() {
    _ensureMachinesVisible();
    return ListView(
      children: [
        _buildMachinesPdfActionCard(
          title: 'Edit Machines',
          description:
              'Export the current machines list to PDF before making edits.',
        ),
        const SizedBox(height: 12),
        _buildMachineList(
          _machines,
          showActions: true,
          editableDetails: false,
          emptyMessage: 'No machines added yet.',
        ),
      ],
    );
  }

  Widget _buildHelpTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.rocket_launch_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Getting Started',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start by adding machines, their sub-assemblies, and '
                  'recurring tasks. Set each machine\'s last-check date to '
                  'anchor calendar forecasts, then add employees and their '
                  'licenses for work-order assignment. Native app records are '
                  'stored locally on this device; use the storage icon to '
                  'export a transferable JSON registry backup. Web database '
                  'functions are unavailable and browser-session data is '
                  'temporary.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Machine',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the machine details, last-check date, and required '
                  'licenses, then add sub-assemblies and their recurring '
                  'maintenance tasks. Choose an interval for each task; '
                  'hour-based tasks are tracked but are not given calendar '
                  'forecast dates. Select Add Machine to save the record.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.list_alt,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Machines List',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Browse machines and expand a record to review its details, '
                  'sub-assemblies, maintenance tasks, required licenses, and '
                  'saved operating-detail history.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Employees',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add, edit, search, filter, sort, or remove employees. '
                  'Assign skills and licenses, and manage the available skill '
                  'and license types. Skills are for reference; work-order '
                  'assignment checks that an employee holds every license '
                  'required by the machine.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.build_circle_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Schedule',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Filter machines by component category, task type, interval, '
                  'or search text. Expand a machine to review maintenance due '
                  'and update operating hours, idle hours, or the last-check '
                  'date. Changes to machine and sub-assembly operating details '
                  'are saved in timestamped history; work-order status is '
                  'shown when available.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Work Orders',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Review sub-assemblies with date-based maintenance due in '
                  'the next five days. Tasks are assigned to employees who '
                  'hold every license required by the machine, or marked '
                  'Contractor Needed. Save Work Complete, Partial, or Bypass '
                  'with notes, and print a seven-day work-order PDF.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Forecast',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Review all maintenance tasks in projected due-date order '
                  'and print or share the schedule PDF. Forecasts repeat from '
                  'the machine last-check date using approximate calendar '
                  'intervals (30 days per month, 91 per quarter, 182 per '
                  'half-year, 365 per year, and 730 per biannual interval). '
                  'Hour-based tasks remain listed without a forecast date.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_note,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Edit Machines',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Export the machine list to PDF, or edit and delete machines. '
                  'Editing a machine also supports its required licenses, '
                  'sub-assemblies, and maintenance tasks.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.storage_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Database Actions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use the storage icon to export or replace registry data '
                  'with JSON, import or export employee and machine CSV files, '
                  'create CSV templates, open CSV import help, or delete the '
                  'database. JSON replacement clears saved detail history, '
                  'work-order statuses, and task assignments.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.swap_vert,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tab Order',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use Customize tab order in the toolbar, drag the tabs into '
                  'your preferred order, and save. The order is remembered on '
                  'this device.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.brightness_6_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Appearance',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose Light, Dark, or System from the toolbar. The theme '
                  'choice is remembered on this device.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use the Information tab to send a support question. With '
                  'an internet connection, the form sends your name, email, '
                  'question, package name, app version/build, platform, '
                  'orientation, layout, and submission time to the support '
                  'service. Do not include sensitive information in a request.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInformationTab() {
    return createContactPage(
      serverUrl: 'https://stefanronnkvist.com',
      showAppBar: false,
    );
  }

  Widget _buildPage(BuildContext context) {
    final baseTheme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final layout = _layoutForWidth(screenWidth);
    final themedData = _themeForLayout(baseTheme, layout);
    final showThemeLabels = layout != _ResponsiveLayout.phone;
    final contentMaxWidth = _maxContentWidthForLayout(layout);
    final contentPadding = _contentPaddingForLayout(layout);
    final tabOrder = _normalizeTabOrder(_tabOrder);
    final tabs = tabOrder
        .map((tab) => Tab(text: _tabTitle(tab), icon: Icon(_tabIcon(tab))))
        .toList(growable: false);
    final tabViews = tabOrder.map(_tabViewFor).toList(growable: false);
    final initialTabIndex = tabOrder.indexOf(_AppTab.maintenanceDue);
    final themeSegments = showThemeLabels
        ? const <ButtonSegment<ThemeMode>>[
            ButtonSegment<ThemeMode>(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode_outlined),
              label: Text('Light'),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode_outlined),
              label: Text('Dark'),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto_outlined),
              label: Text('System'),
            ),
          ]
        : const <ButtonSegment<ThemeMode>>[
            ButtonSegment<ThemeMode>(
              value: ThemeMode.light,
              icon: Tooltip(
                message: 'Light',
                child: Icon(Icons.light_mode_outlined),
              ),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.dark,
              icon: Tooltip(
                message: 'Dark',
                child: Icon(Icons.dark_mode_outlined),
              ),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.system,
              icon: Tooltip(
                message: 'System',
                child: Icon(Icons.brightness_auto_outlined),
              ),
            ),
          ];

    return DefaultTabController(
      length: tabs.length,
      initialIndex: initialTabIndex < 0 ? 0 : initialTabIndex,
      child: Builder(
        builder: (tabCtx) {
          _tabSwitcherContext = tabCtx;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Schedular'),
              actions: [
                IconButton(
                  tooltip: 'Customize tab order',
                  onPressed: _showTabOrderDialog,
                  icon: const Icon(Icons.swap_horiz_outlined),
                ),
                PopupMenuButton<DatabaseAction>(
                  tooltip: 'Database actions',
                  onSelected: _handleDatabaseAction,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: DatabaseAction.exportBackup,
                      child: ListTile(
                        leading: const Icon(Icons.upload_file_outlined),
                        title: Text(_exportBackupActionLabel),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: DatabaseAction.importBackup,
                      child: ListTile(
                        leading: Icon(Icons.download_outlined),
                        title: Text('Import Database'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: DatabaseAction.exportEmployeesCsv,
                      child: ListTile(
                        leading: Icon(Icons.badge_outlined),
                        title: Text('Export Employees CSV'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: DatabaseAction.exportMachinesCsv,
                      child: ListTile(
                        leading: Icon(Icons.precision_manufacturing_outlined),
                        title: Text('Export Machines CSV'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: DatabaseAction.exportEmployeeTemplateCsv,
                      child: ListTile(
                        leading: Icon(Icons.description_outlined),
                        title: Text('Create Employee CSV Template'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: DatabaseAction.exportMachineTemplateCsv,
                      child: ListTile(
                        leading: Icon(Icons.topic_outlined),
                        title: Text('Create Machine CSV Template'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: DatabaseAction.importEmployeesCsv,
                      child: ListTile(
                        leading: Icon(Icons.person_add_alt_1_outlined),
                        title: Text('Import Employees CSV'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: DatabaseAction.importMachinesCsv,
                      child: ListTile(
                        leading: Icon(Icons.playlist_add_outlined),
                        title: Text('Import Machines CSV'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: DatabaseAction.csvImportHelp,
                      child: ListTile(
                        leading: Icon(Icons.help_outline),
                        title: Text('CSV Import Help'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: DatabaseAction.deleteDatabase,
                      child: ListTile(
                        leading: Icon(Icons.delete_forever_outlined),
                        title: Text('Delete Database'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.storage_outlined),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    segments: themeSegments,
                    selected: {widget.themeMode},
                    onSelectionChanged: (selection) {
                      if (selection.isEmpty) {
                        return;
                      }
                      widget.onThemeModeChanged(selection.first);
                    },
                  ),
                ),
              ],
              bottom: TabBar(
                isScrollable: layout == _ResponsiveLayout.phone,
                tabs: tabs,
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  if (_showWebDatabaseNotice)
                    Material(
                      color: Theme.of(context).colorScheme.error,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'PWA notice: database functions are not available on web builds. Data is temporary for this browser session only.',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onError,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Dismiss PWA notice',
                              onPressed: () {
                                setState(() {
                                  _showWebDatabaseNotice = false;
                                });
                              },
                              icon: Icon(
                                Icons.close,
                                color: Theme.of(context).colorScheme.onError,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: contentPadding,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: constraints.maxWidth < contentMaxWidth
                                  ? constraints.maxWidth
                                  : contentMaxWidth,
                              height: constraints.maxHeight,
                              child: Theme(
                                data: themedData,
                                child: _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : TabBarView(children: tabViews),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
