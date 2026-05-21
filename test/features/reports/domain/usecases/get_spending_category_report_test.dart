import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_spending_category_report.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
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
  final tAccountIds = ['account1'];

  final tSpendingByCategory = [
    CategorySpendingData(
      categoryId: 'cat1',
      categoryName: 'Food',
      categoryColor: Colors.red,
      totalAmount: ComparisonValue(currentValue: 100.0),
      percentage: 20.0,
    ),
  ];

  final tReportData = SpendingCategoryReportData(
    totalSpending: ComparisonValue(currentValue: 500.0),
    spendingByCategory: tSpendingByCategory,
  );

  test('should get spending category report from the repository', () async {
    // arrange
    when(
      () => mockReportRepository.getSpendingByCategory(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        accountIds: any(named: 'accountIds'),
      ),
    ).thenAnswer((_) async => Right(tReportData));

    // act
    final result = await useCase(
      GetSpendingCategoryReportParams(
        startDate: tStartDate,
        endDate: tEndDate,
        accountIds: tAccountIds,
        compareToPrevious: false,
        transactionType: TransactionType.expense,
      ),
    );

    // assert
    expect(result, Right(tReportData));
    verify(
      () => mockReportRepository.getSpendingByCategory(
        startDate: tStartDate,
        endDate: tEndDate,
        accountIds: tAccountIds,
      ),
    );
    verifyNoMoreInteractions(mockReportRepository);
  });

  test(
    'should return a failure when repository call is unsuccessful',
    () async {
      // arrange
      when(
        () => mockReportRepository.getSpendingByCategory(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountIds: any(named: 'accountIds'),
        ),
      ).thenAnswer((_) async => Left(ServerFailure()));

      // act
      final result = await useCase(
        GetSpendingCategoryReportParams(
          startDate: tStartDate,
          endDate: tEndDate,
          accountIds: tAccountIds,
          compareToPrevious: false,
        ),
      );

      // assert
      expect(result, Left(ServerFailure()));
      verify(
        () => mockReportRepository.getSpendingByCategory(
          startDate: tStartDate,
          endDate: tEndDate,
          accountIds: tAccountIds,
        ),
      );
      verifyNoMoreInteractions(mockReportRepository);
    },
  );
}
