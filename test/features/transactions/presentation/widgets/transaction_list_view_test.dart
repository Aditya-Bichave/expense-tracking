import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_card.dart';
import 'package:expense_tracker/features/income/presentation/widgets/income_card.dart';
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
    TransactionEntity(
        id: '1',
        title: 'Expense 1',
        amount: 50,
        date: DateTime.now(),
        type: TransactionType.expense),
    TransactionEntity(
        id: '2',
        title: 'Income 1',
        amount: 200,
        date: DateTime.now(),
        type: TransactionType.income),
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
      ),
    );
  }

  group('TransactionListView', () {
    testWidgets('shows loading indicator when state is loading',
        (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(
              const TransactionListState(status: ListStatus.loading)));
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
          widget: buildTestWidget(const TransactionListState(
              status: ListStatus.loaded, transactions: [])));
      expect(find.text('No transactions recorded yet'), findsOneWidget);
      expect(find.byKey(const ValueKey('button_listView_addFirst')),
          findsOneWidget);
    });

    testWidgets('shows filtered empty state when filters are applied',
        (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(const TransactionListState(
              status: ListStatus.loaded,
              transactions: [],
              filtersApplied: true)));
      expect(find.text('No transactions match filters'), findsOneWidget);
      expect(
          find.byKey(const ValueKey('button_listView_addFirst')), findsNothing);
    });

    testWidgets('renders a list of ExpenseCard and IncomeCard', (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(TransactionListState(
              status: ListStatus.loaded, transactions: mockTransactions)));
      expect(find.byType(ExpenseCard), findsOneWidget);
      expect(find.byType(IncomeCard), findsOneWidget);
    });

    testWidgets('tapping card navigates when not in batch mode',
        (tester) async {
      when(() => mockCallbacks.navigateToDetailOrEdit(any(), any()))
          .thenAnswer((_) {});
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(TransactionListState(
              status: ListStatus.loaded,
              transactions: mockTransactions,
              isInBatchEditMode: false)));

      await tester.tap(find.byType(ExpenseCard));

      verify(() => mockCallbacks.navigateToDetailOrEdit(
          any(), mockTransactions.first)).called(1);
    });

    testWidgets('tapping card dispatches event when in batch mode',
        (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(TransactionListState(
              status: ListStatus.loaded,
              transactions: mockTransactions,
              isInBatchEditMode: true)));

      await tester.tap(find.byType(IncomeCard));

      verify(() => mockBloc.add(SelectTransaction(mockTransactions.last.id)))
          .called(1);
    });

    testWidgets('swiping a card calls confirmDeletion', (tester) async {
      when(() => mockCallbacks.confirmDeletion(any(), any()))
          .thenAnswer((_) async => true);
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(TransactionListState(
              status: ListStatus.loaded, transactions: mockTransactions)));

      await tester.drag(find.byType(ExpenseCard), const Offset(-500, 0));
      await tester.pumpAndSettle();

      verify(() => mockCallbacks.confirmDeletion(any(), mockTransactions.first))
          .called(1);
    });
  });
}
