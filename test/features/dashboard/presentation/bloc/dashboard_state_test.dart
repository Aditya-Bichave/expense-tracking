import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardState', () {
    test('DashboardInitial supports value comparisons', () {
      expect(DashboardInitial(), equals(DashboardInitial()));
    });

    test('DashboardLoading supports value comparisons', () {
      expect(const DashboardLoading(), equals(const DashboardLoading()));
      expect(
        const DashboardLoading(isReloading: true),
        equals(const DashboardLoading(isReloading: true)),
      );
      expect(
        const DashboardLoading(),
        isNot(equals(const DashboardLoading(isReloading: true))),
      );
    });

    test('DashboardLoaded supports value comparisons', () {
      const overview1 = FinancialOverview(
        totalIncome: 150,
        totalExpenses: 50,
        netFlow: 100,
        overallBalance: 1000,
        accounts: [],
        accountBalances: {},
        activeBudgetsSummary: [],
        activeGoalsSummary: [],
        recentSpendingSparkline: [],
        recentContributionSparkline: [],
      );
      const overview2 = FinancialOverview(
        totalIncome: 150,
        totalExpenses: 50,
        netFlow: 100,
        overallBalance: 1000,
        accounts: [],
        accountBalances: {},
        activeBudgetsSummary: [],
        activeGoalsSummary: [],
        recentSpendingSparkline: [],
        recentContributionSparkline: [],
      );
      const overview3 = FinancialOverview(
        totalIncome: 300,
        totalExpenses: 100,
        netFlow: 200,
        overallBalance: 2000,
        accounts: [],
        accountBalances: {},
        activeBudgetsSummary: [],
        activeGoalsSummary: [],
        recentSpendingSparkline: [],
        recentContributionSparkline: [],
      );

      expect(DashboardLoaded(overview1), equals(DashboardLoaded(overview2)));
      expect(
        DashboardLoaded(overview1),
        isNot(equals(DashboardLoaded(overview3))),
      );
    });

    test('DashboardError supports value comparisons', () {
      expect(
        const DashboardError('error'),
        equals(const DashboardError('error')),
      );
      expect(
        const DashboardError('error1'),
        isNot(equals(const DashboardError('error2'))),
      );
    });
  });

  group('DashboardEvent', () {
    test('LoadDashboard supports value comparisons', () {
      final date1 = DateTime(2023, 1, 1);
      final date2 = DateTime(2023, 1, 31);
      expect(
        LoadDashboard(startDate: date1, endDate: date2, forceReload: true),
        equals(
          LoadDashboard(startDate: date1, endDate: date2, forceReload: true),
        ),
      );
      expect(
        LoadDashboard(startDate: date1, endDate: date2, forceReload: true),
        isNot(
          equals(
            LoadDashboard(startDate: date1, endDate: date2, forceReload: false),
          ),
        ),
      );
    });

    test('ResetState supports value comparisons', () {
      expect(const ResetState(), equals(const ResetState()));
    });
  });
}
