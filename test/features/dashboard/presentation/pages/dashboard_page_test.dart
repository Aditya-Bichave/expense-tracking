import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/asset_distribution_section.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/budget_summary_widget.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockFinancialOverview extends Mock implements FinancialOverview {}

void main() {
  late DashboardBloc mockDashboardBloc;
  late SettingsBloc mockSettingsBloc;
  late MockGoRouter mockGoRouter;
  late FinancialOverview mockOverview;

  setUp(() {
    mockDashboardBloc = MockDashboardBloc();
    mockSettingsBloc = MockSettingsBloc();
    mockGoRouter = MockGoRouter();
    mockOverview = MockFinancialOverview();

    when(() => mockOverview.accountBalances).thenReturn({});
    when(() => mockOverview.activeBudgetsSummary).thenReturn([]);
    when(() => mockOverview.activeGoalsSummary).thenReturn([]);
    when(() => mockOverview.recentSpendingSparkline).thenReturn([]);
    when(() => mockOverview.recentContributionSparkline).thenReturn([]);
  });

  Widget buildTestWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: mockDashboardBloc),
        BlocProvider.value(value: mockSettingsBloc),
      ],
      child: const DashboardPage(),
    );
  }

  group('DashboardPage', () {
    testWidgets('shows loading indicator when state is DashboardLoading',
        (tester) async {
      when(() => mockDashboardBloc.state).thenReturn(DashboardLoading());
      when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error and retry button when state is DashboardError',
        (tester) async {
      when(() => mockDashboardBloc.state)
          .thenReturn(const DashboardError('Failed'));
      when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());

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
      when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());

      expect(find.byType(AssetDistributionSection), findsOneWidget);
      expect(find.byType(BudgetSummaryWidget), findsOneWidget);
    });

    testWidgets('report navigation buttons push correct routes',
        (tester) async {
      when(() => mockDashboardBloc.state)
          .thenReturn(DashboardLoaded(mockOverview));
      when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
      when(() => mockGoRouter.push(any())).thenAnswer((_) async {});

      await pumpWidgetWithProviders(
          tester: tester, widget: buildTestWidget(), router: mockGoRouter);

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
