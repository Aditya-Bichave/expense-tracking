import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/analytics/domain/usecases/get_expense_summary.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late GetExpenseSummaryUseCase useCase;
  late MockExpenseRepository mockExpenseRepository;

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    useCase = GetExpenseSummaryUseCase(mockExpenseRepository);
  });

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  final tParams = GetSummaryParams(startDate: tStartDate, endDate: tEndDate);

  final tExpenseSummary = const ExpenseSummary(
    totalExpenses: 100.0,
    categoryBreakdown: {},
  );

  test('should get expense summary from the repository', () async {
    // arrange
    when(() => mockExpenseRepository.getExpenseSummary(
          startDate: tStartDate,
          endDate: tEndDate,
        )).thenAnswer((_) async => Right(tExpenseSummary));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result, Right(tExpenseSummary));
    verify(() => mockExpenseRepository.getExpenseSummary(
          startDate: tStartDate,
          endDate: tEndDate,
        ));
    verifyNoMoreInteractions(mockExpenseRepository);
  });

  test('should return a Failure when the repository call is unsuccessful',
      () async {
    // arrange
    when(() => mockExpenseRepository.getExpenseSummary(
          startDate: tStartDate,
          endDate: tEndDate,
        )).thenAnswer((_) async => const Left(CacheFailure('Error')));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result, const Left(CacheFailure('Error')));
    verify(() => mockExpenseRepository.getExpenseSummary(
          startDate: tStartDate,
          endDate: tEndDate,
        ));
    verifyNoMoreInteractions(mockExpenseRepository);
  });
}
