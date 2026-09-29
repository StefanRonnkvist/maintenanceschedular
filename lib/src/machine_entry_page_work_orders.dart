// ignore_for_file: invalid_use_of_protected_member, unused_element

part of 'package:maintenanceschedular/main.dart';

extension _MachineEntryPageWorkOrdersExtension on _MachineEntryPageState {
  static const String _unassignedSelectionValue =
      '__UNASSIGNED__|Contractor Needed';

  /// Creates a stable draft-map key for a task within one sub-assembly.
  ///
  /// [taskIndex] distinguishes unsaved tasks, whose database ID is represented
  /// by `-1` until persistence assigns an ID.
  String _workOrderTaskAssignmentKey(
    int subAssemblyId,
    MaintenanceTask task,
    int taskIndex,
  ) {
    final taskId = task.id ?? -1;
    return '$subAssemblyId:$taskId:$taskIndex';
  }

  /// Encodes identity and display text in the value stored by dropdown fields.
  String _employeeSelectionValue(Employee employee) {
    final idPart = employee.id?.toString() ?? 'no-id';
    return '$idPart|${employee.name}';
  }

  String _employeeNameFromSelectionValue(String selectionValue) {
    final separator = selectionValue.indexOf('|');
    if (separator < 0 || separator + 1 >= selectionValue.length) {
      return selectionValue.trim();
    }
    return selectionValue.substring(separator + 1).trim();
  }

  String _taskLabel(MaintenanceTask task) {
    return '${task.taskType} (${task.timeCategory} ${task.timeValue})';
  }

  String _superCategoryForSubAssembly(SubAssembly subAssembly) {
    final superCategory = subAssembly.superCategory.trim();
    if (superCategory.isNotEmpty) {
      return superCategory;
    }
    return 'Not set';
  }

  /// Returns whether [employee] holds every license required by [machine].
  ///
  /// Comparison is case-insensitive and ignores surrounding whitespace.
  bool _employeeIsQualifiedForMachineLicenses(
    Employee employee,
    Machine machine,
  ) {
    final requiredLicenses = _machineLicenseTradeLabels(machine)
        .map((license) => license.trim().toUpperCase())
        .where((license) => license.isNotEmpty)
        .toSet();

    if (requiredLicenses.isEmpty) {
      return true;
    }

    final employeeLicenses = employee.licenses
        .map((license) => license.trim().toUpperCase())
        .where((license) => license.isNotEmpty)
        .toSet();

    return requiredLicenses.every(employeeLicenses.contains);
  }

  /// Returns license-qualified employees sorted by name for assignment UI.
  ///
  /// Task and sub-assembly parameters keep this boundary ready for finer-grain
  /// qualification rules even though current rules are machine-wide.
  List<Employee> _qualifiedEmployeesForTask({
    required Machine machine,
    required SubAssembly subAssembly,
    required MaintenanceTask task,
  }) {
    final filtered = _employees
        .where(
          (employee) =>
              _employeeIsQualifiedForMachineLicenses(employee, machine),
        )
        .toList(growable: false);
    filtered.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return filtered;
  }

  /// Resolves the displayed assignee from draft state, persisted state, or the
  /// first qualified employee, and optionally synchronizes the draft map.
  String _resolvedAssigneeNameForTask({
    required int subAssemblyId,
    required Machine machine,
    required SubAssembly subAssembly,
    required MaintenanceTask task,
    required int taskIndex,
    required Map<int, String> persistedAssignments,
    bool updateDraft = true,
  }) {
    final qualified = _qualifiedEmployeesForTask(
      machine: machine,
      subAssembly: subAssembly,
      task: task,
    );
    if (qualified.isEmpty) {
      return 'Contractor Needed';
    }

    if (qualified.length == 1) {
      return qualified.first.name;
    }

    final assignmentKey = _workOrderTaskAssignmentKey(
      subAssemblyId,
      task,
      taskIndex,
    );
    final candidateValues = <String>{
      _unassignedSelectionValue,
      ...qualified.map(_employeeSelectionValue),
    };
    final taskId = task.id;
    final draftValue = _workOrderTaskAssigneeDrafts[assignmentKey];
    final persistedValue = taskId == null ? null : persistedAssignments[taskId];

    String? selectedValue;
    if (draftValue != null && candidateValues.contains(draftValue)) {
      selectedValue = draftValue;
    } else if (persistedValue != null &&
        candidateValues.contains(persistedValue)) {
      selectedValue = persistedValue;
    } else if (persistedValue != null &&
        persistedValue == _unassignedSelectionValue) {
      selectedValue = persistedValue;
    } else {
      selectedValue = _employeeSelectionValue(qualified.first);
    }

    if (updateDraft) {
      _workOrderTaskAssigneeDrafts[assignmentKey] = selectedValue;
    }

    return _employeeNameFromSelectionValue(selectedValue);
  }

