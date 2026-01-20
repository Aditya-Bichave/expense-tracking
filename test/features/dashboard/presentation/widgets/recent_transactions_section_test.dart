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
          settle: false,
          widget: buildTestWidget(
              const TransactionListState(status: ListStatus.loading)));
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message', (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(const TransactionListState(
              status: ListStatus.success, transactions: [])));
      expect(find.text('No recent activity'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
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

      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await pumpWidgetWithProviders(
          tester: tester,
          router: mockGoRouter,
          widget: SingleChildScrollView(
              child: buildTestWidget(const TransactionListState(
                  status: ListStatus.success, transactions: []))));

      final buttonFinder = find.byKey(const ValueKey('button_recentTransactions_viewAll'));

      // FIXME: This test requires proper GoRouter mocking to render the widget while verifying navigation.
      // Currently, passing mockGoRouter prevents the widget from rendering.
      // expect(buttonFinder, findsOneWidget);
      // await tester.ensureVisible(buttonFinder);
      // await tester.tap(buttonFinder);
      // verify(() => mockGoRouter.go(RouteNames.transactionsList)).called(1);
    }, skip: true); // Skipped as it was originally skipped and requires fix

    testWidgets('tapping a list item calls navigateToDetailOrEdit',
        (tester) async {
      when(() => mockNavigateToDetail.call(any(), any())).thenAnswer((_) {});

      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await pumpWidgetWithProviders(
          tester: tester,
          widget: SingleChildScrollView(
            child: buildTestWidget(TransactionListState(
              status: ListStatus.success, transactions: mockTransactions))));

      await tester.tap(find.byType(TransactionListItem).first);

      verify(() => mockNavigateToDetail.call(any(), mockTransactions.first))
          .called(1);
    });
  });
}
