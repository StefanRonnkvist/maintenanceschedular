// ignore_for_file: invalid_use_of_protected_member, unused_element

part of 'package:maintenanceschedular/main.dart';

extension _MachineEntryPageCalendarExtension on _MachineEntryPageState {
  /// Formats a signed day offset for schedule and maintenance displays.
  String _dueInLabel(int? daysUntilDue) {
    if (daysUntilDue == null) {
      return 'Unavailable';
    }
    if (daysUntilDue < 0) {
      final overdueDays = daysUntilDue.abs();
      return 'Overdue by $overdueDays day${overdueDays == 1 ? '' : 's'}';
    }
    if (daysUntilDue == 0) {
      return 'Today';
    }
    if (daysUntilDue == 1) {
      return '1 day';
    }
    return '$daysUntilDue days';
  }

  /// Counts non-overdue tasks in mutually exclusive future-time buckets.
  ///
  /// Bypassed and partial counts come from work-order status records rather
  /// than the estimated task list and are prepended to the result.
  List<({String label, int count})> _dueBucketCounts(
    List<_EstimatedTaskItem> items, {
    int bypassed = 0,
    int partial = 0,
  }) {
    int today = 0;
    int week = 0;
    int month = 0;
    int quarter = 0;
    int semiAnnual = 0;
    int annual = 0;
    int biAnnual = 0;
    int greaterThanBiAnnual = 0;

    for (final item in items) {
      final dueDays = item.daysUntilDue;
      if (dueDays == null || dueDays < 0) {
        continue;
      }

      if (dueDays == 0) {
        today += 1;
      } else if (dueDays <= 7) {
        week += 1;
      } else if (dueDays <= 31) {
        month += 1;
      } else if (dueDays <= 92) {
        quarter += 1;
      } else if (dueDays <= 183) {
        semiAnnual += 1;
      } else if (dueDays <= 365) {
        annual += 1;
      } else if (dueDays <= 730) {
        biAnnual += 1;
      } else {
        greaterThanBiAnnual += 1;
      }
    }

    return [
      (label: 'Bypassed', count: bypassed),
      (label: 'Partial', count: partial),
      (label: 'Today', count: today),
      (label: 'Week', count: week),
      (label: 'Month', count: month),
      (label: 'Quarter', count: quarter),
      (label: 'Semi-Annual', count: semiAnnual),
      (label: 'Annual', count: annual),
      (label: 'Biannual', count: biAnnual),
      (label: 'Greater than Biannual', count: greaterThanBiAnnual),
    ];
  }

  /// Projects every maintenance task from the machine's last check date and
  /// sorts dated tasks first, followed by stable machine/component/task names.
  List<_EstimatedTaskItem> _buildEstimatedTasksForCalendar() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final items = <_EstimatedTaskItem>[];
    for (final machine in _machines) {
      for (final subAssembly in machine.subAssemblies) {
        for (final task in subAssembly.maintenanceTasks) {
          final projected = _projectedNextDateForTask(machine, task);
          final dueDate = projected == null
              ? null
              : DateTime(projected.year, projected.month, projected.day);
          final daysUntilDue = dueDate?.difference(todayStart).inDays;
          items.add(
            _EstimatedTaskItem(
              machine: machine,
              subAssembly: subAssembly,
              task: task,
              projectedDate: projected,
              daysUntilDue: daysUntilDue,
            ),
          );
        }
      }
    }

    items.sort((a, b) {
      final aDate = a.projectedDate;
      final bDate = b.projectedDate;
      if (aDate == null && bDate != null) {
        return 1;
      }
      if (aDate != null && bDate == null) {
        return -1;
      }
      if (aDate != null && bDate != null) {
        final dateCmp = aDate.compareTo(bDate);
        if (dateCmp != 0) {
          return dateCmp;
        }
      }

      final machineCmp = a.machine.name.compareTo(b.machine.name);
      if (machineCmp != 0) {
        return machineCmp;
      }

      final subAssemblyCmp = a.subAssembly.name.compareTo(b.subAssembly.name);
      if (subAssemblyCmp != 0) {
        return subAssemblyCmp;
      }

      return a.task.taskType.compareTo(b.task.taskType);
    });

