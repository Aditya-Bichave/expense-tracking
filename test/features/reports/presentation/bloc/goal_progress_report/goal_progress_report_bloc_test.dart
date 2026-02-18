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

class MockReportFilterBloc
    extends MockBloc<ReportFilterEvent, ReportFilterState>
    implements ReportFilterBloc {}

void main() {
  late GoalProgressReportBloc bloc;
  late MockGetGoalProgressReportUseCase mockUseCase;
  late MockReportFilterBloc mockFilterBloc;

  setUpAll(() {
    registerFallbackValue(const GetGoalProgressReportParams());
  });

  setUp(() {
    mockUseCase = MockGetGoalProgressReportUseCase();
    mockFilterBloc = MockReportFilterBloc();

    // Default filter state
    when(() => mockFilterBloc.state).thenReturn(ReportFilterState.initial());
    when(() => mockFilterBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  final tReportData = GoalProgressReportData(progressData: const []);

  blocTest<GoalProgressReportBloc, GoalProgressReportState>(
    'emits [Loading, Loaded] when initialized and use case succeeds',
    build: () {
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) async => Right(tReportData));
      return GoalProgressReportBloc(
        getGoalProgressReportUseCase: mockUseCase,
        reportFilterBloc: mockFilterBloc,
      );
    },
    // The LoadGoalProgressReport event is added in constructor
    expect: () => [
      isA<GoalProgressReportLoading>(),
      isA<GoalProgressReportLoaded>().having(
        (s) => s.reportData,
        'data',
        tReportData,
      ),
    ],
  );

  blocTest<GoalProgressReportBloc, GoalProgressReportState>(
    'emits [Loading, Error] when use case fails',
    build: () {
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) async => const Left(ServerFailure('Error')));
      return GoalProgressReportBloc(
        getGoalProgressReportUseCase: mockUseCase,
        reportFilterBloc: mockFilterBloc,
      );
    },
    expect: () => [
      isA<GoalProgressReportLoading>(),
      isA<GoalProgressReportError>().having(
        (s) => s.message,
        'message',
        'Error',
      ),
    ],
  );
}
