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

  setUpAll(() {
    registerFallbackValue(TimeSeriesGranularity.daily);
  });

  setUp(() {
    mockReportRepository = MockReportRepository();
    useCase = GetSpendingTimeReportUseCase(mockReportRepository);
  });

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  const tGranularity = TimeSeriesGranularity.daily;
  const tAccountIds = ['1', '2'];
  const tCategoryIds = ['cat1', 'cat2'];

  const tReportData = SpendingTimeReportData(
    spendingData: [],
    granularity: tGranularity,
  );

  test('should call getSpendingOverTime from repository', () async {
    // Arrange
    when(() => mockReportRepository.getSpendingOverTime(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          granularity: any(named: 'granularity'),
          accountIds: any(named: 'accountIds'),
          categoryIds: any(named: 'categoryIds'),
        )).thenAnswer((_) async => const Right(tReportData));

    // Act
    final result = await useCase(GetSpendingTimeReportParams(
      startDate: tStartDate,
      endDate: tEndDate,
      granularity: tGranularity,
      accountIds: tAccountIds,
      categoryIds: tCategoryIds,
      compareToPrevious: false,
    ));

    // Assert
    expect(result, const Right(tReportData));
    verify(() => mockReportRepository.getSpendingOverTime(
          startDate: tStartDate,
          endDate: tEndDate,
          granularity: tGranularity,
          accountIds: tAccountIds,
          categoryIds: tCategoryIds,
        )).called(1);
  });
}
