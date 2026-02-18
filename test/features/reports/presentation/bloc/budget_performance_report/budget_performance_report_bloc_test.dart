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

class MockReportFilterBloc
    extends MockBloc<ReportFilterEvent, ReportFilterState>
    implements ReportFilterBloc {}

void main() {
  late BudgetPerformanceReportBloc bloc;
  late MockGetBudgetPerformanceReportUseCase mockUseCase;
  late MockReportFilterBloc mockFilterBloc;

  setUpAll(() {
    registerFallbackValue(
      GetBudgetPerformanceReportParams(
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        compareToPrevious: false,
      ),
    );
  });

  setUp(() {
    mockUseCase = MockGetBudgetPerformanceReportUseCase();
    mockFilterBloc = MockReportFilterBloc();

    // Default filter state
    when(() => mockFilterBloc.state).thenReturn(ReportFilterState.initial());
    when(() => mockFilterBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  final tReportData = BudgetPerformanceReportData(
    performanceData: const [],
    previousPerformanceData: const [],
  );

  blocTest<BudgetPerformanceReportBloc, BudgetPerformanceReportState>(
    'emits [Loading, Loaded] when initialized and use case succeeds',
    build: () {
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) async => Right(tReportData));
      return BudgetPerformanceReportBloc(
        getBudgetPerformanceReportUseCase: mockUseCase,
        reportFilterBloc: mockFilterBloc,
      );
    },
    // The LoadBudgetPerformanceReport event is added in constructor
    expect: () => [
      isA<BudgetPerformanceReportLoading>().having(
        (s) => s.compareToPrevious,
        'compare',
        false,
      ),
      isA<BudgetPerformanceReportLoaded>()
          .having((s) => s.reportData, 'data', tReportData)
          .having((s) => s.showComparison, 'compare', false),
    ],
  );

  blocTest<BudgetPerformanceReportBloc, BudgetPerformanceReportState>(
    'emits [Loading, Error] when use case fails',
    build: () {
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) async => const Left(ServerFailure('Error')));
      return BudgetPerformanceReportBloc(
        getBudgetPerformanceReportUseCase: mockUseCase,
        reportFilterBloc: mockFilterBloc,
      );
    },
    expect: () => [
      isA<BudgetPerformanceReportLoading>(),
      isA<BudgetPerformanceReportError>().having(
        (s) => s.message,
        'message',
        'Error',
      ),
    ],
  );

  blocTest<BudgetPerformanceReportBloc, BudgetPerformanceReportState>(
    'emits [Loading, Loaded] with compare=true when ToggleBudgetComparison is added',
    build: () {
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) async => Right(tReportData));
      return BudgetPerformanceReportBloc(
        getBudgetPerformanceReportUseCase: mockUseCase,
        reportFilterBloc: mockFilterBloc,
      );
    },
    skip: 2, // Skip initial loading/loaded
    act: (bloc) => bloc.add(const ToggleBudgetComparison()),
    expect: () => [
      isA<BudgetPerformanceReportLoading>().having(
        (s) => s.compareToPrevious,
        'compare',
        true,
      ),
      isA<BudgetPerformanceReportLoaded>().having(
        (s) => s.showComparison,
        'compare',
        true,
      ),
    ],
  );
}
