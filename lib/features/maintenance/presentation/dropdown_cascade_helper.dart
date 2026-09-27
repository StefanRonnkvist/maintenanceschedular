/// Computes the options available at each step of the maintenance selector.
class DropdownCascadeHelper {
  const DropdownCascadeHelper();

  /// Keeps rows matching every selection before [index].
  ///
  /// A null selection is treated as unconstrained, allowing callers to reuse
  /// the helper while a cascade is only partially selected.
  List<List<String>> relevantDataForIndex({
    required int index,
    required List<List<String>> source,
    required List<String?> selectedValues,
  }) {
    var relevantData = source;
    for (int i = 0; i < index; i++) {
      final selected = selectedValues[i];
      if (selected != null) {
        relevantData = relevantData.where((row) => row[i] == selected).toList();
      }
    }
    return relevantData;
  }

  /// Returns non-empty values from [index] in first-seen order.
  List<String> uniqueItemsAtIndex({
    required int index,
    required List<List<String>> source,
  }) {
    final allItems = source
        .map((row) => row[index])
        .where((item) => item.isNotEmpty)
        .toList();

    final List<String> uniqueItems = [];
    for (final item in allItems) {
      if (!uniqueItems.contains(item)) {
        uniqueItems.add(item);
      }
    }
    return uniqueItems;
  }
}
