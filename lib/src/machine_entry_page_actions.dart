// ignore_for_file: invalid_use_of_protected_member, unused_element

part of 'package:maintenanceschedular/main.dart';

extension _MachineEntryPageActionsExtension on _MachineEntryPageState {
  bool get _opensPdfInViewerForPrinting =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  String get _workOrdersPdfActionLabel => _opensPdfInViewerForPrinting
      ? 'Open Work Orders PDF'
      : 'Print Work Orders PDF';

  String get _schedulePdfActionLabel =>
      _opensPdfInViewerForPrinting ? 'Open Schedule PDF' : 'Print Schedule PDF';

  String get _machinesListPdfActionLabel => _opensPdfInViewerForPrinting
      ? 'Open Machines List PDF'
      : 'Print Machines List PDF';

  bool get _opensBackupInViewer =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  String get _exportBackupActionLabel =>
      _opensBackupInViewer ? 'Open Backup JSON' : 'Export Database';

  IconData get _pdfActionIcon => _opensPdfInViewerForPrinting
      ? Icons.open_in_new_outlined
      : Icons.picture_as_pdf_outlined;

  Widget _buildPdfActionHint(String fileDescription) {
    if (!_opensPdfInViewerForPrinting) {
      return const SizedBox.shrink();
    }

    return Text(
      'Windows opens $fileDescription in your default PDF viewer before printing so the filename stays visible.',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  Future<void> _presentBackupForReview(
    String fileName,
    String backupJson,
  ) async {
    if (_opensBackupInViewer) {
      final opened = await Printing.sharePdf(
        bytes: Uint8List.fromList(utf8.encode(backupJson)),
        filename: fileName,
      );

      if (!opened) {
        throw StateError('Unable to open $fileName.');
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Database backup copied to clipboard and opened as $fileName.',
          ),
        ),
      );
      return;
    }

    final preview = backupJson.length > 3500
        ? '${backupJson.substring(0, 3500)}\n\n...output truncated for preview...'
        : backupJson;

    final layout = _layoutForContext(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final maxWidth = _dialogMaxWidthForLayout(layout);
        return AlertDialog(
          insetPadding: _dialogInsetPaddingForLayout(layout),
          title: const Text('Database Exported'),
          content: SizedBox(
            width: maxWidth,
            child: SingleChildScrollView(
              child: SelectableText(
                preview,
                style: Theme.of(
                  dialogContext,
                ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ),
          actions: _dialogActionsForContext(dialogContext, [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ]),
        );
      },
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Database backup copied to clipboard as JSON.'),
      ),
    );
  }

  Future<void> _presentPdfForPrinting(
    String fileName,
    Uint8List pdfBytes, {
    required String successMessage,
  }) async {
    if (_opensPdfInViewerForPrinting) {
      final opened = await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );

      if (!opened) {
        throw StateError('Unable to open $fileName.');
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      return;
    }

    await Printing.layoutPdf(name: fileName, onLayout: (_) => pdfBytes);
  }

  Future<void> _handleDatabaseAction(DatabaseAction action) async {
    switch (action) {
      case DatabaseAction.exportBackup:
        return _exportDatabaseBackup();
      case DatabaseAction.importBackup:
        return _importDatabaseBackup();
      case DatabaseAction.exportEmployeesCsv:
        return exportEmployeesToCsv();
      case DatabaseAction.exportMachinesCsv:
        return exportMachinesToCsv();
      case DatabaseAction.exportEmployeeTemplateCsv:
        return exportEmployeeCsvTemplate();
      case DatabaseAction.exportMachineTemplateCsv:
        return exportMachineCsvTemplate();
      case DatabaseAction.importEmployeesCsv:
        return importEmployeesFromCsv();
      case DatabaseAction.importMachinesCsv:
        return importMachinesFromCsv();
      case DatabaseAction.csvImportHelp:
        return showCsvImportHelp();
      case DatabaseAction.deleteDatabase:
        return _deleteDatabase();
    }
  }

  Future<void> _exportDatabaseBackup() async {
    try {
      final backupJson = await MachineDatabase.instance.exportDatabaseJson();
      await Clipboard.setData(ClipboardData(text: backupJson));

      if (!mounted) {
        return;
      }
      final now = DateTime.now();
      final yyyy = now.year.toString().padLeft(4, '0');
      final mm = now.month.toString().padLeft(2, '0');
      final dd = now.day.toString().padLeft(2, '0');
      final hh = now.hour.toString().padLeft(2, '0');
      final min = now.minute.toString().padLeft(2, '0');
      final ss = now.second.toString().padLeft(2, '0');
      final fileName = 'machine_registry_backup_$yyyy$mm${dd}_$hh$min$ss.json';

      await _presentBackupForReview(fileName, backupJson);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar('Failed to export database.', error);
    }
  }

  Future<void> _importDatabaseBackup() async {
    final inputController = TextEditingController();
    try {
      final layout = _layoutForContext(context);
      final backupJson = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          final maxWidth = _dialogMaxWidthForLayout(layout);
          return AlertDialog(
            insetPadding: _dialogInsetPaddingForLayout(layout),
            title: const Text('Import Database Backup'),
            content: SizedBox(
              width: maxWidth,
              child: TextField(
                controller: inputController,
                minLines: 8,
                maxLines: 18,
                decoration: const InputDecoration(
                  hintText: 'Paste exported backup JSON here',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            actions: _dialogActionsForContext(dialogContext, [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(_cancelActionLabel(dialogContext)),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(inputController.text.trim());
                },
                child: const Text('Import'),
              ),
            ]),
          );
        },
      );

      if (backupJson == null || backupJson.isEmpty) {
        return;
      }

      if (!mounted) {
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final dialogLayout = _layoutForContext(dialogContext);
          return AlertDialog(
            insetPadding: _dialogInsetPaddingForLayout(dialogLayout),
            title: const Text('Replace Existing Data?'),
            content: const Text(
              'Import will replace all current machines, sub-assemblies, and tasks.',
            ),
            actions: _dialogActionsForContext(dialogContext, [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(_cancelActionLabel(dialogContext)),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Replace'),
              ),
            ]),
          );
        },
      );

      if (confirm != true) {
        return;
      }

      final importedCount = await MachineDatabase.instance.importDatabaseJson(
        backupJson,
        clearExisting: true,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = true;
      });
      await _loadMachines(seedSampleData: false);

      if (!mounted) {
        return;
      }

      final importedNoMachines = importedCount == 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $importedCount machine(s).')),
      );
      if (importedNoMachines) {
        _hasShownStartupPrompt = false;
        _showInitialDatabaseSetupPrompt();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar('Failed to import database backup.', error);
    } finally {
      inputController.dispose();
    }
  }

  Future<void> _deleteDatabase() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final layout = _layoutForContext(dialogContext);
        return AlertDialog(
          insetPadding: _dialogInsetPaddingForLayout(layout),
          title: const Text('Delete Entire Database'),
          content: const Text(
            'This will permanently delete all machines, sub-assemblies, and tasks. Continue?',
          ),
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
      return;
    }

    try {
      await MachineDatabase.instance.deleteEntireDatabaseFile();

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = true;
        _selectedTaskType = null;
        _selectedTaskTimeCategory = null;
        _selectedSubCategory = null;
        _hasShownStartupPrompt = false;
        _taskSearchQuery = '';
        _taskSearchController.clear();
      });

      await _loadMachines(seedSampleData: false);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database deleted successfully.')),
      );
      _showInitialDatabaseSetupPrompt();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showErrorSnackBar('Failed to delete database.', error);
    }
  }
}
