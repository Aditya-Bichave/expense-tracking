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
import 'package:go_router/go_router.dart';
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
      child: SingleChildScrollView(
        child: RecentTransactionsSection(
            navigateToDetailOrEdit: mockNavigateToDetail.call),
      ),
    );
  }

  group('RecentTransactionsSection', () {
    testWidgets('shows loading indicator', (tester) async {
      await pumpWidgetWithProviders(
          tester: tester,
          settle: false,
          widget: buildTestWidget(
              const TransactionListState(status: ListStatus.loading)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message with action button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(const TransactionListState(
              status: ListStatus.success, transactions: [])));

      expect(find.text('No recent activity'), findsOneWidget);
      expect(find.text('Record your first transaction to see it here.'),
          findsOneWidget);
      expect(find.text('Add Transaction'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('tapping "Add Transaction" navigates', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool pushed = false;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => buildTestWidget(
                const TransactionListState(
                    status: ListStatus.success, transactions: [])),
          ),
          GoRoute(
            path: '/add',
            name: RouteNames.addTransaction,
            builder: (context, state) {
              pushed = true;
              return const SizedBox();
            },
          ),
        ],
      );

      await pumpWidgetWithProviders(
        tester: tester,
        router: router,
        widget: const SizedBox(), // Ignored
      );

      await tester.tap(find.text('Add Transaction'));
      await tester.pumpAndSettle();

      expect(pushed, isTrue);
    });

    testWidgets('renders a list of TransactionListItems', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await pumpWidgetWithProviders(
          tester: tester,
          widget: buildTestWidget(TransactionListState(
              status: ListStatus.success, transactions: mockTransactions)));
      expect(find.byType(TransactionListItem), findsNWidgets(2));
    });

    testWidgets('"View All" button navigates', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool pushed = false;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => buildTestWidget(
                const TransactionListState(
                    status: ListStatus.success, transactions: [])),
          ),
          GoRoute(
            path: '/transactions',
            // The code uses context.go(RouteNames.transactionsList)
            // RouteNames.transactionsList is '/transactions'
            // In GoRouter, context.go('/transactions') matches path.
            // If it was pushNamed, it would match name.
            // RouteNames defines transactionsList = '/transactions'.
            builder: (context, state) {
              pushed = true;
              return const SizedBox();
            },
          ),
        ],
      );

      await pumpWidgetWithProviders(
        tester: tester,
        router: router,
        widget: const SizedBox(), // Ignored
      );

      // Scroll to find the button
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('button_recentTransactions_viewAll')),
        500.0,
      );

      await tester
          .tap(find.byKey(const ValueKey('button_recentTransactions_viewAll')));
      await tester.pumpAndSettle();

      expect(pushed, isTrue);
    });

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
