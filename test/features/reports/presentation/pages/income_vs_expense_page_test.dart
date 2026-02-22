import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/income_expense_report/income_expense_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/pages/income_vs_expense_page.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockIncomeExpenseReportBloc
    extends MockBloc<IncomeExpenseReportEvent, IncomeExpenseReportState>
    implements IncomeExpenseReportBloc {}

class MockReportFilterBloc
    extends MockBloc<ReportFilterEvent, ReportFilterState>
    implements ReportFilterBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockCsvExportHelper extends Mock implements CsvExportHelper {}

void main() {
  late MockIncomeExpenseReportBloc mockReportBloc;
  late MockReportFilterBloc mockFilterBloc;
  late MockSettingsBloc mockSettingsBloc;
  late MockCsvExportHelper mockCsvHelper;

  setUpAll(() {
    registerFallbackValue(IncomeExpenseReportInitial());
    registerFallbackValue(ReportFilterState.initial());
    registerFallbackValue(const SettingsState());
  });

  setUp(() {
    mockReportBloc = MockIncomeExpenseReportBloc();
    mockFilterBloc = MockReportFilterBloc();
    mockSettingsBloc = MockSettingsBloc();
    mockCsvHelper = MockCsvExportHelper();

    final getIt = GetIt.instance;
    getIt.reset();
    getIt.registerSingleton<CsvExportHelper>(mockCsvHelper);

    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(() => mockFilterBloc.state).thenReturn(ReportFilterState.initial());
    when(() => mockReportBloc.state).thenReturn(IncomeExpenseReportInitial());
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  Widget createWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<IncomeExpenseReportBloc>.value(value: mockReportBloc),
        BlocProvider<ReportFilterBloc>.value(value: mockFilterBloc),
        BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: IncomeVsExpensePage(),
      ),
    );
  }

  testWidgets('renders IncomeVsExpensePage', (tester) async {
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();
    expect(find.byType(IncomeVsExpensePage), findsOneWidget);
  });

  testWidgets('shows loading indicator when loading', (tester) async {
    when(() => mockReportBloc.state).thenReturn(
      const IncomeExpenseReportLoading(
        periodType: IncomeExpensePeriodType.monthly,
        compareToPrevious: false,
      ),
    );
    await tester.pumpWidget(createWidget());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message when error', (tester) async {
    when(
      () => mockReportBloc.state,
    ).thenReturn(const IncomeExpenseReportError('Test Error'));
    await tester.pumpWidget(createWidget());
    await tester.pumpAndSettle();
    expect(find.text('Error: Test Error'), findsOneWidget);
  });
}
