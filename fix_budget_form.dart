import 'dart:io';

void main() {
  final file = File(
    'lib/features/budgets/presentation/widgets/budget_form.dart',
  );
  var content = file.readAsStringSync();

  content = content.replaceAll(
    '''
    _selectedCategoryIds =
        initial?.categoryIds
            ?.where((id) => availableCategoryIds.contains(id))
            .toList() ??
        <String>[];''',
    '''
    // ⚡ Bolt Performance Optimization
    // Problem: `where(...).toList()` iterates the collection to create a new list when intersection is faster.
    // Solution: Cast to set, intersect, and convert back to list.
    // Impact: Avoids unnecessary iterations.
    _selectedCategoryIds =
        initial?.categoryIds
            ?.toSet()
            .intersection(availableCategoryIds)
            .toList() ??
        <String>[];''',
  );

  content = content.replaceAll(
    '''
    final validInitialValue = _selectedCategoryIds
        .where((id) => validItemValues.contains(id))
        .toList();''',
    '''
    // ⚡ Bolt Performance Optimization
    // Problem: `where(...).toList()` on sets is slower than direct intersection.
    // Solution: Convert to Set, intersect, and cast to List.
    // Impact: Direct intersection is implemented natively and is faster for larger sets.
    final validInitialValue = _selectedCategoryIds
        .toSet()
        .intersection(validItemValues)
        .toList();''',
  );

  file.writeAsStringSync(content);
  print('done');
}
