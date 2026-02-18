import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_spending_category_report.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_category_report/spending_category_report_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetSpendingCategoryReportUseCase extends Mock
    implements GetSpendingCategoryReportUseCase {}

class MockReportFilterBloc
    extends MockBloc<ReportFilterEvent, ReportFilterState>
    implements ReportFilterBloc {}

void main() {
  late SpendingCategoryReportBloc bloc;
  late MockGetSpendingCategoryReportUseCase mockUseCase;
  late MockReportFilterBloc mockFilterBloc;

  setUpAll(() {
    registerFallbackValue(
      GetSpendingCategoryReportParams(
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        compareToPrevious: false,
      ),
    );
  });

  setUp(() {
    mockUseCase = MockGetSpendingCategoryReportUseCase();
    mockFilterBloc = MockReportFilterBloc();

    // Default filter state
    when(() => mockFilterBloc.state).thenReturn(ReportFilterState.initial());
    when(() => mockFilterBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  final tReportData = SpendingCategoryReportData(
    totalSpending: const ComparisonValue(currentValue: 100),
    spendingByCategory: const [],
  );

  blocTest<SpendingCategoryReportBloc, SpendingCategoryReportState>(
    'emits [Loading, Loaded] when initialized and use case succeeds',
    build: () {
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) async => Right(tReportData));
      return SpendingCategoryReportBloc(
        getSpendingCategoryReportUseCase: mockUseCase,
        reportFilterBloc: mockFilterBloc,
      );
    },
    // The LoadSpendingCategoryReport event is added in constructor
    expect: () => [
      isA<SpendingCategoryReportLoading>().having(
        (s) => s.compareToPrevious,
        'compare',
        false,
      ),
      isA<SpendingCategoryReportLoaded>().having(
        (s) => s.reportData,
        'data',
        tReportData,
      ),
    ],
  );

  blocTest<SpendingCategoryReportBloc, SpendingCategoryReportState>(
    'emits [Loading, Error] when use case fails',
    build: () {
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) async => const Left(ServerFailure('Error')));
      return SpendingCategoryReportBloc(
        getSpendingCategoryReportUseCase: mockUseCase,
        reportFilterBloc: mockFilterBloc,
      );
    },
    expect: () => [
      isA<SpendingCategoryReportLoading>(),
      isA<SpendingCategoryReportError>().having(
        (s) => s.message,
        'message',
        'Error',
      ),
    ],
  );

  // Test ToggleSpendingComparison
  // Note: ToggleSpendingComparison logic:
  // final bool currentCompare = state is SpendingCategoryReportLoaded ? (state as SpendingCategoryReportLoaded).showComparison : false;
  // add(LoadSpendingCategoryReport(compareToPrevious: !currentCompare));

  blocTest<SpendingCategoryReportBloc, SpendingCategoryReportState>(
    'emits [Loading, Loaded] with compare=true when ToggleSpendingComparison is added',
    build: () {
      when(
        () => mockUseCase(any()),
      ).thenAnswer((_) async => Right(tReportData));
      return SpendingCategoryReportBloc(
        getSpendingCategoryReportUseCase: mockUseCase,
        reportFilterBloc: mockFilterBloc,
      );
    },
    skip: 2, // Skip initial loading/loaded
    act: (bloc) => bloc.add(const ToggleSpendingComparison()),
    expect: () => [
      // Since initial state was loaded with compare=false (default), toggle makes it true
      isA<SpendingCategoryReportLoading>().having(
        (s) => s.compareToPrevious,
        'compare',
        true,
      ),
      isA<SpendingCategoryReportLoaded>().having(
        (s) => s.showComparison,
        'compare',
        true,
      ),
    ],
  );
}
