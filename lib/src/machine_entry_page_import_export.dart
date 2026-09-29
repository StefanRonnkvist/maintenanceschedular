// ignore_for_file: invalid_use_of_protected_member, unused_element

part of 'package:maintenanceschedular/main.dart';

extension _MachineEntryPageImportExportExtension on _MachineEntryPageState {
  Future<void> showCsvImportHelp() async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final layout = _layoutForContext(dialogContext);
        return AlertDialog(
          insetPadding: _dialogInsetPaddingForLayout(layout),
          title: const Text('CSV Import Help'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Employee CSV columns: id, name, skills, licenses.'),
                SizedBox(height: 8),
                Text('Employee import requires: name.'),
                SizedBox(height: 8),
                Text(
                  'Employee skills and licenses use semicolons between values.',
                ),
                SizedBox(height: 16),
                Text(
                  'Machine CSV columns: id, name, modelName, modelNumber, operatingHours, idleHours, lastCheckDate, serialNumber, location, manufacturer, maintenanceDocumentName, maintenanceDocumentNumber, maintenancePublisher, requiresHvacLicense, requiresRefrigerationLicense, requiresPlumberLicense, requiresElectricianLicense, requiresBoilerLicense.',
                ),
                SizedBox(height: 8),
                Text('Machine import requires: name, modelName, modelNumber.'),
                SizedBox(height: 8),
                Text('License columns accept 1/0, true/false, or yes/no.'),
                SizedBox(height: 8),
                Text(
                  'Use the template actions to generate a file with example rows.',
                ),
              ],
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
  }

  Future<void> _saveCsvFile({
    required String dialogTitle,
    required String fileName,
    required String successMessage,
    required String csvContent,
  }) async {
    final result = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      bytes: utf8.encode(csvContent),
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null) {
      return;
    }

    final savedLocation = result.path.isNotEmpty
        ? result.path
        : result.toString();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$successMessage: $savedLocation'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Exports employees to CSV file.
  /// Opens file picker to save the CSV file.
  Future<void> exportEmployeesToCsv() async {
    try {
      // Get CSV content
      final csvContent = await MachineDatabase.instance.exportEmployeesToCsv();
      if (csvContent == null || csvContent.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No employees to export.')),
        );
        return;
      }

      await _saveCsvFile(
        dialogTitle: 'Save Employees CSV',
        fileName: 'employees_${DateTime.now().millisecondsSinceEpoch}.csv',
        successMessage: 'Employees exported to',
        csvContent: csvContent,
      );
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to export employees.', error);
    }
  }

  /// Export machines to CSV file.
  /// Opens file picker to save the CSV file.
  Future<void> exportMachinesToCsv() async {
    try {
      // Get CSV content
      final csvContent = await MachineDatabase.instance.exportMachinesToCsv();
      if (csvContent == null || csvContent.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No machines to export.')));
        return;
      }

      await _saveCsvFile(
        dialogTitle: 'Save Machines CSV',
        fileName: 'machines_${DateTime.now().millisecondsSinceEpoch}.csv',
        successMessage: 'Machines exported to',
        csvContent: csvContent,
      );
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to export machines.', error);
    }
  }

  Future<void> exportEmployeeCsvTemplate() async {
    try {
      final csvContent = await MachineDatabase.instance
          .exportEmployeeTemplateToCsv();
      if (csvContent == null || csvContent.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create employee CSV template.'),
          ),
        );
        return;
      }

      await _saveCsvFile(
        dialogTitle: 'Save Employee CSV Template',
        fileName: 'employee_template.csv',
        successMessage: 'Employee CSV template saved to',
        csvContent: csvContent,
      );
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to create employee CSV template.', error);
    }
  }

  Future<void> exportMachineCsvTemplate() async {
    try {
      final csvContent = await MachineDatabase.instance
          .exportMachineTemplateToCsv();
      if (csvContent == null || csvContent.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create machine CSV template.'),
          ),
        );
        return;
      }

      await _saveCsvFile(
        dialogTitle: 'Save Machine CSV Template',
        fileName: 'machine_template.csv',
        successMessage: 'Machine CSV template saved to',
        csvContent: csvContent,
      );
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to create machine CSV template.', error);
    }
  }

  /// Imports employees from CSV file.
  /// Opens file picker to select the CSV file.
  Future<void> importEmployeesFromCsv() async {
    try {
      // Open file picker to select CSV
      final pickedFile = await FilePicker.pickFile(
        dialogTitle: 'Select Employees CSV',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (pickedFile == null) {
        return; // User cancelled
      }

      final filePath = pickedFile.path;
      if (filePath == null || filePath.isEmpty) {
        return;
      }

      // Read file
      final csvFile = File(filePath);
      final csvContent = await csvFile.readAsString();

      // Import employees
      final importedCount = await MachineDatabase.instance
          .importEmployeesFromCsv(csvContent);

      if (!mounted) return;

      if (importedCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No employees were imported.')),
        );
        return;
      }

      // Reload employees data
      await _reloadEmployeeData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$importedCount employees imported successfully.'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to import employees.', error);
    }
  }

  /// Imports machines from CSV file.
  /// Opens file picker to select the CSV file.
  Future<void> importMachinesFromCsv() async {
    try {
      // Open file picker to select CSV
      final pickedFile = await FilePicker.pickFile(
        dialogTitle: 'Select Machines CSV',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (pickedFile == null) {
        return; // User cancelled
      }

      final filePath = pickedFile.path;
      if (filePath == null || filePath.isEmpty) {
        return;
      }

      // Read file
      final csvFile = File(filePath);
      final csvContent = await csvFile.readAsString();

      // Import machines
      final importedCount = await MachineDatabase.instance
          .importMachinesFromCsv(csvContent);

      if (!mounted) return;

      if (importedCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No machines were imported.')),
        );
        return;
      }

      // Reload machines data
      await _loadMachines(seedSampleData: false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$importedCount machines imported successfully.'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to import machines.', error);
    }
  }

  /// Helper method to reload employee data.
  Future<void> _reloadEmployeeData() async {
    try {
      await _loadEmployees();
      await _refreshSkillTypes();
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to reload employees.', error);
    }
  }
}
