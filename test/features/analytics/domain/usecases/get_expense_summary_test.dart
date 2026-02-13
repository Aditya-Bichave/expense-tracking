import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/analytics/domain/usecases/get_expense_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_helpers.dart';

void main() {
  late GetExpenseSummaryUseCase useCase;
  late MockExpenseRepository mockExpenseRepository;

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    useCase = GetExpenseSummaryUseCase(mockExpenseRepository);
  });

  const tExpenseSummary = ExpenseSummary(
    totalExpenses: 100.0,
    categoryBreakdown: {'Food': 60.0, 'Transport': 40.0},
  );

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  final tParams = GetSummaryParams(startDate: tStartDate, endDate: tEndDate);

  test(
    'should return ExpenseSummary from the repository when successful',
    () async {
      // Arrange
      when(() => mockExpenseRepository.getExpenseSummary(
            startDate: tStartDate,
            endDate: tEndDate,
          )).thenAnswer((_) async => const Right(tExpenseSummary));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Right(tExpenseSummary));
      verify(() => mockExpenseRepository.getExpenseSummary(
            startDate: tStartDate,
            endDate: tEndDate,
          )).called(1);
      verifyNoMoreInteractions(mockExpenseRepository);
    },
  );

  test(
    'should return Failure from the repository when it fails',
    () async {
      // Arrange
      const tFailure = ServerFailure('Server Error');
      when(() => mockExpenseRepository.getExpenseSummary(
            startDate: tStartDate,
            endDate: tEndDate,
          )).thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result, const Left(tFailure));
      verify(() => mockExpenseRepository.getExpenseSummary(
            startDate: tStartDate,
            endDate: tEndDate,
          )).called(1);
      verifyNoMoreInteractions(mockExpenseRepository);
    },
  );
}