    return items;
  }

  /// Builds and opens a printable PDF containing the current projected schedule.
  Future<void> _printSchedulePdf() async {
    final items = _buildEstimatedTasksForCalendar();
    final statusCounts = await MachineDatabase.instance
        .getWorkOrderStatusCounts();
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final yyyy = now.year.toString().padLeft(4, '0');
    final fileName = 'schedule$mm$dd$yyyy.pdf';
    final dueBuckets = _dueBucketCounts(
      items,
      bypassed: statusCounts['Bypass'] ?? 0,
      partial: statusCounts['Partial'] ?? 0,
    );

    final document = pw.Document();

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
              'Schedule Report',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Generated: ${_formatDate(now)}'),
            pw.SizedBox(height: 10),
            pw.Wrap(
              spacing: 10,
              runSpacing: 6,
              children: dueBuckets
                  .map((bucket) => pw.Text('${bucket.label}: ${bucket.count}'))
                  .toList(growable: false),
            ),
            pw.SizedBox(height: 12),
            ...items.map((item) {
              final dueDate = item.projectedDate == null
                  ? 'Unavailable'
                  : _formatDate(item.projectedDate!);
              final dueIn = _dueInLabel(item.daysUntilDue);
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item.task.taskType,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('Due Date: $dueDate ($dueIn)'),
                    pw.Text('Machine: ${item.machine.name}'),
                    pw.Text('Sub-Assembly: ${item.subAssembly.name}'),
                    pw.Text(
                      'Interval: ${item.task.timeValue} ${item.task.timeCategory}',
                    ),
                    pw.Text(
                      'Component: ${item.subAssembly.subCategory} | Location: ${item.subAssembly.location}',
                    ),
                  ],
                ),
              );
            }),
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

  Widget _buildCalendarTab() {
    _ensureMachinesVisible();
    final items = _buildEstimatedTasksForCalendar();

    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Schedule',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                const Text(
                  'All maintenance tasks listed in due order. Tasks without a '
                  'date-based interval appear at the end as Unavailable.',
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _printSchedulePdf,
                        icon: Icon(_pdfActionIcon),
                        label: Text(_schedulePdfActionLabel),
                      ),
                      if (_opensPdfInViewerForPrinting) ...[
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 320,
                          child: _buildPdfActionHint('the schedule PDF'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                FutureBuilder<Map<String, int>>(
                  future: MachineDatabase.instance.getWorkOrderStatusCounts(),
                  builder: (context, snapshot) {
                    final statusCounts = snapshot.data ?? const <String, int>{};
                    final bypassedCount = statusCounts['Bypass'] ?? 0;
                    final partialCount = statusCounts['Partial'] ?? 0;
                    final dueBuckets = _dueBucketCounts(
                      items,
                      bypassed: bypassedCount,
                      partial: partialCount,
                    );

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: dueBuckets
                            .map(
                              (bucket) => Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bucket.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text('${bucket.count}'),
                                  ],
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('No maintenance tasks are available to display.'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _reloadMachinesFromDatabase(showFeedback: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reload Data'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _printSchedulePdf,
                    icon: Icon(_pdfActionIcon),
                    label: Text(_schedulePdfActionLabel),
                  ),
                  if (_opensPdfInViewerForPrinting) ...[
                    const SizedBox(height: 8),
                    _buildPdfActionHint('the schedule PDF'),
                  ],
                ],
              ),
            ),
          )
        else
          ...items.map(_buildScheduleTaskCard),
      ],
    );
  }

  Widget _buildScheduleTaskCard(_EstimatedTaskItem item) {
    final dueDate = item.projectedDate == null
        ? 'Unavailable'
        : _formatDate(item.projectedDate!);
    final dueIn = _dueInLabel(item.daysUntilDue);
    final machineLicenseTrades = _machineLicenseTradeLabels(item.machine);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.task.taskType,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text('Due Date: $dueDate ($dueIn)'),
            Text('Machine: ${item.machine.name}'),
            Text('Sub-Assembly: ${item.subAssembly.name}'),
            Text('Interval: ${item.task.timeValue} ${item.task.timeCategory}'),
            Text('Component: ${item.subAssembly.subCategory}'),
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
          ],
        ),
      ),
    );
  }
}
