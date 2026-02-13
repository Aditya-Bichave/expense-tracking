import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_spending_category_report.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_category_report/spending_category_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
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

  final tReportData = SpendingCategoryReportData(
    totalSpending: const ComparisonValue(currentValue: 100),
    spendingByCategory: const [],
  );

  setUpAll(() {
    registerFallbackValue(GetSpendingCategoryReportParams(
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      compareToPrevious: false,
    ));
  });

  setUp(() {
    mockUseCase = MockGetSpendingCategoryReportUseCase();
    mockFilterBloc = MockReportFilterBloc();
    when(() => mockFilterBloc.state).thenReturn(ReportFilterState.initial());
  });

  group('LoadSpendingCategoryReport', () {
    blocTest<SpendingCategoryReportBloc, SpendingCategoryReportState>(
      'emits [loading, loaded] on success',
      build: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => Right(tReportData));
        return SpendingCategoryReportBloc(
          getSpendingCategoryReportUseCase: mockUseCase,
          reportFilterBloc: mockFilterBloc,
        );
      },
      // Initial load triggered in constructor
      expect: () => [
        isA<SpendingCategoryReportLoading>(),
        SpendingCategoryReportLoaded(tReportData, showComparison: false),
      ],
    );

    blocTest<SpendingCategoryReportBloc, SpendingCategoryReportState>(
      'emits [loading, error] on failure',
      build: () {
        when(() => mockUseCase(any()))
            .thenAnswer((_) async => Left(CacheFailure('Error')));
        return SpendingCategoryReportBloc(
          getSpendingCategoryReportUseCase: mockUseCase,
          reportFilterBloc: mockFilterBloc,
        );
      },
      // Initial load triggered in constructor
      expect: () => [
        isA<SpendingCategoryReportLoading>(),
        const SpendingCategoryReportError('Error'),
      ],
    );
  });
}
