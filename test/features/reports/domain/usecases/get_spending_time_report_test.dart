import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_spending_time_report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReportRepository extends Mock implements ReportRepository {}

void main() {
  late GetSpendingTimeReportUseCase useCase;
  late MockReportRepository mockReportRepository;

  setUp(() {
    mockReportRepository = MockReportRepository();
    useCase = GetSpendingTimeReportUseCase(mockReportRepository);
  });

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  final tParams = GetSpendingTimeReportParams(
    startDate: tStartDate,
    endDate: tEndDate,
    granularity: TimeSeriesGranularity.daily,
    compareToPrevious: false,
  );

  final tDataPoint = TimeSeriesDataPoint(
    date: tStartDate,
    amount: const ComparisonValue(currentValue: 50),
  );

  final tReportData = SpendingTimeReportData(
    spendingData: [tDataPoint],
    granularity: TimeSeriesGranularity.daily,
  );

  test('should get spending time report from the repository', () async {
    // arrange
    when(() => mockReportRepository.getSpendingOverTime(
          startDate: tStartDate,
          endDate: tEndDate,
          granularity: TimeSeriesGranularity.daily,
          accountIds: null,
          categoryIds: null,
        )).thenAnswer((_) async => Right(tReportData));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result, Right(tReportData));
    verify(() => mockReportRepository.getSpendingOverTime(
          startDate: tStartDate,
          endDate: tEndDate,
          granularity: TimeSeriesGranularity.daily,
          accountIds: null,
          categoryIds: null,
        ));
    verifyNoMoreInteractions(mockReportRepository);
  });
}
