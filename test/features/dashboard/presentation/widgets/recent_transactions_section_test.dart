import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/recent_transactions_section.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockTransactionListBloc
    extends MockBloc<TransactionListEvent, TransactionListState>
    implements TransactionListBloc {}

class MockNavigateToDetail extends Mock {
  void call(BuildContext context, TransactionEntity transaction);
}

void main() {
  late TransactionListBloc mockTransactionListBloc;
  late MockNavigateToDetail mockNavigateToDetail;
  late MockGoRouter mockGoRouter;

  final mockTransactions = [
    TransactionEntity(
        id: '1',
        title: 'Txn 1',
        amount: 10,
        date: DateTime.now(),
        type: TransactionType.expense),
    TransactionEntity(
        id: '2',
        title: 'Txn 2',
        amount: 20,
        date: DateTime.now(),
        type: TransactionType.expense),
  ];

  setUp(() {
    mockTransactionListBloc = MockTransactionListBloc();
    mockNavigateToDetail = MockNavigateToDetail();
    mockGoRouter = MockGoRouter();
  });

  Widget buildTestWidget(TransactionListState state) {
    when(() => mockTransactionListBloc.state).thenReturn(state);
    return BlocProvider.value(
      value: mockTransactionListBloc,
      child: RecentTransactionsSection(
          navigateToDetailOrEdit: mockNavigateToDetail.call),
    );
  }

  group('RecentTransactionsSection', () {
    testWidgets('shows loading indicator', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: buildTestWidget(
            const TransactionListState(status: ListStatus.loading)),
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message', (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(const TransactionListState(
              status: ListStatus.success, transactions: [])));
      expect(find.text('No recent activity'), findsOneWidget);
      expect(find.text('Your recent transactions will appear here'),
          findsOneWidget);
      expect(find.byIcon(Icons.history_edu), findsOneWidget);
    });

    testWidgets('renders a list of TransactionListItems', (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(TransactionListState(
              status: ListStatus.success, transactions: mockTransactions)));
      expect(find.byType(TransactionListItem), findsNWidgets(2));
    });

    testWidgets('"View All" button navigates', (tester) async {
      when(() => mockGoRouter.go(RouteNames.transactionsList))
          .thenAnswer((_) {});
      await pumpWidgetWithProviders(
          tester: tester,
          router: mockGoRouter,
          widget: buildTestWidget(const TransactionListState(
              status: ListStatus.success, transactions: [])));

      await tester
          .tap(find.byKey(const ValueKey('button_recentTransactions_viewAll')));

      verify(() => mockGoRouter.go(RouteNames.transactionsList)).called(1);
    }, skip: true);

    testWidgets('tapping a list item calls navigateToDetailOrEdit',
        (tester) async {
      when(() => mockNavigateToDetail.call(any(), any())).thenAnswer((_) {});
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(TransactionListState(
              status: ListStatus.success, transactions: mockTransactions)));

      await tester.tap(find.byType(TransactionListItem).first);

      verify(() => mockNavigateToDetail.call(any(), mockTransactions.first))
          .called(1);
    });
  });
}
