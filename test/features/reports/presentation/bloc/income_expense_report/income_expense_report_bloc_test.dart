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

class MockReportFilterBloc
    extends MockBloc<ReportFilterEvent, ReportFilterState>
    implements ReportFilterBloc {}

void main() {
  late IncomeExpenseReportBloc bloc;
  late MockGetIncomeExpenseReportUseCase mockGetReportUseCase;
  late MockReportFilterBloc mockReportFilterBloc;

  final tReportData = IncomeExpenseReportData(
    periodType: IncomeExpensePeriodType.monthly,
    periodData: const [],
  );

  setUpAll(() {
    registerFallbackValue(GetIncomeExpenseReportParams(
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      periodType: IncomeExpensePeriodType.monthly,
      compareToPrevious: false,
    ));
  });

  setUp(() {
    mockGetReportUseCase = MockGetIncomeExpenseReportUseCase();
    mockReportFilterBloc = MockReportFilterBloc();

    when(() => mockReportFilterBloc.state)
        .thenReturn(ReportFilterState.initial());
  });

  group('LoadIncomeExpenseReport', () {
    blocTest<IncomeExpenseReportBloc, IncomeExpenseReportState>(
      'emits [loading, loaded] on success',
      build: () {
        when(() => mockGetReportUseCase(any()))
            .thenAnswer((_) async => Right(tReportData));
        return IncomeExpenseReportBloc(
          getIncomeExpenseReportUseCase: mockGetReportUseCase,
          reportFilterBloc: mockReportFilterBloc,
        );
      },
      // Initial load is triggered in constructor
      expect: () => [
        isA<IncomeExpenseReportLoading>(),
        IncomeExpenseReportLoaded(tReportData, showComparison: false),
      ],
    );

    blocTest<IncomeExpenseReportBloc, IncomeExpenseReportState>(
      'emits [loading, error] on failure',
      build: () {
        when(() => mockGetReportUseCase(any()))
            .thenAnswer((_) async => Left(CacheFailure('Error')));
        return IncomeExpenseReportBloc(
          getIncomeExpenseReportUseCase: mockGetReportUseCase,
          reportFilterBloc: mockReportFilterBloc,
        );
      },
      // Initial load is triggered in constructor
      expect: () => [
        isA<IncomeExpenseReportLoading>(),
        const IncomeExpenseReportError('Error'),
      ],
    );
  });

  group('ChangeIncomeExpensePeriod', () {
    blocTest<IncomeExpenseReportBloc, IncomeExpenseReportState>(
      'emits [loading, loaded] with new period',
      build: () {
        when(() => mockGetReportUseCase(any()))
            .thenAnswer((_) async => Right(tReportData));
        return IncomeExpenseReportBloc(
          getIncomeExpenseReportUseCase: mockGetReportUseCase,
          reportFilterBloc: mockReportFilterBloc,
        );
      },
      act: (bloc) => bloc
          .add(const ChangeIncomeExpensePeriod(IncomeExpensePeriodType.yearly)),
      expect: () => [
        isA<IncomeExpenseReportLoading>(), // Initial load
        isA<IncomeExpenseReportLoaded>(),
        isA<IncomeExpenseReportLoading>().having((s) => s.periodType, 'period',
            IncomeExpensePeriodType.yearly), // Reload with new period
        isA<IncomeExpenseReportLoaded>(),
      ],
    );
  });
}
