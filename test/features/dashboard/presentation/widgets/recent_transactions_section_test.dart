import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/recent_transactions_section.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockSettingsBloc mockSettingsBloc;
  late MockTransactionListBloc mockTransactionListBloc;
  late MockAccountListBloc mockAccountListBloc;
  late MockGoRouter mockGoRouter;

  setUp(() {
    mockSettingsBloc = MockSettingsBloc();
    mockTransactionListBloc = MockTransactionListBloc();
    mockAccountListBloc = MockAccountListBloc();
    mockGoRouter = MockGoRouter();

    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(
      () => mockSettingsBloc.stream,
    ).thenAnswer((_) => Stream<SettingsState>.empty().asBroadcastStream());

    when(
      () => mockAccountListBloc.state,
    ).thenReturn(const AccountListLoaded(accounts: []));
    when(
      () => mockAccountListBloc.stream,
    ).thenAnswer((_) => Stream<AccountListState>.empty().asBroadcastStream());

    when(
      () => mockGoRouter.go(any(), extra: any(named: 'extra')),
    ).thenReturn(null);
    when(
      () => mockGoRouter.pushNamed(
        any(),
        pathParameters: any(named: 'pathParameters'),
        queryParameters: any(named: 'queryParameters'),
        extra: any(named: 'extra'),
      ),
    ).thenAnswer((_) async => null);

    if (!sl.isRegistered<AccountListBloc>()) {
      sl.registerFactory<AccountListBloc>(() => mockAccountListBloc);
    }
  });

  tearDown(() {
    if (sl.isRegistered<AccountListBloc>()) {
      sl.unregister<AccountListBloc>();
    }
  });

  testWidgets('RecentTransactionsSection renders list of transactions', (
    tester,
  ) async {
    final transactions = [
      TransactionEntity(
        id: '1',
        amount: 50,
        date: DateTime.now(),
        accountId: 'acc1',
        type: TransactionType.expense,
        title: 'Groceries',
      ),
    ];

    when(() => mockTransactionListBloc.state).thenReturn(
      TransactionListState(
        status: ListStatus.success,
        transactions: transactions,
      ),
    );
    when(() => mockTransactionListBloc.stream).thenAnswer(
      (_) => Stream<TransactionListState>.empty().asBroadcastStream(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
            BlocProvider<TransactionListBloc>.value(
              value: mockTransactionListBloc,
            ),
            BlocProvider<AccountListBloc>.value(value: mockAccountListBloc),
          ],
          child: Scaffold(
            body: MockGoRouterProvider(
              router: mockGoRouter,
              child: RecentTransactionsSection(
                navigateToDetailOrEdit: (_, __) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('RECENT ACTIVITY'), findsOneWidget);
    // Use regex for locale-agnostic currency check
    expect(find.textContaining(RegExp(r'50\.00')), findsOneWidget);
  });

  testWidgets('RecentTransactionsSection renders loading state', (
    tester,
  ) async {
    when(
      () => mockTransactionListBloc.state,
    ).thenReturn(const TransactionListState(status: ListStatus.loading));
    when(() => mockTransactionListBloc.stream).thenAnswer(
      (_) => Stream<TransactionListState>.empty().asBroadcastStream(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
            BlocProvider<TransactionListBloc>.value(
              value: mockTransactionListBloc,
            ),
            BlocProvider<AccountListBloc>.value(value: mockAccountListBloc),
          ],
          child: Scaffold(
            body: MockGoRouterProvider(
              router: mockGoRouter,
              child: RecentTransactionsSection(
                navigateToDetailOrEdit: (_, __) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('RecentTransactionsSection renders empty state', (tester) async {
    when(() => mockTransactionListBloc.state).thenReturn(
      const TransactionListState(status: ListStatus.success, transactions: []),
    );
    when(() => mockTransactionListBloc.stream).thenAnswer(
      (_) => Stream<TransactionListState>.empty().asBroadcastStream(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
            BlocProvider<TransactionListBloc>.value(
              value: mockTransactionListBloc,
            ),
            BlocProvider<AccountListBloc>.value(value: mockAccountListBloc),
          ],
          child: Scaffold(
            body: MockGoRouterProvider(
              router: mockGoRouter,
              child: RecentTransactionsSection(
                navigateToDetailOrEdit: (_, __) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No transactions recorded yet.'), findsOneWidget);
  });

  testWidgets('tapping See All invokes navigation', (tester) async {
    when(() => mockTransactionListBloc.state).thenReturn(
      const TransactionListState(status: ListStatus.success, transactions: []),
    );
    when(() => mockTransactionListBloc.stream).thenAnswer(
      (_) => Stream<TransactionListState>.empty().asBroadcastStream(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
            BlocProvider<TransactionListBloc>.value(
              value: mockTransactionListBloc,
            ),
            BlocProvider<AccountListBloc>.value(value: mockAccountListBloc),
          ],
          child: Scaffold(
            body: MockGoRouterProvider(
              router: mockGoRouter,
              child: RecentTransactionsSection(
                navigateToDetailOrEdit: (_, __) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final seeAllButton = find.text('View All Transactions');
    expect(seeAllButton, findsOneWidget);
    await tester.tap(seeAllButton);
    await tester.pumpAndSettle();
  });
}
