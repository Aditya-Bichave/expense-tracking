import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/goal_progress_report/goal_progress_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/pages/goal_progress_page.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockGoalProgressReportBloc
    extends MockBloc<GoalProgressReportEvent, GoalProgressReportState>
    implements GoalProgressReportBloc {}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockCsvExportHelper extends Mock implements CsvExportHelper {}

// Helpers
final tGoal = Goal(
  id: '1',
  name: 'Test Goal',
  targetAmount: 1000,
  totalSaved: 500,
  status: GoalStatus.active,
  createdAt: DateTime(2023, 1, 1),
  targetDate: DateTime(2023, 12, 31),
  iconName: 'savings',
  description: 'Test Description',
);

final tGoalData = GoalProgressData(
  goal: tGoal,
  contributions: [
    GoalContribution(
      id: 'c1',
      goalId: '1',
      amount: 100,
      date: DateTime(2023, 6, 1),
      note: 'Test',
      createdAt: DateTime(2023, 6, 1),
    ),
  ],
  requiredDailySaving: 10.0,
  requiredMonthlySaving: 300.0,
  estimatedCompletionDate: DateTime(2023, 10, 1),
);

final tReportData = GoalProgressReportData(progressData: [tGoalData]);

void main() {
  late MockGoalProgressReportBloc mockBloc;
  late MockSettingsBloc mockSettingsBloc;
  late MockCsvExportHelper mockCsvExportHelper;

  setUpAll(() {
    registerFallbackValue(const ToggleComparison());
    registerFallbackValue(tReportData);
  });

  setUp(() {
    mockBloc = MockGoalProgressReportBloc();
    mockSettingsBloc = MockSettingsBloc();
    mockCsvExportHelper = MockCsvExportHelper();

    // Ensure GetIt is reset and registered
    GetIt.instance.reset();
    GetIt.instance.registerLazySingleton<CsvExportHelper>(
      () => mockCsvExportHelper,
    );

    when(
      () => mockSettingsBloc.state,
    ).thenReturn(const SettingsState(selectedCountryCode: 'US'));
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<GoalProgressReportBloc>.value(value: mockBloc),
          BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
        ],
        child: const GoalProgressPage(),
      ),
    );
  }

  testWidgets('renders loading state', (tester) async {
    when(() => mockBloc.state).thenReturn(GoalProgressReportLoading());

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders error state', (tester) async {
    when(
      () => mockBloc.state,
    ).thenReturn(const GoalProgressReportError('Failed'));

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Error: Failed'), findsOneWidget);
  });

  testWidgets('renders empty state', (tester) async {
    when(() => mockBloc.state).thenReturn(
      const GoalProgressReportLoaded(GoalProgressReportData(progressData: [])),
    );

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('No active goals found.'), findsOneWidget);
  });

  testWidgets('renders report data without pacing info by default', (
    tester,
  ) async {
    when(
      () => mockBloc.state,
    ).thenReturn(GoalProgressReportLoaded(tReportData));

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Test Goal'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Pacing Information'), findsNothing);
  });

  testWidgets('renders report data WITH pacing info when enabled', (
    tester,
  ) async {
    // Increase screen size
    tester.binding.window.physicalSizeTestValue = const Size(1000, 2000);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    when(() => mockBloc.state).thenReturn(
      GoalProgressReportLoaded(tReportData, isComparisonEnabled: true),
    );

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Pacing Information'), findsOneWidget);
    expect(find.text('Req. Daily'), findsOneWidget);
    expect(find.text('\$10.00'), findsOneWidget);
  });

  testWidgets('triggers toggle comparison event', (tester) async {
    when(() => mockBloc.state).thenReturn(
      GoalProgressReportLoaded(tReportData, isComparisonEnabled: false),
    );

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.byIcon(Icons.compare_arrows_outlined));
    await tester.pump();

    verify(() => mockBloc.add(const ToggleComparison())).called(1);
  });

  testWidgets('triggers CSV export', (tester) async {
    // Explicitly re-register to be safe, though setUp should handle it
    if (!GetIt.instance.isRegistered<CsvExportHelper>()) {
      GetIt.instance.registerLazySingleton<CsvExportHelper>(
        () => mockCsvExportHelper,
      );
    }

    when(
      () => mockBloc.state,
    ).thenReturn(GoalProgressReportLoaded(tReportData));

    when(
      () => mockCsvExportHelper.exportGoalProgressReport(any(), any()),
    ).thenAnswer((_) async => const Left<String, Failure>('csv,data'));

    when(
      () => mockCsvExportHelper.saveCsvFile(
        context: any(named: 'context'),
        csvData: any(named: 'csvData'),
        fileName: any(named: 'fileName'),
      ),
    ).thenAnswer((_) async => {});

    await tester.pumpWidget(createWidgetUnderTest());

    // Open menu
    await tester.tap(find.byIcon(Icons.download_outlined));
    await tester.pumpAndSettle();

    // Tap Export CSV
    await tester.tap(find.text('Export as CSV'));
    await tester.pumpAndSettle();

    // Verify export called
    verify(
      () => mockCsvExportHelper.exportGoalProgressReport(tReportData, '\$'),
    ).called(1);
  });
}
