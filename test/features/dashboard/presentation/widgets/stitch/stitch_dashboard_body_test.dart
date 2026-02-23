import 'package:expense_tracker/features/dashboard/presentation/widgets/stitch/stitch_dashboard_body.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../helpers/pump_app.dart';
import 'package:bloc_test/bloc_test.dart';

class MockTransactionListBloc
    extends MockBloc<TransactionListEvent, TransactionListState>
    implements TransactionListBloc {}

class MockGoalListBloc extends MockBloc<GoalListEvent, GoalListState>
    implements GoalListBloc {}

void main() {
  late MockTransactionListBloc mockTransactionListBloc;
  late MockGoalListBloc mockGoalListBloc;

  setUp(() {
    mockTransactionListBloc = MockTransactionListBloc();
    mockGoalListBloc = MockGoalListBloc();

    when(
      () => mockTransactionListBloc.state,
    ).thenReturn(const TransactionListState(status: ListStatus.success));
    when(() => mockGoalListBloc.state).thenReturn(const GoalListState(status: GoalListStatus.success));
  });

  testWidgets('StitchDashboardBody renders correctly', (tester) async {
    final overview = FinancialOverview(
      overallBalance: 1000,
      totalIncome: 2000,
      totalExpenses: 1000,
      netFlow: 1000,
      accounts: [],
      accountBalances: {},
      activeBudgetsSummary: [],
      activeGoalsSummary: [],
      recentSpendingSparkline: [],
      recentContributionSparkline: [],
    );

    await pumpWidgetWithProviders(
      tester: tester,
      widget: StitchDashboardBody(
        overview: overview,
        navigateToDetailOrEdit: (_, __) {},
        onRefresh: () async {},
      ),
      blocProviders: [
        BlocProvider<TransactionListBloc>.value(value: mockTransactionListBloc),
        BlocProvider<GoalListBloc>.value(value: mockGoalListBloc),
      ],
    );

    expect(find.byType(CustomScrollView), findsOneWidget);
  });
}
