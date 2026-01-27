import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_spending_category_report.dart';
import 'package:flutter/material.dart';
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
  final tParams = GetSpendingCategoryReportParams(
    startDate: tStartDate,
    endDate: tEndDate,
    compareToPrevious: false,
  );

  final tCategoryData = CategorySpendingData(
    categoryId: '1',
    categoryName: 'Food',
    categoryColor: Colors.red,
    totalAmount: const ComparisonValue(currentValue: 100),
    percentage: 10.0,
  );

  final tReportData = SpendingCategoryReportData(
    totalSpending: const ComparisonValue(currentValue: 1000),
    spendingByCategory: [tCategoryData],
  );

  test('should get spending category report from the repository', () async {
    // arrange
    when(() => mockReportRepository.getSpendingByCategory(
          startDate: tStartDate,
          endDate: tEndDate,
          accountIds: null,
        )).thenAnswer((_) async => Right(tReportData));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result, Right(tReportData));
    verify(() => mockReportRepository.getSpendingByCategory(
          startDate: tStartDate,
          endDate: tEndDate,
          accountIds: null,
        ));
    verifyNoMoreInteractions(mockReportRepository);
  });
}
