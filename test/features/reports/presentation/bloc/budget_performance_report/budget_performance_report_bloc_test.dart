import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_budget_performance_report.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/budget_performance_report/budget_performance_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetBudgetPerformanceReportUseCase extends Mock
    implements GetBudgetPerformanceReportUseCase {}

class MockReportFilterBloc extends Mock implements ReportFilterBloc {}

void main() {
  late BudgetPerformanceReportBloc bloc;
  late MockGetBudgetPerformanceReportUseCase mockUseCase;
  late MockReportFilterBloc mockReportFilterBloc;

  setUp(() {
    mockUseCase = MockGetBudgetPerformanceReportUseCase();
    mockReportFilterBloc = MockReportFilterBloc();

    // Mock the filter bloc stream and state
    when(
      () => mockReportFilterBloc.stream,
    ).thenAnswer((_) => const Stream.empty());
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

    bloc = BudgetPerformanceReportBloc(
      getBudgetPerformanceReportUseCase: mockUseCase,
      reportFilterBloc: mockReportFilterBloc,
    );

    registerFallbackValue(
      GetBudgetPerformanceReportParams(
        startDate: DateTime(2023),
        endDate: DateTime(2023),
      ),
    );
  });

  tearDown(() {
    bloc.close();
  });

  const tReportData = BudgetPerformanceReportData(performanceData: []);
  final tFailure = CacheFailure();

  group('BudgetPerformanceReportBloc', () {
    test('initial state is initial (before first event processed)', () {
      expect(bloc.state, isA<BudgetPerformanceReportInitial>());
    });

    blocTest<BudgetPerformanceReportBloc, BudgetPerformanceReportState>(
      'emits [loading, loaded] when LoadBudgetPerformanceReport is successful',
      build: () {
        when(
          () => mockUseCase(any()),
        ).thenAnswer((_) async => const Right(tReportData));
        return BudgetPerformanceReportBloc(
          getBudgetPerformanceReportUseCase: mockUseCase,
          reportFilterBloc: mockReportFilterBloc,
        );
      },
      skip: 2, // Skip the initial load triggered by constructor
      act: (bloc) => bloc.add(const LoadBudgetPerformanceReport()),
      expect: () => [
        const BudgetPerformanceReportLoading(compareToPrevious: false),
        const BudgetPerformanceReportLoaded(tReportData, showComparison: false),
      ],
    );

    blocTest<BudgetPerformanceReportBloc, BudgetPerformanceReportState>(
      'emits [loading, error] when LoadBudgetPerformanceReport fails',
      build: () {
        when(() => mockUseCase(any())).thenAnswer((_) async => Left(tFailure));
        return BudgetPerformanceReportBloc(
          getBudgetPerformanceReportUseCase: mockUseCase,
          reportFilterBloc: mockReportFilterBloc,
        );
      },
      skip: 2, // Skip initial load
      act: (bloc) => bloc.add(const LoadBudgetPerformanceReport()),
      expect: () => [
        const BudgetPerformanceReportLoading(compareToPrevious: false),
        const BudgetPerformanceReportError(
          'A local data storage error occurred.',
        ),
      ],
    );
  });
}
