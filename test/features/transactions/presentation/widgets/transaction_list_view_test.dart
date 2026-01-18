import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_card.dart';
import 'package:expense_tracker/features/income/presentation/widgets/income_card.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_data.dart';

class MockTransactionListBloc
    extends MockBloc<TransactionListEvent, TransactionListState>
    implements TransactionListBloc {}

class MockCallbacks extends Mock {
  void navigateToDetailOrEdit(
      BuildContext context, TransactionEntity transaction);
  void handleChangeCategoryRequest(
      BuildContext context, TransactionEntity transaction);
  Future<bool> confirmDeletion(
      BuildContext context, TransactionEntity transaction);
}

void main() {
  late TransactionListBloc mockBloc;
  late MockCallbacks mockCallbacks;

  final mockTransactions = [
    TransactionEntity.fromExpense(
      Expense(
          id: '1',
          title: 'Expense 1',
          amount: 50,
          date: DateTime.now(),
          accountId: 'a1'),
    ),
    TransactionEntity.fromIncome(
      Income(
          id: '2',
          title: 'Income 1',
          amount: 200,
          date: DateTime.now(),
          accountId: 'a1'),
    ),
  ];

  setUp(() {
    mockBloc = MockTransactionListBloc();
    mockCallbacks = MockCallbacks();
  });

  Widget buildTestWidget(TransactionListState state) {
    return BlocProvider.value(
      value: mockBloc,
      child: TransactionListView(
        state: state,
        settings: const SettingsState(),
        navigateToDetailOrEdit: mockCallbacks.navigateToDetailOrEdit,
        handleChangeCategoryRequest: mockCallbacks.handleChangeCategoryRequest,
        confirmDeletion: mockCallbacks.confirmDeletion,
        enableAnimations: false,
        accountMap: const {'a1': 'Test Account'},
        isAccountsLoaded: true,
      ),
    );
  }

  group('TransactionListView', () {
    testWidgets('shows loading indicator when state is loading',
        (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(
              const TransactionListState(status: ListStatus.loading)),
          settle: false);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when state is error', (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(const TransactionListState(
              status: ListStatus.error, errorMessage: 'Failed')));
      expect(find.text('Error: Failed'), findsOneWidget);
    });

    testWidgets('shows empty state when no transactions exist', (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(
            const TransactionListState(
              status: ListStatus.success,
              transactions: [],
            ),
          ));
      expect(find.text('No transactions recorded yet'), findsOneWidget);
      expect(find.byKey(const ValueKey('button_listView_addFirst')),
          findsOneWidget);
    });

    testWidgets('shows filtered empty state when filters are applied',
        (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(
            TransactionListState(
              status: ListStatus.success,
              transactions: const [],
              categoryId: '1',
            ),
          ));
      expect(find.text('No transactions match filters'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('button_listView_addFirst')), findsNothing);
    });

    testWidgets('renders a list of ExpenseCard and IncomeCard', (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(
            TransactionListState(
              status: ListStatus.success,
              transactions: mockTransactions,
            ),
          ),
          settle: false);
      await tester.pump();
      expect(find.byType(ExpenseCard), findsOneWidget);
      expect(find.byType(IncomeCard), findsOneWidget);
      expect(find.text('Acc: Test Account'),
          findsNWidgets(2)); // Check if account name is rendered
    });

    testWidgets('tapping card navigates when not in batch mode',
        (tester) async {
      when(() => mockCallbacks.navigateToDetailOrEdit(any(), any()))
          .thenAnswer((_) {});
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(
            TransactionListState(
              status: ListStatus.success,
              transactions: mockTransactions,
              isInBatchEditMode: false,
            ),
          ),
          settle: false);
      await tester.pump();

      await tester.tap(find.byType(ExpenseCard));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockCallbacks.navigateToDetailOrEdit(
          any(), mockTransactions.first)).called(1);
    });

    testWidgets('tapping card dispatches event when in batch mode',
        (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(
            TransactionListState(
              status: ListStatus.success,
              transactions: mockTransactions,
              isInBatchEditMode: true,
            ),
          ),
          settle: false);
      await tester.pump();

      await tester.tap(find.byType(IncomeCard));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockBloc.add(SelectTransaction(mockTransactions.last.id)))
          .called(1);
    });

    testWidgets('swiping a card calls confirmDeletion', (tester) async {
      when(() => mockCallbacks.confirmDeletion(any(), any()))
          .thenAnswer((_) async => true);
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(
            TransactionListState(
              status: ListStatus.success,
              transactions: mockTransactions,
            ),
          ),
          settle: false);
      await tester.pump();

      await tester.drag(find.byType(ExpenseCard), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockCallbacks.confirmDeletion(any(), mockTransactions.first))
          .called(1);
    });
  });
}
