@Skip('Needs stabilization')
library transaction_form_test;

import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../../../helpers/pump_app.dart';

class MockAddEditTransactionBloc
    extends MockBloc<AddEditTransactionEvent, AddEditTransactionState>
    implements AddEditTransactionBloc {}

class MockOnSubmit extends Mock {
  void call({
    required TransactionType type,
    required String? title,
    required double amount,
    required DateTime date,
    required Category? category,
    required String? fromAccountId,
    required String? toAccountId,
    required String? notes,
  });
}

void main() {
  late AddEditTransactionBloc mockBloc;
  late MockOnSubmit mockOnSubmit;

  final mockTransaction = Transaction(
    id: '1',
    title: 'Initial Title',
    amount: 123.45,
    date: DateTime(2023),
    fromAccountId: 'acc1',
    category: Category.uncategorized,
    type: TransactionType.expense,
  );

  setUp(() {
    mockBloc = MockAddEditTransactionBloc();
    mockOnSubmit = MockOnSubmit();
    when(() => mockBloc.state).thenReturn(const AddEditTransactionState());
  });

  Widget buildTestWidget({
    Transaction? initialTransaction,
    Category? initialCategory,
    String? initialAccountId,
  }) {
    return BlocProvider.value(
      value: mockBloc,
      child: TransactionForm(
        initialTransaction: initialTransaction,
        initialCategory: initialCategory,
        initialAccountId: initialAccountId,
        onSubmit: mockOnSubmit.call,
      ),
    );
  }

  group('TransactionForm', () {
    testWidgets('initializes fields with initialTransaction data',
        (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: buildTestWidget(initialTransaction: mockTransaction),
        settle: false,
      );
      await tester.pump();
      expect(find.text('Initial Title'), findsOneWidget);
      expect(find.text('123.45'), findsOneWidget);
    });

    testWidgets(
        'toggling transaction type clears category and dispatches event',
        (tester) async {
      when(() => mockBloc.add(any())).thenAnswer((_) async {});
      await pumpWidgetWithProviders(
        tester: tester,
        widget: buildTestWidget(initialTransaction: mockTransaction),
        settle: false,
      );
      await tester.pump();
      await tester.tap(find.byType(ToggleSwitch));
      await tester.pump();

      verify(() => mockBloc
          .add(const TransactionTypeChanged(TransactionType.income))).called(1);
    });

    testWidgets('onSubmit is called with correct data when form is valid',
        (tester) async {
      when(() => mockOnSubmit.call(
            type: any(named: 'type'),
            title: any(named: 'title'),
            amount: any(named: 'amount'),
            date: any(named: 'date'),
            category: any(named: 'category'),
            fromAccountId: any(named: 'fromAccountId'),
            toAccountId: any(named: 'toAccountId'),
            notes: any(named: 'notes'),
          )).thenAnswer((_) {});
      await pumpWidgetWithProviders(
        tester: tester,
        widget: buildTestWidget(
          initialCategory: Category.uncategorized,
          initialAccountId: 'acc1',
        ),
        settle: false,
      );
      await tester.pump();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Title / Description'),
          'Test Title');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Amount'), '50.00');

      await tester
          .tap(find.byKey(const ValueKey('button_transactionForm_submit')));
      await tester.pump();

      verify(() => mockOnSubmit.call(
            type: TransactionType.expense,
            title: 'Test Title',
            amount: 50.00,
            date: any(named: 'date'),
            category: Category.uncategorized,
            fromAccountId: 'acc1',
            toAccountId: null,
            notes: null,
          )).called(1);
    });

    testWidgets('onSubmit is not called when form is invalid', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: buildTestWidget(),
        settle: false,
      );
      await tester.pump();

      await tester
          .tap(find.byKey(const ValueKey('button_transactionForm_submit')));
      await tester.pump();

      verifyNever(() => mockOnSubmit.call(
            type: any(named: 'type'),
            title: any(named: 'title'),
            amount: any(named: 'amount'),
            date: any(named: 'date'),
            category: any(named: 'category'),
            fromAccountId: any(named: 'fromAccountId'),
            toAccountId: any(named: 'toAccountId'),
            notes: any(named: 'notes'),
          ));
      expect(
          find.text('Please correct the errors in the form.'), findsOneWidget);
    });
  });
}
