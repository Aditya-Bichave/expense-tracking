import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/budget_performance_report/budget_performance_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/pages/budget_performance_page.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

class MockBudgetPerformanceReportBloc
    extends MockBloc<BudgetPerformanceReportEvent, BudgetPerformanceReportState>
    implements BudgetPerformanceReportBloc {}

class MockReportFilterBloc
    extends MockBloc<ReportFilterEvent, ReportFilterState>
    implements ReportFilterBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class FakeBudgetPerformanceReportEvent extends Fake
    implements BudgetPerformanceReportEvent {}

class FakeReportFilterEvent extends Fake implements ReportFilterEvent {}

class FakeSettingsEvent extends Fake implements SettingsEvent {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBudgetPerformanceReportBloc mockReportBloc;
  late MockReportFilterBloc mockFilterBloc;
  late MockSettingsBloc mockSettingsBloc;

  setUpAll(() {
    registerFallbackValue(FakeBudgetPerformanceReportEvent());
    registerFallbackValue(FakeReportFilterEvent());
    registerFallbackValue(FakeSettingsEvent());
  });

  setUp(() {
    mockReportBloc = MockBudgetPerformanceReportBloc();
    mockFilterBloc = MockReportFilterBloc();
    mockSettingsBloc = MockSettingsBloc();

    when(() => mockFilterBloc.state).thenReturn(ReportFilterState.initial());
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
  });

  testWidgets('BudgetPerformancePage renders loading state', (tester) async {
    when(() => mockReportBloc.state).thenReturn(const BudgetPerformanceReportLoading(compareToPrevious: false));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<BudgetPerformanceReportBloc>.value(value: mockReportBloc),
          BlocProvider<ReportFilterBloc>.value(value: mockFilterBloc),
          BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BudgetPerformancePage(),
        ),
      ),
    );
    // Don't settle, just pump once to see loading
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('BudgetPerformancePage renders empty state', (tester) async {
     final emptyData = BudgetPerformanceReportData(performanceData: []);
     when(() => mockReportBloc.state).thenReturn(
       BudgetPerformanceReportLoaded(emptyData, showComparison: false),
     );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<BudgetPerformanceReportBloc>.value(value: mockReportBloc),
          BlocProvider<ReportFilterBloc>.value(value: mockFilterBloc),
          BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BudgetPerformancePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No budgets found for this period.'), findsOneWidget);
  });
}