  Widget _buildTaskAssignmentSection({
    required int subAssemblyId,
    required Machine machine,
    required SubAssembly subAssembly,
    required Map<int, String> persistedAssignments,
  }) {
    final tasks = List<MaintenanceTask>.from(subAssembly.maintenanceTasks)
      ..sort((a, b) {
        final taskCmp = a.taskType.toLowerCase().compareTo(
          b.taskType.toLowerCase(),
        );
        if (taskCmp != 0) {
          return taskCmp;
        }
        return a.timeCategory.toLowerCase().compareTo(
          b.timeCategory.toLowerCase(),
        );
      });

    if (tasks.isEmpty) {
      return const Text('No maintenance tasks available for assignment.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Task Assignment', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...List<Widget>.generate(tasks.length, (taskIndex) {
          final task = tasks[taskIndex];
          final assignmentKey = _workOrderTaskAssignmentKey(
            subAssemblyId,
            task,
            taskIndex,
          );
          final qualified = _qualifiedEmployeesForTask(
            machine: machine,
            subAssembly: subAssembly,
            task: task,
          );
          final taskLabel = _taskLabel(task);

          if (qualified.isEmpty) {
            _workOrderTaskAssigneeDrafts.remove(assignmentKey);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(taskLabel),
                  const SizedBox(height: 4),
                  Text(
                    'Contractor Needed',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          if (qualified.length == 1) {
            final only = qualified.first;
            _workOrderTaskAssigneeDrafts[assignmentKey] =
                _employeeSelectionValue(only);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(taskLabel),
                  const SizedBox(height: 4),
                  Text('Assigned: ${only.name}'),
                ],
              ),
            );
          }

          final candidateValues = <String>{
            _unassignedSelectionValue,
            ...qualified.map(_employeeSelectionValue),
          };
          var selectedValue = _workOrderTaskAssigneeDrafts[assignmentKey];
          final taskId = task.id;
          final persistedValue = taskId == null
              ? null
              : persistedAssignments[taskId];
          final hasSavedAssignment =
              persistedValue != null &&
              candidateValues.contains(persistedValue);
          if (selectedValue == null ||
              !candidateValues.contains(selectedValue)) {
            if (persistedValue != null &&
                candidateValues.contains(persistedValue)) {
              selectedValue = persistedValue;
            } else {
              selectedValue = _employeeSelectionValue(qualified.first);
            }
            _workOrderTaskAssigneeDrafts[assignmentKey] = selectedValue;
          }

          final dropdownItems = <DropdownMenuItem<String>>[
            const DropdownMenuItem<String>(
              value: _unassignedSelectionValue,
              child: Text('Unassigned (Contractor Needed)'),
            ),
            ...qualified.map(
              (employee) => DropdownMenuItem<String>(
                value: _employeeSelectionValue(employee),
                child: Text(employee.name),
              ),
            ),
          ];
          final qualifiedCountLabel =
              '${qualified.length} qualified employee${qualified.length == 1 ? '' : 's'}';

          final selectedEmployeeName = _employeeNameFromSelectionValue(
            selectedValue,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Chip(
                  avatar: Icon(
                    hasSavedAssignment
                        ? Icons.save_outlined
                        : Icons.auto_fix_high_outlined,
                    size: 18,
                  ),
                  label: Text(
                    hasSavedAssignment
                        ? 'Saved selection'
                        : 'Default selection',
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedValue,
                  decoration: InputDecoration(
                    labelText: '$taskLabel - Qualified Employees',
                    border: const OutlineInputBorder(),
                  ),
                  items: dropdownItems,
                  selectedItemBuilder: (context) {
                    return dropdownItems
                        .map((_) => Text(qualifiedCountLabel))
                        .toList(growable: false);
                  },
                  onChanged: (value) async {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _workOrderTaskAssigneeDrafts[assignmentKey] = value;
                    });
                    if (taskId == null) {
                      return;
                    }
                    try {
                      await MachineDatabase.instance
                          .upsertWorkOrderTaskAssignment(
                            subAssemblyId: subAssemblyId,
                            taskId: taskId,
                            assigneeValue: value,
                          );
                      _workOrderTaskAssignmentFutures.remove(subAssemblyId);
                    } catch (error) {
                      if (!mounted) {
                        return;
                      }
                      _showErrorSnackBar(
                        'Failed to save task assignee selection.',
                        error,
                      );
                    }
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  'Selected: $selectedEmployeeName',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  List<_WorkOrderItem> _buildWorkOrderItemsForNextFiveDays() {
    return _buildWorkOrderItemsForNextDays(5);
  }

  /// Builds sorted work orders due from today through the inclusive day window.
  ///
  /// Overdue and unschedulable components are intentionally excluded.
  List<_WorkOrderItem> _buildWorkOrderItemsForNextDays(int daysAhead) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final windowEnd = todayStart.add(
      Duration(days: daysAhead, hours: 23, minutes: 59, seconds: 59),
    );

    final items = <_WorkOrderItem>[];
    for (final machine in _machines) {
      for (final subAssembly in machine.subAssemblies) {
        final projected = _projectedNextDateForSubAssembly(
          machine,
          subAssembly,
        );
        if (projected == null) {
          continue;
        }
        if (projected.isBefore(todayStart) || projected.isAfter(windowEnd)) {
          continue;
        }

        final dueDate = DateTime(
          projected.year,
          projected.month,
          projected.day,
        );
        final daysUntilDue = dueDate.difference(todayStart).inDays;

        items.add(
          _WorkOrderItem(
            machine: machine,
            subAssembly: subAssembly,
            projectedNextDate: projected,
            daysUntilDue: daysUntilDue,
          ),
        );
      }
    }

    items.sort((a, b) {
      final dateCmp = a.projectedNextDate.compareTo(b.projectedNextDate);
      if (dateCmp != 0) {
        return dateCmp;
      }
      final machineCmp = a.machine.name.compareTo(b.machine.name);
      if (machineCmp != 0) {
        return machineCmp;
      }
      return a.subAssembly.name.compareTo(b.subAssembly.name);
    });

    return items;
  }

  /// Builds and opens a printable seven-day work-order PDF with persisted
  /// statuses and task assignments.
  Future<void> _printWorkOrdersPdf() async {
    final weeklyItems = _buildWorkOrderItemsForNextDays(7);
    final dueToday = weeklyItems
        .where((item) => item.daysUntilDue == 0)
        .toList(growable: false);
    final dueThisWeek = weeklyItems
        .where((item) => item.daysUntilDue >= 1 && item.daysUntilDue <= 7)
        .toList(growable: false);
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final yyyy = now.year.toString().padLeft(4, '0');
    final fileName = 'workorder$mm$dd$yyyy.pdf';
    final statusEntries = await Future.wait(
      weeklyItems.map((item) async {
        final subAssemblyId = item.subAssembly.id;
        if (subAssemblyId == null) {
          return null;
        }
        return MachineDatabase.instance.getWorkOrderStatus(subAssemblyId);
      }),
    );
    final workOrderStatusesBySubAssemblyId = <int, WorkOrderStatusEntry>{
      for (final entry in statusEntries.whereType<WorkOrderStatusEntry>())
        entry.subAssemblyId: entry,
    };
    final subAssemblyIds = weeklyItems
        .map((item) => item.subAssembly.id)
        .whereType<int>()
        .toSet()
        .toList(growable: false);
    final assigneeEntries = await Future.wait(
      subAssemblyIds.map((id) async {
        final assignments = await MachineDatabase.instance
            .getWorkOrderTaskAssignments(id);
        return MapEntry(id, assignments);
      }),
    );
    final persistedAssignmentsBySubAssemblyId = <int, Map<int, String>>{
      for (final entry in assigneeEntries) entry.key: entry.value,
    };

    final document = pw.Document();

    pw.Widget section(String title, List<_WorkOrderItem> items) {
      final titleStyle = pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
      );

      if (items.isEmpty) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: titleStyle),
            pw.SizedBox(height: 6),
            pw.Text('No work orders in this section.'),
            pw.SizedBox(height: 14),
          ],
        );
      }

      final groupedTasks = <String, List<Map<String, String>>>{};
      for (final item in items) {
        final dueDate = _formatDate(item.projectedNextDate);
        final dueText = item.daysUntilDue == 0
            ? 'Due today'
            : 'Due in ${item.daysUntilDue} day${item.daysUntilDue == 1 ? '' : 's'}';
        final subAssemblyId = item.subAssembly.id;
        final licenseTrades = _machineLicenseTradeLabels(item.machine);
        final statusEntry = subAssemblyId == null
            ? null
            : workOrderStatusesBySubAssemblyId[subAssemblyId];
        final statusNotes = (statusEntry?.notes ?? '').trim();
        final statusSummary = statusEntry == null
            ? 'Not set'
            : '${statusEntry.status} | Licensed Work: ${statusEntry.isLicensedWork ? 'Yes' : 'No'} | Rescheduled: ${statusEntry.isRescheduled ? 'Yes' : 'No'} | Notes: ${statusNotes.isEmpty ? 'Not set' : statusNotes}';
        final tasks =
            List<MaintenanceTask>.from(item.subAssembly.maintenanceTasks)
              ..sort((a, b) {
                final taskCmp = a.taskType.toLowerCase().compareTo(
                  b.taskType.toLowerCase(),
                );
                if (taskCmp != 0) {
                  return taskCmp;
                }
                return a.timeCategory.toLowerCase().compareTo(
                  b.timeCategory.toLowerCase(),
                );
              });

        for (int taskIndex = 0; taskIndex < tasks.length; taskIndex += 1) {
          final task = tasks[taskIndex];
          final assigneeName = subAssemblyId == null
              ? 'Contractor Needed'
              : _resolvedAssigneeNameForTask(
                  subAssemblyId: subAssemblyId,
                  machine: item.machine,
                  subAssembly: item.subAssembly,
                  task: task,
                  taskIndex: taskIndex,
                  persistedAssignments:
                      persistedAssignmentsBySubAssemblyId[subAssemblyId] ??
                      const <int, String>{},
                  updateDraft: false,
                );

          groupedTasks.putIfAbsent(assigneeName, () => []).add({
            'task': _taskLabel(task),
            'due': '$dueDate ($dueText)',
            'superCategory': _superCategoryForSubAssembly(item.subAssembly),
            'machine': item.machine.name,
            'subAssembly':
                '${item.subAssembly.name} (${item.subAssembly.modelName})',
            'serial': item.subAssembly.serialNumber,
            'component': item.subAssembly.subCategory,
            'location': item.subAssembly.location,
            'trades': licenseTrades.isEmpty ? 'None' : licenseTrades.join(', '),
            'status': statusSummary,
          });
        }
      }

      final assignees = groupedTasks.keys.toList(growable: false)
        ..sort((a, b) {
          if (a == 'Contractor Needed') {
            return 1;
          }
          if (b == 'Contractor Needed') {
            return -1;
          }
          return a.toLowerCase().compareTo(b.toLowerCase());
        });

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: titleStyle),
          pw.SizedBox(height: 6),
          ...assignees.map((assignee) {
            final taskRows =
                groupedTasks[assignee] ?? const <Map<String, String>>[];
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '$assignee (${taskRows.length})',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  ...taskRows.map((row) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Task: ${row['task'] ?? ''}'),
                          pw.Text('Due: ${row['due'] ?? ''}'),
                          pw.Text(
                            'Super Category: ${row['superCategory'] ?? 'Not set'}',
                          ),
                          pw.Text(
                            'Machine: ${row['machine'] ?? ''} | Sub-Assembly: ${row['subAssembly'] ?? ''}',
                          ),
                          pw.Text(
                            'Serial: ${row['serial'] ?? ''} | Component: ${row['component'] ?? ''} | Location: ${row['location'] ?? ''}',
                          ),
                          pw.Text(
                            'Required Trades: ${row['trades'] ?? 'None'}',
                          ),
                          pw.Text('Work Status: ${row['status'] ?? 'Not set'}'),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 10),
        ],
      );
    }

