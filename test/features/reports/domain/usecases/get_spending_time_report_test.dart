import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_spending_time_report.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReportRepository extends Mock implements ReportRepository {}

void main() {
  late GetSpendingTimeReportUseCase useCase;
  late MockReportRepository mockReportRepository;

  setUpAll(() {
    registerFallbackValue(TimeSeriesGranularity.daily);
  });

  setUp(() {
    mockReportRepository = MockReportRepository();
    useCase = GetSpendingTimeReportUseCase(mockReportRepository);
  });

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  final tGranularity = TimeSeriesGranularity.daily;
  final tAccountIds = ['account1'];
  final tCategoryIds = ['category1'];

  final tSpendingData = [
    TimeSeriesDataPoint(
      date: DateTime(2023, 1, 1),
      amount: const ComparisonValue(currentValue: 100.0),
    ),
  ];

  final tReportData = SpendingTimeReportData(
    spendingData: tSpendingData,
    granularity: tGranularity,
  );

  test('should get spending over time report from the repository', () async {
    // arrange
    when(
      () => mockReportRepository.getSpendingOverTime(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        granularity: any(named: 'granularity'),
        accountIds: any(named: 'accountIds'),
        categoryIds: any(named: 'categoryIds'),
      ),
    ).thenAnswer((_) async => Right(tReportData));

    // act
    final result = await useCase(
      GetSpendingTimeReportParams(
        startDate: tStartDate,
        endDate: tEndDate,
        granularity: tGranularity,
        accountIds: tAccountIds,
        categoryIds: tCategoryIds,
        compareToPrevious: false,
        transactionType: TransactionType.expense,
      ),
    );

    // assert
    expect(result, Right(tReportData));
    verify(
      () => mockReportRepository.getSpendingOverTime(
        startDate: tStartDate,
        endDate: tEndDate,
        granularity: tGranularity,
        accountIds: tAccountIds,
        categoryIds: tCategoryIds,
      ),
    );
    verifyNoMoreInteractions(mockReportRepository);
  });

  test(
    'should return a failure when repository call is unsuccessful',
    () async {
      // arrange
      when(
        () => mockReportRepository.getSpendingOverTime(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          granularity: any(named: 'granularity'),
          accountIds: any(named: 'accountIds'),
          categoryIds: any(named: 'categoryIds'),
        ),
      ).thenAnswer((_) async => Left(ServerFailure()));

      // act
      final result = await useCase(
        GetSpendingTimeReportParams(
          startDate: tStartDate,
          endDate: tEndDate,
          granularity: tGranularity,
          accountIds: tAccountIds,
          categoryIds: tCategoryIds,
          compareToPrevious: false,
        ),
      );

      // assert
      expect(result, Left(ServerFailure()));
      verify(
        () => mockReportRepository.getSpendingOverTime(
          startDate: tStartDate,
          endDate: tEndDate,
          granularity: tGranularity,
          accountIds: tAccountIds,
          categoryIds: tCategoryIds,
        ),
      );
      verifyNoMoreInteractions(mockReportRepository);
    },
  );
}
