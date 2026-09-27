import 'package:flutter/material.dart';
import 'package:plannedmaintenance/features/maintenance/data/csv_data_loader.dart';
import 'package:plannedmaintenance/features/maintenance/presentation/dropdown_cascade_helper.dart';

/// Presents the maintenance table as a sequence of dependent selectors.
class CsvDropdowns extends StatefulWidget {
  const CsvDropdowns({super.key});

  @override
  State<CsvDropdowns> createState() => _CsvDropdownsState();
}

class _CsvDropdownsState extends State<CsvDropdowns> {
  final CsvDataLoader _dataLoader = CsvDataLoader();
  final DropdownCascadeHelper _cascadeHelper = const DropdownCascadeHelper();

  List<String> _headers = [];
  List<List<String>> _data = [];
  Map<String, List<String>> _levelDetails = {};
  List<String?> _selectedValues = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadCsvData();
  }

  /// Loads the asset-backed table and initializes one selection per header.
  Future<void> _loadCsvData() async {
    try {
      final csvData = await _dataLoader.load();
      setState(() {
        _headers = csvData.headers;
        _data = csvData.rows;
        _levelDetails = csvData.levelDetails;
        _selectedValues = List<String?>.filled(_headers.length, null);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  /// Applies a selection and invalidates every dependent value to its right.
  void _onDropdownChanged(String? newValue, int index) {
    if (newValue != _selectedValues[index]) {
      setState(() {
        _selectedValues[index] = newValue;
        for (int i = index + 1; i < _headers.length; i++) {
          _selectedValues[i] = null;
        }
      });
    }
  }

  /// Builds the explanatory text associated with a selected level.
  Widget _buildLevelDetails(String levelValue) {
    final details = _levelDetails[levelValue];
    if (details == null || details.length < 2) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: 4.0,
        right: 4.0,
        top: 4.0,
        bottom: 12.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            details[0],
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(details[1]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_loadError != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading data: $_loadError',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        );
      }

      if (_data.isEmpty) {
        return const Center(child: Text('No valid data found.'));
      }

      final List<Widget> dropdowns = [];
      for (int index = 0; index < _headers.length; index++) {
        final header = _headers[index];

        final relevantData = _cascadeHelper.relevantDataForIndex(
          index: index,
          source: _data,
          selectedValues: _selectedValues,
        );
        final uniqueItems = _cascadeHelper.uniqueItemsAtIndex(
          index: index,
          source: relevantData,
        );

        final hasContent = uniqueItems.isNotEmpty;
        if ((index > 0 && _selectedValues[index - 1] == null) || !hasContent) {
          continue;
        }

        if (uniqueItems.length == 1) {
          if (_selectedValues[index] == null) {
            // Updating state during build is unsafe, so defer automatic
            // selection until the current frame's synchronous work finishes.
            Future.microtask(
              () => _onDropdownChanged(uniqueItems.first, index),
            );
          }
          dropdowns.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                controller: TextEditingController(text: uniqueItems.first),
                readOnly: true,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: header,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          );
        } else {
          dropdowns.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedValues[index],
                decoration: InputDecoration(
                  labelText: header,
                  border: const OutlineInputBorder(),
                ),
                items: uniqueItems.map((value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (newValue) {
                  _onDropdownChanged(newValue, index);
                },
              ),
            ),
          );
        }

        if (header.toLowerCase() == 'level') {
          final selectedLevel =
              _selectedValues[index] ??
              (uniqueItems.length == 1 ? uniqueItems.first : null);
          if (selectedLevel != null && selectedLevel.isNotEmpty) {
            dropdowns.add(_buildLevelDetails(selectedLevel));
          }
        }
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: dropdowns,
        ),
      );
    } catch (e) {
      return Center(child: Text('An error occurred while building the UI: $e'));
    }
  }
}