    document.addPage(
      pw.MultiPage(
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              '$fileName | ${_formatDate(now)} | Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          );
        },
        build: (context) {
          return [
            pw.Text(
              'Work Orders Report',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Generated: ${_formatDate(DateTime.now())}'),
            pw.SizedBox(height: 12),
            section('Due Today (${dueToday.length})', dueToday),
            section('Due This Week (${dueThisWeek.length})', dueThisWeek),
          ];
        },
      ),
    );

    final pdfBytes = await document.save();
    await _presentPdfForPrinting(
      fileName,
      pdfBytes,
      successMessage:
          'Opened $fileName in your default PDF viewer. Use the viewer print command to print it.',
    );
  }

  Widget _buildWorkOrdersTab() {
    _ensureMachinesVisible();
    final workOrders = _buildWorkOrderItemsForNextFiveDays();
    final layout = _layoutForContext(context);
    final cardPadding = _cardPaddingForLayout(layout);

    if (workOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No sub-assemblies are due in the next five days.'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _reloadMachinesFromDatabase(showFeedback: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Reload Data'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _printWorkOrdersPdf,
              icon: Icon(_pdfActionIcon),
              label: Text(_workOrdersPdfActionLabel),
            ),
            if (_opensPdfInViewerForPrinting) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildPdfActionHint('the work orders PDF'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: workOrders.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _printWorkOrdersPdf,
                  icon: Icon(_pdfActionIcon),
                  label: Text(_workOrdersPdfActionLabel),
                ),
                if (_opensPdfInViewerForPrinting) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 320,
                    child: _buildPdfActionHint('the work orders PDF'),
                  ),
                ],
              ],
            ),
          );
        }

        final item = workOrders[index - 1];
        final subAssemblyId = item.subAssembly.id;
        final machineLicenseTrades = _machineLicenseTradeLabels(item.machine);
        final dueLabel = _formatDate(item.projectedNextDate);
        final dueText = item.daysUntilDue == 0
            ? 'Due today'
            : 'Due in ${item.daysUntilDue} day${item.daysUntilDue == 1 ? '' : 's'}';
        final superCategory = _superCategoryForSubAssembly(item.subAssembly);

        return Card(
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.subAssembly.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text('Super Category: $superCategory'),
                const SizedBox(height: 8),
                Text('Due Date: $dueLabel ($dueText)'),
                Text('Machine: ${item.machine.name}'),
                Text(
                  'Model: ${item.subAssembly.modelName} (${item.subAssembly.modelNumber})',
                ),
                Text('Serial: ${item.subAssembly.serialNumber}'),
                Text('Location: ${item.subAssembly.location}'),
                const SizedBox(height: 8),
                Text(
                  'Required Trades',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: machineLicenseTrades.isEmpty
                      ? const [Chip(label: Text('None'))]
                      : machineLicenseTrades
                            .map((trade) => Chip(label: Text(trade)))
                            .toList(growable: false),
                ),
                const SizedBox(height: 10),
                if (subAssemblyId != null)
                  FutureBuilder<Map<int, String>>(
                    future: _workOrderTaskAssignmentFutureForSubAssembly(
                      subAssemblyId,
                    ),
                    builder: (context, snapshot) {
                      final persistedAssignments =
                          snapshot.data ?? const <int, String>{};
                      return _buildTaskAssignmentSection(
                        subAssemblyId: subAssemblyId,
                        machine: item.machine,
                        subAssembly: item.subAssembly,
                        persistedAssignments: persistedAssignments,
                      );
                    },
                  ),
                const SizedBox(height: 10),
                if (subAssemblyId == null)
                  const Text(
                    'Status cannot be updated: missing sub-assembly id.',
                  )
                else
                  FutureBuilder<WorkOrderStatusEntry?>(
                    future: _workOrderStatusFutureForSubAssembly(subAssemblyId),
                    builder: (context, snapshot) {
                      final savedEntry = snapshot.data;
                      final savedStatus = savedEntry?.status ?? '';
                      final savedRescheduled =
                          savedEntry?.isRescheduled ?? false;
                      final savedNotes = savedEntry?.notes ?? '';
                      final hasSavedStatus = savedEntry != null;
                      final savedBadgeLabel = !hasSavedStatus
                          ? null
                          : savedRescheduled
                          ? 'Saved: Rescheduled'
                          : 'Saved: $savedStatus';
                      final selectedStatus =
                          _workOrderStatusSelectionDrafts[subAssemblyId] ??
                          savedStatus;
                      final supportsReschedule = _statusSupportsReschedule(
                        selectedStatus,
                      );
                      final selectedRescheduled = supportsReschedule
                          ? (_workOrderRescheduledDrafts[subAssemblyId] ??
                                savedRescheduled)
                          : false;
                      final selectedNotes =
                          _workOrderStatusNotesDrafts[subAssemblyId] ??
                          savedNotes;
                      final enteredAtLabel = snapshot.data == null
                          ? 'Not set'
                          : _formatHistoryTimestamp(
                              snapshot.data!.enteredAtUtc,
                            );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (savedBadgeLabel != null) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  avatar: Icon(
                                    savedRescheduled
                                        ? Icons.schedule_outlined
                                        : Icons.verified_outlined,
                                    size: 18,
                                  ),
                                  label: Text(savedBadgeLabel),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          DropdownButtonFormField<String>(
                            initialValue: selectedStatus.isEmpty
                                ? null
                                : selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Work Status',
                              border: OutlineInputBorder(),
                            ),
                            items: _MachineEntryPageState
                                ._workOrderStatusOptions
                                .map(
                                  (status) => DropdownMenuItem<String>(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) {
                              setState(() {
                                _workOrderStatusSelectionDrafts[subAssemblyId] =
                                    value ?? '';
                                if (!_statusSupportsReschedule(value ?? '')) {
                                  _workOrderRescheduledDrafts[subAssemblyId] =
                                      false;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          if (supportsReschedule)
                            Card(
                              margin: EdgeInsets.zero,
                              child: SwitchListTile.adaptive(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                title: const Text('Rescheduled'),
                                subtitle: const Text(
                                  'Use this when Partial or Bypass work is being rescheduled.',
                                ),
                                value: selectedRescheduled,
                                onChanged: (value) {
                                  setState(() {
                                    _workOrderRescheduledDrafts[subAssemblyId] =
                                        value;
                                  });
                                },
                              ),
                            ),
                          if (supportsReschedule) const SizedBox(height: 8),
                          TextFormField(
                            key: ValueKey(
                              'work-order-notes-$subAssemblyId-$savedNotes',
                            ),
                            initialValue: selectedNotes,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Notes',
                              hintText: 'Add status notes (optional)',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              _workOrderStatusNotesDrafts[subAssemblyId] =
                                  value;
                            },
                          ),
                          const SizedBox(height: 8),
                          Text('Status Entered: $enteredAtLabel'),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: selectedStatus.isEmpty
                                  ? null
                                  : () async {
                                      try {
                                        await _saveWorkOrderStatus(
                                          subAssemblyId: subAssemblyId,
                                          status: selectedStatus,
                                          isRescheduled:
                                              _workOrderRescheduledDrafts[subAssemblyId] ??
                                              selectedRescheduled,
                                          isLicensedWork:
                                              _workOrderLicensedWorkDrafts[subAssemblyId] ??
                                              false,
                                          notes:
                                              _workOrderStatusNotesDrafts[subAssemblyId] ??
                                              selectedNotes,
                                        );
                                      } catch (error) {
                                        if (!mounted) {
                                          return;
                                        }
                                        _showErrorSnackBar(
                                          'Failed to save work order status.',
                                          error,
                                        );
                                      }
                                    },
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Save Status'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
