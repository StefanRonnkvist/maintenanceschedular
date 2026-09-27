/// Normalized maintenance table and the descriptive text associated with
/// maintenance levels.
class MaintenanceCsvData {
  const MaintenanceCsvData({
    required this.headers,
    required this.rows,
    required this.levelDetails,
  });

  /// Labels for the populated columns in [rows].
  final List<String> headers;

  /// Maintenance records aligned positionally with [headers].
  final List<List<String>> rows;

  /// Level identifier to title-and-description pairs.
  final Map<String, List<String>> levelDetails;
}
