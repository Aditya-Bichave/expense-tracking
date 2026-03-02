import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_time_report/spending_time_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/pages/spending_over_time_page.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockSpendingTimeReportBloc
    extends MockBloc<SpendingTimeReportEvent, SpendingTimeReportState>
    implements SpendingTimeReportBloc {}

class MockReportFilterBloc
    extends MockBloc<ReportFilterEvent, ReportFilterState>
    implements ReportFilterBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockCsvExportHelper extends Mock implements CsvExportHelper {}

void main() {
  late MockSpendingTimeReportBloc mockSpendingBloc;
  late MockReportFilterBloc mockFilterBloc;
  late MockSettingsBloc mockSettingsBloc;
  late MockCsvExportHelper mockCsvHelper;

  setUpAll(() {
    registerFallbackValue(SpendingTimeReportInitial());
    registerFallbackValue(ReportFilterState.initial());
    registerFallbackValue(const SettingsState());
  });

  setUp(() {
    mockSpendingBloc = MockSpendingTimeReportBloc();
    mockFilterBloc = MockReportFilterBloc();
    mockSettingsBloc = MockSettingsBloc();
    mockCsvHelper = MockCsvExportHelper();

    final getIt = GetIt.instance;
    getIt.reset();
    getIt.registerSingleton<CsvExportHelper>(mockCsvHelper);

    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(() => mockFilterBloc.state).thenReturn(ReportFilterState.initial());
    when(() => mockSpendingBloc.state).thenReturn(SpendingTimeReportInitial());
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  Widget createWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SpendingTimeReportBloc>.value(value: mockSpendingBloc),
        BlocProvider<ReportFilterBloc>.value(value: mockFilterBloc),
        BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SpendingOverTimePage(),
      ),
    );
  }

  testWidgets('renders SpendingOverTimePage', (tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();
    expect(find.byType(SpendingOverTimePage), findsOneWidget);
  });

  testWidgets('shows loading indicator when loading', (tester) async {
    when(() => mockSpendingBloc.state).thenReturn(
      const SpendingTimeReportLoading(
        granularity: TimeSeriesGranularity.daily,
        compareToPrevious: false,
      ),
    );
    await tester.pumpWidget(createWidget());
    // Use pump instead of pumpAndSettle for infinite animations
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message when error', (tester) async {
    when(
      () => mockSpendingBloc.state,
    ).thenReturn(const SpendingTimeReportError('Test Error'));
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();
    expect(find.text('Error: Test Error'), findsOneWidget);
  });

  testWidgets('renders loaded report data with sliver list', (tester) async {
    final reportData = SpendingTimeReportData(
      granularity: TimeSeriesGranularity.daily,
      spendingData: [
        TimeSeriesDataPoint(
          date: DateTime(2023, 5, 1),
          amount: const ComparisonValue(
            currentValue: 100.0,
            previousValue: 80.0,
          ),
        ),
        TimeSeriesDataPoint(
          date: DateTime(2023, 5, 2),
          amount: const ComparisonValue(
            currentValue: 150.0,
            previousValue: 120.0,
          ),
        ),
      ],
    );

    when(
      () => mockSpendingBloc.state,
    ).thenReturn(SpendingTimeReportLoaded(reportData, showComparison: false));

    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();

    // Check if CustomScrollView is present
    expect(find.byType(CustomScrollView), findsOneWidget);

    // Check if list items are rendered (implying SliverList is working)
    expect(find.byType(ListTile), findsNWidgets(2));

    // Verify specific data rendering if possible (dates/amounts might be formatted)
    // We can just check that we have list tiles
  });
}
