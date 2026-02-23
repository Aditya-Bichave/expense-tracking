import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/recent_transactions_section.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/stitch/stitch_dashboard_body.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/mocks.dart';

void main() {
  late MockSettingsBloc mockSettingsBloc;
  late MockTransactionListBloc mockTransactionListBloc;
  late MockAccountListBloc mockAccountListBloc;

  setUp(() {
    mockSettingsBloc = MockSettingsBloc();
    mockTransactionListBloc = MockTransactionListBloc();
    mockAccountListBloc = MockAccountListBloc();

    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(
      () => mockSettingsBloc.stream,
    ).thenAnswer((_) => Stream<SettingsState>.empty().asBroadcastStream());

    when(
      () => mockTransactionListBloc.state,
    ).thenReturn(const TransactionListState());
    when(() => mockTransactionListBloc.stream).thenAnswer(
      (_) => Stream<TransactionListState>.empty().asBroadcastStream(),
    );

    when(
      () => mockAccountListBloc.state,
    ).thenReturn(const AccountListLoaded(accounts: []));
    when(
      () => mockAccountListBloc.stream,
    ).thenAnswer((_) => Stream<AccountListState>.empty().asBroadcastStream());

    if (!sl.isRegistered<AccountListBloc>()) {
      sl.registerFactory<AccountListBloc>(() => mockAccountListBloc);
    }
  });

  tearDown(() {
    if (sl.isRegistered<AccountListBloc>()) {
      sl.unregister<AccountListBloc>();
    }
  });

  testWidgets('StitchDashboardBody renders', (tester) async {
    final overview = FinancialOverview(
      totalIncome: 0,
      totalExpenses: 0,
      netFlow: 0,
      overallBalance: 0,
      accounts: [],
      accountBalances: {},
      activeBudgetsSummary: [],
      activeGoalsSummary: [],
      recentSpendingSparkline: [],
      recentContributionSparkline: [],
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
            body: StitchDashboardBody(
              overview: overview,
              navigateToDetailOrEdit: (_, __) {},
              onRefresh: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(StitchDashboardBody), findsOneWidget);
    // Deep assertion for child components
    expect(find.byType(RecentTransactionsSection), findsOneWidget);
  });
}
