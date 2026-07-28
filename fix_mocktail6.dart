import 'dart:io';

void replaceInFile(String filePath, String search, String replace) {
  final file = File(filePath);
  if (!file.existsSync()) {
    print('File not found: $filePath');
    return;
  }
  var content = file.readAsStringSync();
  if (content.contains(search)) {
    content = content.replaceAll(search, replace);
    file.writeAsStringSync(content);
    print('Updated $filePath');
  } else {
    print('Search string not found in $filePath');
  }
}

void main() {
  replaceInFile(
    'test/features/budgets/data/datasources/budget_local_data_source_test.dart',
    '''      when(() => mockBox.put(any(), any())).thenThrow(Exception());''',
    '''      when(() => mockBox.put(any(), any())).thenAnswer((_) async => throw Exception());'''
  );

  replaceInFile(
    'test/features/budgets/data/datasources/budget_local_data_source_test.dart',
    '''      when(() => mockBox.delete(any())).thenThrow(Exception());''',
    '''      when(() => mockBox.delete(any())).thenAnswer((_) async => throw Exception());'''
  );
}
