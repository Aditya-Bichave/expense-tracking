import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/budget_performance_report/budget_performance_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/pages/budget_performance_page.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/budget_performance_bar_chart.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockBudgetPerformanceReportBloc
    extends MockBloc<BudgetPerformanceReportEvent, BudgetPerformanceReportState>
    implements BudgetPerformanceReportBloc {}

class MockReportFilterBloc
    extends MockBloc<ReportFilterEvent, ReportFilterState>
    implements ReportFilterBloc {}

class MockCsvExportHelper extends Mock implements CsvExportHelper {}

class _FakeBudgetPerformanceReportEvent extends Fake
    implements BudgetPerformanceReportEvent {}

class _FakeBudgetPerformanceReportData extends Fake
    implements BudgetPerformanceReportData {}

void main() {
  late MockBudgetPerformanceReportBloc reportBloc;
  late MockReportFilterBloc filterBloc;
  late MockCsvExportHelper csvHelper;

  Budget budget(String id, String name, double target) => Budget(
    id: id,
    name: name,
    type: BudgetType.overall,
    targetAmount: target,
    period: BudgetPeriodType.recurringMonthly,
    createdAt: DateTime(2024, 1, 1),
  );

  BudgetPerformanceData perf(
    String id,
    String name, {
    double target = 500,
    double actual = 400,
    double variance = 100,
    double variancePercent = 20,
  }) => BudgetPerformanceData(
    budget: budget(id, name, target),
    actualSpending: ComparisonValue(currentValue: actual),
    varianceAmount: ComparisonValue(currentValue: variance),
    currentVariancePercent: variancePercent,
    health: BudgetHealth.thriving,
    statusColor: Colors.green,
  );

  BudgetPerformanceReportData data({
    List<BudgetPerformanceData>? current,
    List<BudgetPerformanceData>? previous,
  }) => BudgetPerformanceReportData(
    performanceData: current ?? [perf('b1', 'Groceries')],
    previousPerformanceData: previous,
  );

  setUpAll(() {
    registerFallbackValue(_FakeBudgetPerformanceReportEvent());
    registerFallbackValue(_FakeBudgetPerformanceReportData());
  });

  setUp(() async {
    await sl.reset();
    reportBloc = MockBudgetPerformanceReportBloc();
    filterBloc = MockReportFilterBloc();
    csvHelper = MockCsvExportHelper();

    sl.registerSingleton<CsvExportHelper>(csvHelper);

    when(() => filterBloc.state).thenReturn(ReportFilterState.initial());
    when(() => reportBloc.state).thenReturn(BudgetPerformanceReportInitial());
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> pumpPage(WidgetTester tester, {bool settle = true}) async {
    await pumpWidgetWithProviders(
      tester: tester,
      settle: settle,
      widget: const BudgetPerformancePage(),
      blocProviders: [
        BlocProvider<BudgetPerformanceReportBloc>.value(value: reportBloc),
        BlocProvider<ReportFilterBloc>.value(value: filterBloc),
      ],
    );
    if (!settle) await tester.pump();
  }

  group('states', () {
    testWidgets('initial state prompts for filters', (tester) async {
      await pumpPage(tester);

      expect(find.text('Select filters to view report.'), findsOneWidget);
      expect(find.byType(BudgetPerformanceBarChart), findsNothing);
    });

    testWidgets('loading shows the spinner', (tester) async {
      when(() => reportBloc.state).thenReturn(
        const BudgetPerformanceReportLoading(compareToPrevious: false),
      );

      await pumpPage(tester, settle: false);

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
    });

    testWidgets('error shows the failure message', (tester) async {
      when(
        () => reportBloc.state,
      ).thenReturn(const BudgetPerformanceReportError('Budgets unavailable'));

      await pumpPage(tester);

      expect(find.text('Error: Budgets unavailable'), findsOneWidget);
    });

    testWidgets('a loaded report with no budgets shows the empty message', (
      tester,
    ) async {
      when(() => reportBloc.state).thenReturn(
        BudgetPerformanceReportLoaded(
          data(current: const []),
          showComparison: false,
        ),
      );

      await pumpPage(tester);

      expect(find.byType(BudgetPerformanceBarChart), findsNothing);
      expect(find.byType(DataTable), findsNothing);
    });

    testWidgets('a loaded report renders the chart and the table', (
      tester,
    ) async {
      when(() => reportBloc.state).thenReturn(
        BudgetPerformanceReportLoaded(data(), showComparison: false),
      );

      await pumpPage(tester);

      expect(find.byType(BudgetPerformanceBarChart), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DataTable),
          matching: find.text('Groceries'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('one table row per budget', (tester) async {
      when(() => reportBloc.state).thenReturn(
        BudgetPerformanceReportLoaded(
          data(
            current: [
              perf('b1', 'Groceries'),
              perf('b2', 'Transport'),
              perf('b3', 'Utilities'),
            ],
          ),
          showComparison: false,
        ),
      );

      await pumpPage(tester);

      final table = tester.widget<DataTable>(find.byType(DataTable));
      expect(table.rows, hasLength(3));
    });
  });

  group('comparison toggle', () {
    testWidgets('is disabled when there is no previous period to compare', (
      tester,
    ) async {
      when(() => reportBloc.state).thenReturn(
        BudgetPerformanceReportLoaded(data(), showComparison: false),
      );

      await pumpPage(tester);

      final button = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.compare_arrows_outlined),
          matching: find.byType(IconButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('is disabled in the initial state', (tester) async {
      await pumpPage(tester);

      final button = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.compare_arrows_outlined),
          matching: find.byType(IconButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('is enabled once previous-period data exists and dispatches', (
      tester,
    ) async {
      when(() => reportBloc.state).thenReturn(
        BudgetPerformanceReportLoaded(
          data(previous: [perf('b1', 'Groceries', actual: 450)]),
          showComparison: false,
        ),
      );

      await pumpPage(tester);
      await tester.tap(find.byIcon(Icons.compare_arrows_outlined));
      await tester.pump();

      verify(() => reportBloc.add(const ToggleBudgetComparison())).called(1);
    });

    testWidgets('shows the active icon while comparison is on', (tester) async {
      when(() => reportBloc.state).thenReturn(
        BudgetPerformanceReportLoaded(
          data(previous: [perf('b1', 'Groceries', actual: 450)]),
          showComparison: true,
        ),
      );

      await pumpPage(tester);

      expect(find.byIcon(Icons.compare_arrows_rounded), findsOneWidget);
      expect(find.byIcon(Icons.compare_arrows_outlined), findsNothing);
    });

    testWidgets('comparison widens the table with previous-period columns', (
      tester,
    ) async {
      when(() => reportBloc.state).thenReturn(
        BudgetPerformanceReportLoaded(
          data(previous: [perf('b1', 'Groceries', actual: 450)]),
          showComparison: true,
        ),
      );

      await pumpPage(tester);

      final table = tester.widget<DataTable>(find.byType(DataTable));
      expect(table.columns.length, greaterThan(4));
    });
  });

  group('CSV export', () {
    testWidgets('exports the loaded report, honouring the comparison flag', (
      tester,
    ) async {
      final reportData = data(previous: [perf('b1', 'Groceries', actual: 450)]);
      when(() => reportBloc.state).thenReturn(
        BudgetPerformanceReportLoaded(reportData, showComparison: true),
      );
      when(
        () => csvHelper.exportBudgetPerformanceReport(
          any(),
          any(),
          showComparison: any(named: 'showComparison'),
        ),
      ).thenAnswer((_) async => const dartz.Left('budget,target,actual'));

      await pumpPage(tester);
      await tester.tap(find.byIcon(Icons.download_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export as CSV'));
      await tester.pumpAndSettle();

      verify(
        () => csvHelper.exportBudgetPerformanceReport(
          reportData,
          any(),
          showComparison: true,
        ),
      ).called(1);
    });

    testWidgets('exporting before the report loads never calls the helper', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.tap(find.byIcon(Icons.download_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export as CSV'));
      await tester.pumpAndSettle();

      verifyNever(
        () => csvHelper.exportBudgetPerformanceReport(
          any(),
          any(),
          showComparison: any(named: 'showComparison'),
        ),
      );
    });
  });
}
