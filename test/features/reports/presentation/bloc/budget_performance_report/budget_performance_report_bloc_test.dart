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

  const tReportData = BudgetPerformanceReportData(performanceData: []);
  final tFailure = CacheFailure();

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

    registerFallbackValue(
      GetBudgetPerformanceReportParams(
        startDate: DateTime(2023),
        endDate: DateTime(2023),
      ),
    );

    // Stub default behavior for constructor call
    when(
      () => mockUseCase(any()),
    ).thenAnswer((_) async => const Right(tReportData));

    bloc = BudgetPerformanceReportBloc(
      getBudgetPerformanceReportUseCase: mockUseCase,
      reportFilterBloc: mockReportFilterBloc,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('BudgetPerformanceReportBloc', () {
    blocTest<BudgetPerformanceReportBloc, BudgetPerformanceReportState>(
      'emits [loading, loaded] when LoadBudgetPerformanceReport is successful',
      build: () {
        // Re-stub if needed, but the default stub in setUp is fine for success case.
        // Actually, blocTest creates a NEW bloc instance in build().
        // So we must ensure the stub is active. It is, because mockUseCase is reused?
        // Wait, mockUseCase is created in setUp.
        // blocTest uses `setUp` from `main`? Yes.
        // But `blocTest`'s `build` creates a *new* Bloc.
        // Does it use the *same* mockUseCase? Yes, because `setUp` ran once before this test.
        // So the stub in `setUp` applies here.
        return BudgetPerformanceReportBloc(
          getBudgetPerformanceReportUseCase: mockUseCase,
          reportFilterBloc: mockReportFilterBloc,
        );
      },
      skip:
          2, // Skip the initial load triggered by constructor (Loading, Loaded)
      act: (bloc) => bloc.add(const LoadBudgetPerformanceReport()),
      expect: () => [
        const BudgetPerformanceReportLoading(compareToPrevious: false),
        const BudgetPerformanceReportLoaded(tReportData, showComparison: false),
      ],
    );

    blocTest<BudgetPerformanceReportBloc, BudgetPerformanceReportState>(
      'emits [loading, error] when LoadBudgetPerformanceReport fails',
      build: () {
        // Override the stub for failure
        when(() => mockUseCase(any())).thenAnswer((_) async => Left(tFailure));
        return BudgetPerformanceReportBloc(
          getBudgetPerformanceReportUseCase: mockUseCase,
          reportFilterBloc: mockReportFilterBloc,
        );
      },
      skip:
          2, // Skip initial load (which will now be Loading -> Error because of override)
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
