import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/asset_distribution_section.dart';
import 'package:expense_tracker/core/di/service_configurations/dashboard_dependencies.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/budget_summary_widget.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  late MockDashboardBloc mockDashboardBloc;
  late MockSettingsBloc mockSettingsBloc;
  late MockTransactionListBloc mockTransactionListBloc;
  late MockGoRouter mockGoRouter;
  late FinancialOverview mockOverview;

  setUpAll(() {
    DashboardDependencies.register();
  });

  setUp(() {
    mockDashboardBloc = MockDashboardBloc();
    mockSettingsBloc = MockSettingsBloc();
    mockTransactionListBloc = MockTransactionListBloc();
    mockGoRouter = MockGoRouter();
    mockOverview = MockFinancialOverview();

    when(() => mockOverview.accountBalances).thenReturn({});
    when(() => mockOverview.activeBudgetsSummary).thenReturn([]);
    when(() => mockOverview.activeGoalsSummary).thenReturn([]);
    when(() => mockOverview.recentSpendingSparkline).thenReturn([]);
    when(() => mockOverview.recentContributionSparkline).thenReturn([]);
    when(() => mockOverview.overallBalance).thenReturn(0);
  });

  group('DashboardPage', () {
    testWidgets('shows loading indicator when state is DashboardLoading',
        (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        dashboardBloc: mockDashboardBloc,
        settingsBloc: mockSettingsBloc,
        transactionListBloc: mockTransactionListBloc,
        widget: const DashboardPage(),
        settle: false,
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error and retry button when state is DashboardError',
        (tester) async {
      when(() => mockDashboardBloc.state)
          .thenReturn(const DashboardError('Failed'));
      await pumpWidgetWithProviders(
        tester: tester,
        dashboardBloc: mockDashboardBloc,
        settingsBloc: mockSettingsBloc,
        transactionListBloc: mockTransactionListBloc,
        widget: const DashboardPage(),
      );

      expect(find.text('Error loading dashboard: Failed'), findsOneWidget);
      final retryButton = find.byKey(const ValueKey('button_dashboard_retry'));
      expect(retryButton, findsOneWidget);

      await tester.tap(retryButton);
      verify(() =>
              mockDashboardBloc.add(const LoadDashboard(forceReload: true)))
          .called(1);
    });

    testWidgets('renders dashboard sections when state is DashboardLoaded',
        (tester) async {
      when(() => mockDashboardBloc.state)
          .thenReturn(DashboardLoaded(mockOverview));
      await pumpWidgetWithProviders(
        tester: tester,
        dashboardBloc: mockDashboardBloc,
        settingsBloc: mockSettingsBloc,
        transactionListBloc: mockTransactionListBloc,
        widget: const DashboardPage(),
      );

      expect(find.byType(AssetDistributionSection), findsOneWidget);
      expect(find.byType(BudgetSummaryWidget), findsOneWidget);
    });

    testWidgets('report navigation buttons push correct routes',
        (tester) async {
      when(() => mockDashboardBloc.state)
          .thenReturn(DashboardLoaded(mockOverview));
      when(() => mockGoRouter.push(any())).thenAnswer((_) async => null);

      await pumpWidgetWithProviders(
        tester: tester,
        dashboardBloc: mockDashboardBloc,
        settingsBloc: mockSettingsBloc,
        transactionListBloc: mockTransactionListBloc,
        router: mockGoRouter,
        widget: const DashboardPage(),
      );

      final button = find
          .byKey(const ValueKey('button_dashboard_to_spendingCategoryReport'));
      expect(button, findsOneWidget);

      await tester.tap(button);

      verify(() => mockGoRouter.push(
              '${RouteNames.dashboard}/${RouteNames.reportSpendingCategory}'))
          .called(1);
    });
  });
}
