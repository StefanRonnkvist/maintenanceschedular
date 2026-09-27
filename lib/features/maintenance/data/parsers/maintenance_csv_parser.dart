/// Converts the maintenance CSV assets into structures used by the domain and
/// presentation layers.
class MaintenanceCsvParser {
  /// Maps each level identifier to its title and description.
  ///
  /// Blank lines are ignored. The first two commas separate the identifier and
  /// title; any remaining comma-separated cells are rejoined as the
  /// description.
  Map<String, List<String>> parseLevelDetails(String rawLevelData) {
    final Map<String, List<String>> parsedLevelDetails = {};
    for (final row
        in rawLevelData
            .split('\n')
            .map((line) => line.replaceAll('\r', '').trim())
            .where((line) => line.isNotEmpty)) {
      final columns = row.split(',').map((cell) => cell.trim()).toList();
      if (columns.length >= 3) {
        parsedLevelDetails[columns[0]] = [
          columns[1],
          columns.sublist(2).join(', '),
        ];
      }
    }
    return parsedLevelDetails;
  }

  /// Splits the main CSV asset into rows while preserving empty cells.
  ///
  /// This parser intentionally handles the project's simple, unquoted CSV
  /// format. It removes Windows carriage returns and skips empty rows.
  List<List<dynamic>> parseCsvRows(String rawData) {
    return rawData
        .split('\n')
        .map((row) => row.replaceAll('\r', ''))
        .where((row) => row.isNotEmpty)
        .map((row) => row.split(','))
        .toList();
  }

  /// Returns header indices whose corresponding column contains any data.
  ///
  /// Short rows are tolerated by checking their length before reading a cell.
  List<int> getNonEmptyColumnIndices(
    List<String> headerRow,
    List<List<String>> dataRows,
  ) {
    final List<int> nonEmptyColumnIndices = [];
    if (dataRows.isEmpty) {
      return nonEmptyColumnIndices;
    }

    for (int i = 0; i < headerRow.length; i++) {
      bool columnHasData = false;
      for (final row in dataRows) {
        if (i < row.length && row[i].isNotEmpty) {
          columnHasData = true;
          break;
        }
      }
      if (columnHasData) {
        nonEmptyColumnIndices.add(i);
      }
    }

    return nonEmptyColumnIndices;
  }
}
