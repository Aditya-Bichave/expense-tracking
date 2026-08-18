import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_time_report/spending_time_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/pages/spending_over_time_page.dart';
import 'package:expense_tracker/features/reports/presentation/widgets/charts/time_series_line_chart.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockSpendingTimeReportBloc
    extends MockBloc<SpendingTimeReportEvent, SpendingTimeReportState>
    implements SpendingTimeReportBloc {}

class MockReportFilterBloc
    extends MockBloc<ReportFilterEvent, ReportFilterState>
    implements ReportFilterBloc {}

class MockCsvExportHelper extends Mock implements CsvExportHelper {}

class _FakeSpendingTimeReportEvent extends Fake
    implements SpendingTimeReportEvent {}

class _FakeSpendingTimeReportData extends Fake
    implements SpendingTimeReportData {}

void main() {
  late MockSpendingTimeReportBloc reportBloc;
  late MockReportFilterBloc filterBloc;
  late MockCsvExportHelper csvHelper;

  TimeSeriesDataPoint point(DateTime d, double current, [double? previous]) =>
      TimeSeriesDataPoint(
        date: d,
        amount: ComparisonValue(currentValue: current, previousValue: previous),
      );

  SpendingTimeReportData data({
    List<TimeSeriesDataPoint>? points,
    TimeSeriesGranularity granularity = TimeSeriesGranularity.daily,
  }) => SpendingTimeReportData(
    spendingData:
        points ??
        [point(DateTime(2024, 3, 1), 40), point(DateTime(2024, 3, 2), 25.5)],
    granularity: granularity,
  );

  setUpAll(() {
    registerFallbackValue(_FakeSpendingTimeReportEvent());
    registerFallbackValue(_FakeSpendingTimeReportData());
  });

  setUp(() async {
    await sl.reset();
    reportBloc = MockSpendingTimeReportBloc();
    filterBloc = MockReportFilterBloc();
    csvHelper = MockCsvExportHelper();

    sl.registerSingleton<CsvExportHelper>(csvHelper);

    when(() => filterBloc.state).thenReturn(ReportFilterState.initial());
    when(() => reportBloc.state).thenReturn(SpendingTimeReportInitial());
  });

  tearDown(() async {
    await sl.reset();
  });

  Future<void> pumpPage(WidgetTester tester, {bool settle = true}) async {
    await pumpWidgetWithProviders(
      tester: tester,
      settle: settle,
      widget: const SpendingOverTimePage(),
      blocProviders: [
        BlocProvider<SpendingTimeReportBloc>.value(value: reportBloc),
        BlocProvider<ReportFilterBloc>.value(value: filterBloc),
      ],
    );
    if (!settle) await tester.pump();
  }

  group('states', () {
    testWidgets('initial state prompts the user to pick filters', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('Select filters to view report.'), findsOneWidget);
      expect(find.byType(TimeSeriesLineChart), findsNothing);
    });

    testWidgets('loading shows the spinner and no chart', (tester) async {
      when(() => reportBloc.state).thenReturn(
        const SpendingTimeReportLoading(
          granularity: TimeSeriesGranularity.monthly,
          compareToPrevious: false,
        ),
      );

      await pumpPage(tester, settle: false);

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
      expect(find.byType(TimeSeriesLineChart), findsNothing);
    });

    testWidgets('error shows the failure message', (tester) async {
      when(
        () => reportBloc.state,
      ).thenReturn(const SpendingTimeReportError('Report source unavailable'));

      await pumpPage(tester);

      expect(find.text('Error: Report source unavailable'), findsOneWidget);
    });

    testWidgets('a loaded but empty report shows the empty message', (
      tester,
    ) async {
      when(() => reportBloc.state).thenReturn(
        SpendingTimeReportLoaded(data(points: const []), showComparison: false),
      );

      await pumpPage(tester);

      expect(find.text('No spending data for this period.'), findsOneWidget);
      expect(find.byType(TimeSeriesLineChart), findsNothing);
    });

    testWidgets('a loaded report renders the chart and one row per point', (
      tester,
    ) async {
      when(
        () => reportBloc.state,
      ).thenReturn(SpendingTimeReportLoaded(data(), showComparison: false));

      await pumpPage(tester);

      expect(find.byType(TimeSeriesLineChart), findsOneWidget);
      // Daily granularity formats each row header as a plain date.
      expect(find.textContaining('2024'), findsWidgets);
    });
  });

  group('granularity headers', () {
    testWidgets('weekly rows are prefixed with "Wk of"', (tester) async {
      when(() => reportBloc.state).thenReturn(
        SpendingTimeReportLoaded(
          data(
            points: [point(DateTime(2024, 3, 4), 100)],
            granularity: TimeSeriesGranularity.weekly,
          ),
          showComparison: false,
        ),
      );

      await pumpPage(tester);

      expect(find.textContaining('Wk of'), findsOneWidget);
    });

    testWidgets('monthly rows use a month-year header', (tester) async {
      when(() => reportBloc.state).thenReturn(
        SpendingTimeReportLoaded(
          data(
            points: [point(DateTime(2024, 3, 15), 100)],
            granularity: TimeSeriesGranularity.monthly,
          ),
          showComparison: false,
        ),
      );

      await pumpPage(tester);

      expect(find.text('Mar 2024'), findsOneWidget);
    });
  });

  group('comparison toggle', () {
    testWidgets('toggling comparison reloads with the same granularity', (
      tester,
    ) async {
      when(() => reportBloc.state).thenReturn(
        SpendingTimeReportLoaded(
          data(granularity: TimeSeriesGranularity.monthly),
          showComparison: false,
        ),
      );

      await pumpPage(tester);
      await tester.tap(find.byIcon(Icons.compare_arrows_outlined));
      await tester.pumpAndSettle();

      final event =
          verify(() => reportBloc.add(captureAny())).captured.last
              as LoadSpendingTimeReport;
      expect(event.compareToPrevious, isTrue);
      expect(event.granularity, TimeSeriesGranularity.monthly);
      // The icon flips to the filled variant once comparison is on.
      expect(find.byIcon(Icons.compare_arrows_rounded), findsOneWidget);
    });

    testWidgets('toggling from a loading state keeps its granularity', (
      tester,
    ) async {
      when(() => reportBloc.state).thenReturn(
        const SpendingTimeReportLoading(
          granularity: TimeSeriesGranularity.weekly,
          compareToPrevious: false,
        ),
      );

      await pumpPage(tester, settle: false);
      await tester.tap(find.byIcon(Icons.compare_arrows_outlined));
      await tester.pump();

      final event =
          verify(() => reportBloc.add(captureAny())).captured.last
              as LoadSpendingTimeReport;
      expect(event.granularity, TimeSeriesGranularity.weekly);
    });

    testWidgets('toggling from the initial state falls back to daily', (
      tester,
    ) async {
      await pumpPage(tester);
      await tester.tap(find.byIcon(Icons.compare_arrows_outlined));
      await tester.pumpAndSettle();

      final event =
          verify(() => reportBloc.add(captureAny())).captured.last
              as LoadSpendingTimeReport;
      expect(event.granularity, TimeSeriesGranularity.daily);
    });
  });

  group('granularity menu', () {
    testWidgets('selecting a granularity reloads the report', (tester) async {
      when(
        () => reportBloc.state,
      ).thenReturn(SpendingTimeReportLoaded(data(), showComparison: false));

      await pumpPage(tester);
      await tester.tap(find.byIcon(Icons.timeline_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Monthly').last);
      await tester.pumpAndSettle();

      final event =
          verify(() => reportBloc.add(captureAny())).captured.last
              as LoadSpendingTimeReport;
      expect(event.granularity, TimeSeriesGranularity.monthly);
    });

    testWidgets('the menu offers every granularity', (tester) async {
      when(
        () => reportBloc.state,
      ).thenReturn(SpendingTimeReportLoaded(data(), showComparison: false));

      await pumpPage(tester);
      await tester.tap(find.byIcon(Icons.timeline_outlined));
      await tester.pumpAndSettle();

      for (final g in TimeSeriesGranularity.values) {
        final label = g.name[0].toUpperCase() + g.name.substring(1);
        expect(find.text(label), findsWidgets, reason: 'missing $label');
      }
    });
  });

  group('CSV export', () {
    testWidgets('exports the loaded report through the helper', (tester) async {
      final reportData = data();
      when(
        () => reportBloc.state,
      ).thenReturn(SpendingTimeReportLoaded(reportData, showComparison: false));
      when(
        () => csvHelper.exportSpendingTimeReport(
          any(),
          any(),
          showComparison: any(named: 'showComparison'),
        ),
      ).thenAnswer((_) async => const dartz.Left('date,amount'));

      await pumpPage(tester);

      // The export lives behind the wrapper's download menu.
      await tester.tap(find.byIcon(Icons.download_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export as CSV'));
      await tester.pumpAndSettle();

      verify(
        () => csvHelper.exportSpendingTimeReport(
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
        () => csvHelper.exportSpendingTimeReport(
          any(),
          any(),
          showComparison: any(named: 'showComparison'),
        ),
      );
    });
  });
}
