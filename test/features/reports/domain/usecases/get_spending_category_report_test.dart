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

  const tReportData = SpendingCategoryReportData(
    totalSpending: ComparisonValue(currentValue: 1000.0),
    spendingByCategory: [],
  );

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  final tParams = GetSpendingCategoryReportParams(
    startDate: tStartDate,
    endDate: tEndDate,
    accountIds: const ['a1'],
    compareToPrevious: true,
  );

  test('should get spending category report from repository', () async {
    // arrange
    when(
      () => mockReportRepository.getSpendingByCategory(
        startDate: tStartDate,
        endDate: tEndDate,
        accountIds: ['a1'],
      ),
    ).thenAnswer((_) async => const Right(tReportData));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result, const Right(tReportData));
    verify(
      () => mockReportRepository.getSpendingByCategory(
        startDate: tStartDate,
        endDate: tEndDate,
        accountIds: ['a1'],
      ),
    ).called(1);
    verifyNoMoreInteractions(mockReportRepository);
  });
}
