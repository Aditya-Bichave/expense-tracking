import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/income_expense_report/income_expense_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/pages/income_vs_expense_page.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/income_expense_bar_chart.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockIncomeExpenseReportBloc
    extends MockBloc<IncomeExpenseReportEvent, IncomeExpenseReportState>
    implements IncomeExpenseReportBloc {}

class MockReportFilterBloc
    extends MockBloc<ReportFilterEvent, ReportFilterState>
    implements ReportFilterBloc {}

class MockCsvExportHelper extends Mock implements CsvExportHelper {}

class _FakeIncomeExpenseReportEvent extends Fake
    implements IncomeExpenseReportEvent {}

class _FakeIncomeExpenseReportData extends Fake
    implements IncomeExpenseReportData {}

void main() {
  late MockIncomeExpenseReportBloc reportBloc;
  late MockReportFilterBloc filterBloc;
  late MockCsvExportHelper csvHelper;

  IncomeExpensePeriodData period(
    DateTime start,
    double income,
    double expense, {
    double? prevIncome,
    double? prevExpense,
  }) => IncomeExpensePeriodData(
    periodStart: start,
    totalIncome: ComparisonValue(
      currentValue: income,
      previousValue: prevIncome,
    ),
    totalExpense: ComparisonValue(
      currentValue: expense,
      previousValue: prevExpense,
    ),
  );

  IncomeExpenseReportData data({
    List<IncomeExpensePeriodData>? periods,
    IncomeExpensePeriodType periodType = IncomeExpensePeriodType.monthly,
  }) => IncomeExpenseReportData(
    periodData:
        periods ??
        [
          period(DateTime(2024, 3, 1), 500, 200),
          period(DateTime(2024, 4, 1), 450, 400),
        ],
    periodType: periodType,
  );

  setUpAll(() {
    registerFallbackValue(_FakeIncomeExpenseReportEvent());
    registerFallbackValue(_FakeIncomeExpenseReportData());
  });

  setUp(() async {
    await sl.reset();
    reportBloc = MockIncomeExpenseReportBloc();
    filterBloc = MockReportFilterBloc();
    csvHelper = MockCsvExportHelper();

    sl.registerSingleton<CsvExportHelper>(csvHelper);

    when(() => filterBloc.state).thenReturn(ReportFilterState.initial());
    when(() => reportBloc.state).thenReturn(IncomeExpenseReportInitial());
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> pumpPage(WidgetTester tester, {bool settle = true}) async {
    await pumpWidgetWithProviders(
      tester: tester,
      settle: settle,
      widget: const IncomeVsExpensePage(),
      blocProviders: [
        BlocProvider<IncomeExpenseReportBloc>.value(value: reportBloc),
        BlocProvider<ReportFilterBloc>.value(value: filterBloc),
      ],
    );
    if (!settle) await tester.pump();
  }

  group('states', () {
    testWidgets('initial state prompts for filters', (tester) async {
      await pumpPage(tester);

      expect(find.text('Select filters to view report.'), findsOneWidget);
      expect(find.byType(IncomeExpenseBarChart), findsNothing);
    });

    testWidgets('loading shows the spinner', (tester) async {
      when(() => reportBloc.state).thenReturn(
        const IncomeExpenseReportLoading(
          periodType: IncomeExpensePeriodType.monthly,
          compareToPrevious: false,
        ),
      );

      await pumpPage(tester, settle: false);

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
    });

    testWidgets('error shows the failure message', (tester) async {
      when(
        () => reportBloc.state,
      ).thenReturn(const IncomeExpenseReportError('Ledger unavailable'));

      await pumpPage(tester);

      expect(find.text('Error: Ledger unavailable'), findsOneWidget);
    });

    testWidgets('an empty report shows the empty message', (tester) async {
      when(() => reportBloc.state).thenReturn(
        IncomeExpenseReportLoaded(
          data(periods: const []),
          showComparison: false,
        ),
      );

      await pumpPage(tester);

      expect(
        find.text('No income or expense data for this period.'),
        findsOneWidget,
      );
      expect(find.byType(IncomeExpenseBarChart), findsNothing);
    });

    testWidgets('a loaded report renders the chart and the data table', (
      tester,
    ) async {
      when(
        () => reportBloc.state,
      ).thenReturn(IncomeExpenseReportLoaded(data(), showComparison: false));

      await pumpPage(tester);

      expect(find.byType(IncomeExpenseBarChart), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Period'), findsOneWidget);
    });
  });

  group('period headers', () {
    testWidgets('monthly rows use a month-year header', (tester) async {
      when(() => reportBloc.state).thenReturn(
        IncomeExpenseReportLoaded(
          data(periods: [period(DateTime(2024, 3, 1), 10, 5)]),
          showComparison: false,
        ),
      );

      await pumpPage(tester);

      expect(
        find.descendant(
          of: find.byType(DataTable),
          matching: find.text('Mar 2024'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('yearly rows collapse to the year', (tester) async {
      when(() => reportBloc.state).thenReturn(
        IncomeExpenseReportLoaded(
          data(
            periods: [period(DateTime(2024, 1, 1), 10, 5)],
            periodType: IncomeExpensePeriodType.yearly,
          ),
          showComparison: false,
        ),
      );

      await pumpPage(tester);

      // The chart axis also renders '2024', so scope to the table row.
      expect(
        find.descendant(
          of: find.byType(DataTable),
          matching: find.text('2024'),
        ),
        findsOneWidget,
      );
    });
  });

  group('comparison toggle', () {
    testWidgets('toggling reloads with the loaded period type', (tester) async {
      when(() => reportBloc.state).thenReturn(
        IncomeExpenseReportLoaded(
          data(periodType: IncomeExpensePeriodType.yearly),
          showComparison: false,
        ),
      );

      await pumpPage(tester);
      await tester.tap(find.byIcon(Icons.compare_arrows_outlined));
      await tester.pumpAndSettle();

      final event =
          verify(() => reportBloc.add(captureAny())).captured.last
              as LoadIncomeExpenseReport;
      expect(event.compareToPrevious, isTrue);
      expect(event.periodType, IncomeExpensePeriodType.yearly);
      expect(find.byIcon(Icons.compare_arrows_rounded), findsOneWidget);
    });

    testWidgets('toggling from loading keeps that period type', (tester) async {
      when(() => reportBloc.state).thenReturn(
        const IncomeExpenseReportLoading(
          periodType: IncomeExpensePeriodType.yearly,
          compareToPrevious: false,
        ),
      );

      await pumpPage(tester, settle: false);
      await tester.tap(find.byIcon(Icons.compare_arrows_outlined));
      await tester.pump();

      final event =
          verify(() => reportBloc.add(captureAny())).captured.last
              as LoadIncomeExpenseReport;
      expect(event.periodType, IncomeExpensePeriodType.yearly);
    });

    testWidgets('toggling from initial falls back to monthly', (tester) async {
      await pumpPage(tester);
      await tester.tap(find.byIcon(Icons.compare_arrows_outlined));
      await tester.pumpAndSettle();

      final event =
          verify(() => reportBloc.add(captureAny())).captured.last
              as LoadIncomeExpenseReport;
      expect(event.periodType, IncomeExpensePeriodType.monthly);
    });

    testWidgets('comparison mode widens the table with previous columns', (
      tester,
    ) async {
      when(() => reportBloc.state).thenReturn(
        IncomeExpenseReportLoaded(
          data(
            periods: [
              period(
                DateTime(2024, 3, 1),
                500,
                200,
                prevIncome: 400,
                prevExpense: 300,
              ),
            ],
          ),
          showComparison: true,
        ),
      );

      await pumpPage(tester);
      // Turn comparison on so the table builds its extra columns.
      await tester.tap(find.byIcon(Icons.compare_arrows_outlined));
      await tester.pumpAndSettle();

      final table = tester.widget<DataTable>(find.byType(DataTable));
      expect(table.columns.length, greaterThan(4));
    });
  });

  group('period aggregation menu', () {
    testWidgets('selecting a period type reloads the report', (tester) async {
      when(
        () => reportBloc.state,
      ).thenReturn(IncomeExpenseReportLoaded(data(), showComparison: false));

      await pumpPage(tester);
      await tester.tap(find.byIcon(Icons.calendar_view_month_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yearly').last);
      await tester.pumpAndSettle();

      final event =
          verify(() => reportBloc.add(captureAny())).captured.last
              as LoadIncomeExpenseReport;
      expect(event.periodType, IncomeExpensePeriodType.yearly);
    });
  });

  group('CSV export', () {
    testWidgets('exports the loaded report through the helper', (tester) async {
      final reportData = data();
      when(() => reportBloc.state).thenReturn(
        IncomeExpenseReportLoaded(reportData, showComparison: false),
      );
      when(
        () => csvHelper.exportIncomeExpenseReport(
          any(),
          any(),
          showComparison: any(named: 'showComparison'),
        ),
      ).thenAnswer((_) async => const dartz.Left('period,income,expense'));

      await pumpPage(tester);
      await tester.tap(find.byIcon(Icons.download_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export as CSV'));
      await tester.pumpAndSettle();

      verify(
        () => csvHelper.exportIncomeExpenseReport(
          reportData,
          any(),
          showComparison: false,
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
        () => csvHelper.exportIncomeExpenseReport(
          any(),
          any(),
          showComparison: any(named: 'showComparison'),
        ),
      );
    });
  });
}
