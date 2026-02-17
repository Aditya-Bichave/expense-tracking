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

    registerFallbackValue(TimeSeriesGranularity.daily);
  });

  const tReportData = SpendingTimeReportData(
    spendingData: [],
    granularity: TimeSeriesGranularity.daily,
  );

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  final tParams = GetSpendingTimeReportParams(
    startDate: tStartDate,
    endDate: tEndDate,
    granularity: TimeSeriesGranularity.daily,
    accountIds: const ['a1'],
    categoryIds: const ['c1'],
    compareToPrevious: true,
  );

  test('should get spending time report from repository', () async {
    // arrange
    when(() => mockReportRepository.getSpendingOverTime(
          startDate: tStartDate,
          endDate: tEndDate,
          granularity: TimeSeriesGranularity.daily,
          accountIds: ['a1'],
          categoryIds: ['c1'],
        )).thenAnswer((_) async => const Right(tReportData));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result, const Right(tReportData));
    verify(() => mockReportRepository.getSpendingOverTime(
          startDate: tStartDate,
          endDate: tEndDate,
          granularity: TimeSeriesGranularity.daily,
          accountIds: ['a1'],
          categoryIds: ['c1'],
        )).called(1);
    verifyNoMoreInteractions(mockReportRepository);
  });
}
