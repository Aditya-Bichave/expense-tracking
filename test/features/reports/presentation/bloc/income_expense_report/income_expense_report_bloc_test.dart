import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_income_expense_report.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/income_expense_report/income_expense_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetIncomeExpenseReportUseCase extends Mock
    implements GetIncomeExpenseReportUseCase {}

class MockReportFilterBloc extends MockBloc<ReportFilterEvent, ReportFilterState>
    implements ReportFilterBloc {}

void main() {
  late IncomeExpenseReportBloc bloc;
  late MockGetIncomeExpenseReportUseCase mockUseCase;
  late MockReportFilterBloc mockFilterBloc;

  setUpAll(() {
    registerFallbackValue(
      GetIncomeExpenseReportParams(
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        periodType: IncomeExpensePeriodType.monthly,
        compareToPrevious: false,
      ),
    );
    registerFallbackValue(IncomeExpensePeriodType.monthly);
  });

  setUp(() {
    mockUseCase = MockGetIncomeExpenseReportUseCase();
    mockFilterBloc = MockReportFilterBloc();

    // Default filter state
    when(() => mockFilterBloc.state).thenReturn(ReportFilterState.initial());
    when(() => mockFilterBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  final tReportData = IncomeExpenseReportData(
    periodData: const [],
    periodType: IncomeExpensePeriodType.monthly,
  );

  blocTest<IncomeExpenseReportBloc, IncomeExpenseReportState>(
    'emits [Loading, Loaded] when initialized and use case succeeds',
    build: () {
      when(() => mockUseCase(any())).thenAnswer((_) async => Right(tReportData));
      return IncomeExpenseReportBloc(
        getIncomeExpenseReportUseCase: mockUseCase,
        reportFilterBloc: mockFilterBloc,
      );
    },
    // The LoadIncomeExpenseReport event is added in constructor
    expect: () => [
      isA<IncomeExpenseReportLoading>()
          .having((s) => s.periodType, 'period', IncomeExpensePeriodType.monthly)
          .having((s) => s.compareToPrevious, 'compare', false),
      isA<IncomeExpenseReportLoaded>()
          .having((s) => s.reportData, 'data', tReportData)
          .having((s) => s.showComparison, 'compare', false),
    ],
  );

  blocTest<IncomeExpenseReportBloc, IncomeExpenseReportState>(
    'emits [Loading, Error] when use case fails',
    build: () {
      when(() => mockUseCase(any())).thenAnswer((_) async => const Left(ServerFailure('Error')));
      return IncomeExpenseReportBloc(
        getIncomeExpenseReportUseCase: mockUseCase,
        reportFilterBloc: mockFilterBloc,
      );
    },
    expect: () => [
      isA<IncomeExpenseReportLoading>(),
      isA<IncomeExpenseReportError>().having((s) => s.message, 'message', 'Error'),
    ],
  );

  blocTest<IncomeExpenseReportBloc, IncomeExpenseReportState>(
    'emits [Loading, Loaded] with new period when ChangeIncomeExpensePeriod is added',
    build: () {
      when(() => mockUseCase(any())).thenAnswer((_) async => Right(tReportData));
      return IncomeExpenseReportBloc(
        getIncomeExpenseReportUseCase: mockUseCase,
        reportFilterBloc: mockFilterBloc,
      );
    },
    skip: 2, // Skip initial loading/loaded
    act: (bloc) => bloc.add(const ChangeIncomeExpensePeriod(IncomeExpensePeriodType.yearly)),
    expect: () => [
      isA<IncomeExpenseReportLoading>()
          .having((s) => s.periodType, 'period', IncomeExpensePeriodType.yearly),
      isA<IncomeExpenseReportLoaded>(),
    ],
  );
}
