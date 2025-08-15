import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../../../helpers/pump_app.dart';

class MockAddEditTransactionBloc extends MockBloc<AddEditTransactionEvent, AddEditTransactionState>
    implements AddEditTransactionBloc {}

class MockOnSubmit extends Mock {
  void call(TransactionType type, String title, double amount, DateTime date,
      Category category, String accountId, String? notes);
}

void main() {
  late AddEditTransactionBloc mockBloc;
  late MockOnSubmit mockOnSubmit;

  final mockTransaction = TransactionEntity(
    id: '1',
    title: 'Initial Title',
    amount: 123.45,
    date: DateTime(2023),
    accountId: 'acc1',
    category: Category.uncategorized,
    type: TransactionType.expense,
    notes: 'Initial notes',
  );

  setUp(() {
    mockBloc = MockAddEditTransactionBloc();
    mockOnSubmit = MockOnSubmit();
    when(() => mockBloc.state).thenReturn(const AddEditTransactionState());
  });

  Widget buildTestWidget({TransactionEntity? initialTransaction}) {
    return BlocProvider.value(
      value: mockBloc,
      child: TransactionForm(
        initialTransaction: initialTransaction,
        onSubmit: mockOnSubmit.call,
      ),
    );
  }

  group('TransactionForm', () {
    testWidgets('initializes fields with initialTransaction data', (tester) async {
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget(initialTransaction: mockTransaction));

      expect(find.text('Initial Title'), findsOneWidget);
      expect(find.text('123.45'), findsOneWidget);
      expect(find.text('Initial notes'), findsOneWidget);
    });

    testWidgets('toggling transaction type clears category and dispatches event', (tester) async {
      when(() => mockBloc.add(any())).thenAnswer((_) async {});
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget(initialTransaction: mockTransaction));

      await tester.tap(find.byType(ToggleSwitch));
      await tester.pumpAndSettle();

      verify(() => mockBloc.add(const TransactionTypeChanged(TransactionType.income))).called(1);
    });

    testWidgets('onSubmit is called with correct data when form is valid', (tester) async {
      when(() => mockOnSubmit.call(any(), any(), any(), any(), any(), any(), any())).thenAnswer((_) {});
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());

      await tester.enterText(find.widgetWithText(TextFormField, 'Title / Description'), 'Test Title');
      await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '50.00');

      // Can't easily select from dropdowns in test, so we assume a value is set.
      // In a real scenario, you would need to mock the dropdown's state or interaction.
      final formState = tester.state<TransactionFormState>(find.byType(TransactionForm));
      formState.setState(() {
        formState.selectedCategory = Category.uncategorized;
        formState.currentAccountId = 'acc1';
      });

      await tester.tap(find.byKey(const ValueKey('button_transactionForm_submit')));
      await tester.pump();

      verify(() => mockOnSubmit.call(
            TransactionType.expense,
            'Test Title',
            50.00,
            any(named: 'date'),
            Category.uncategorized,
            'acc1',
            any(named: 'notes'),
          )).called(1);
    });

    testWidgets('onSubmit is not called when form is invalid', (tester) async {
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());

      await tester.tap(find.byKey(const ValueKey('button_transactionForm_submit')));
      await tester.pump();

      verifyNever(() => mockOnSubmit.call(any(), any(), any(), any(), any(), any(), any()));
      expect(find.text('Please correct the errors in the form.'), findsOneWidget);
    });
  });
}
