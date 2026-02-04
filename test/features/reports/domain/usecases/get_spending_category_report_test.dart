import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_spending_category_report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReportRepository extends Mock implements ReportRepository {}

void main() {
  late GetSpendingCategoryReportUseCase useCase;
  late MockReportRepository mockReportRepository;

  setUp(() {
    mockReportRepository = MockReportRepository();
    useCase = GetSpendingCategoryReportUseCase(mockReportRepository);
  });

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  const tAccountIds = ['1', '2'];

  const tReportData = SpendingCategoryReportData(
    totalSpending: ComparisonValue(currentValue: 100.0),
    spendingByCategory: [],
  );

  test('should call getSpendingByCategory from repository', () async {
    // Arrange
    when(() => mockReportRepository.getSpendingByCategory(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountIds: any(named: 'accountIds'),
        )).thenAnswer((_) async => const Right(tReportData));

    // Act
    final result = await useCase(GetSpendingCategoryReportParams(
      startDate: tStartDate,
      endDate: tEndDate,
      accountIds: tAccountIds,
      compareToPrevious: false,
    ));

    // Assert
    expect(result, const Right(tReportData));
    verify(() => mockReportRepository.getSpendingByCategory(
          startDate: tStartDate,
          endDate: tEndDate,
          accountIds: tAccountIds,
        )).called(1);
  });
}
