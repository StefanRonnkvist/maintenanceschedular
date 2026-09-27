import 'package:flutter/services.dart' show rootBundle;
import 'package:plannedmaintenance/features/maintenance/data/parsers/maintenance_csv_parser.dart';
import 'package:plannedmaintenance/features/maintenance/domain/models/maintenance_csv_data.dart';

/// Loads and normalizes the bundled maintenance data assets.
class CsvDataLoader {
  final MaintenanceCsvParser _parser = MaintenanceCsvParser();

  /// Reads both CSV assets and returns rows containing only populated columns.
  ///
  /// Rows whose width differs from the header are discarded so later code can
  /// safely address every retained column by index.
  Future<MaintenanceCsvData> load() async {
    final rawData = await rootBundle.loadString('assets/data.csv');
    final rawLevelData = await rootBundle.loadString('assets/level.csv');

    final parsedLevelDetails = _parser.parseLevelDetails(rawLevelData);
    final csvTable = _parser.parseCsvRows(rawData);

    if (csvTable.isEmpty) {
      return MaintenanceCsvData(
        headers: const [],
        rows: const [],
        levelDetails: parsedLevelDetails,
      );
    }

    final headerRow = csvTable[0].map((e) => e.toString().trim()).toList();
    final dataRows = csvTable
        .sublist(1)
        .where((row) => row.length == headerRow.length)
        .map((row) => row.map((e) => e.toString().trim()).toList())
        .toList();

    final nonEmptyColumnIndices = _parser.getNonEmptyColumnIndices(
      headerRow,
      dataRows,
    );
    final filteredHeaders = nonEmptyColumnIndices
        .map((index) => headerRow[index])
        .toList();
    final filteredRows = dataRows
        .map((row) => nonEmptyColumnIndices.map((index) => row[index]).toList())
        .toList();

    return MaintenanceCsvData(
      headers: filteredHeaders,
      rows: filteredRows,
      levelDetails: parsedLevelDetails,
    );
  }
}
