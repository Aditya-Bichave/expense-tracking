import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_goal_progress_report.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/goal_progress_report/goal_progress_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetGoalProgressReportUseCase extends Mock
    implements GetGoalProgressReportUseCase {}

class MockReportFilterBloc extends Mock implements ReportFilterBloc {}

void main() {
  late GoalProgressReportBloc bloc;
  late MockGetGoalProgressReportUseCase mockUseCase;
  late MockReportFilterBloc mockReportFilterBloc;

  setUp(() {
    mockUseCase = MockGetGoalProgressReportUseCase();
    mockReportFilterBloc = MockReportFilterBloc();

    when(() => mockReportFilterBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockReportFilterBloc.state).thenReturn(
      ReportFilterState(
        optionsStatus: FilterOptionsStatus.loaded,
        availableCategories: const [],
        availableAccounts: const [],
        availableBudgets: const [],
        availableGoals: const [],
        startDate: DateTime(2023, 1, 1),
        endDate: DateTime(2023, 1, 31),
        selectedAccountIds: const [],
        selectedBudgetIds: const [],
        selectedCategoryIds: const [],
        selectedGoalIds: const [],
      ),
    );

    bloc = GoalProgressReportBloc(
      getGoalProgressReportUseCase: mockUseCase,
      reportFilterBloc: mockReportFilterBloc,
    );

    registerFallbackValue(const GetGoalProgressReportParams());
  });

  tearDown(() {
    bloc.close();
  });

  const tReportData = GoalProgressReportData(progressData: []);
  final tFailure = CacheFailure();

  group('GoalProgressReportBloc', () {
    test('initial state is initial (before first event processed)', () {
      expect(bloc.state, isA<GoalProgressReportInitial>());
    });

    blocTest<GoalProgressReportBloc, GoalProgressReportState>(
      'emits [loading, loaded] when LoadGoalProgressReport is successful',
      build: () {
        when(() => mockUseCase(any())).thenAnswer((_) async => const Right(tReportData));
        return GoalProgressReportBloc(
          getGoalProgressReportUseCase: mockUseCase,
          reportFilterBloc: mockReportFilterBloc,
        );
      },
      skip: 2, // Skip initial constructor load
      act: (bloc) => bloc.add(const LoadGoalProgressReport()),
      expect: () => [
        GoalProgressReportLoading(),
        const GoalProgressReportLoaded(tReportData),
      ],
    );

    blocTest<GoalProgressReportBloc, GoalProgressReportState>(
      'emits [loading, error] when LoadGoalProgressReport fails',
      build: () {
        when(() => mockUseCase(any())).thenAnswer((_) async => Left(tFailure));
        return GoalProgressReportBloc(
          getGoalProgressReportUseCase: mockUseCase,
          reportFilterBloc: mockReportFilterBloc,
        );
      },
      skip: 2, // Skip initial constructor load
      act: (bloc) => bloc.add(const LoadGoalProgressReport()),
      expect: () => [
        GoalProgressReportLoading(),
        const GoalProgressReportError('A local data storage error occurred.'),
      ],
    );
  });
}
