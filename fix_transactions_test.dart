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
        [];''',
    '''
    _selectedCategoryIds =
        initial?.categoryIds
            ?.where((id) => availableCategoryIds.contains(id))
            .toList() ??
        <String>[];''',
  );

  file.writeAsStringSync(content);
  print('done');
}
