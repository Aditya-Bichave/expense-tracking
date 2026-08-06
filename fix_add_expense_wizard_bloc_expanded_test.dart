import 'dart:io';

void main() {
  final file = File('test/features/add_expense/presentation/bloc/add_expense_wizard_bloc_expanded_test.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst(
    "registerFallbackValue(const AddExpenseWizardState());",
    "// Removed AddExpenseWizardState fallback since FakeAddExpenseWizardState is registered"
  );
  content = content.replaceFirst(
    "when(\n          () => repository.createExpense(any()),\n        ).thenAnswer((_) async => throw Exception('Failed to create'));",
    "when(\n          () => repository.createExpense(any<AddExpenseWizardState>()),\n        ).thenAnswer((_) async => throw Exception('Failed to create'));"
  );
  content = content.replaceFirst(
    "when(() => repository.createExpense(any())).thenAnswer((_) async => throw Exception('Failed to create'));",
    "when(() => repository.createExpense(any<AddExpenseWizardState>())).thenAnswer((_) async => throw Exception('Failed to create'));"
  );
  file.writeAsStringSync(content);
}
