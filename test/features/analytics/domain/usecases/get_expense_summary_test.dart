import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/analytics/domain/usecases/get_expense_summary.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late GetExpenseSummaryUseCase usecase;
  late MockExpenseRepository mockExpenseRepository;

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    usecase = GetExpenseSummaryUseCase(mockExpenseRepository);
  });

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  final tParams = GetSummaryParams(startDate: tStartDate, endDate: tEndDate);
  const tExpenseSummary = ExpenseSummary(
    totalExpenses: 100.0,
    categoryBreakdown: {'Food': 100.0},
  );

  test('should return ExpenseSummary from the repository', () async {
    // arrange
    when(() => mockExpenseRepository.getExpenseSummary(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => const Right(tExpenseSummary));

    // act
    final result = await usecase(tParams);

    // assert
    expect(result, const Right(tExpenseSummary));
    verify(() => mockExpenseRepository.getExpenseSummary(
          startDate: tStartDate,
          endDate: tEndDate,
        ));
    verifyNoMoreInteractions(mockExpenseRepository);
  });

  test('should return Failure when repository fails', () async {
    // arrange
    const tFailure = CacheFailure('Error');
    when(() => mockExpenseRepository.getExpenseSummary(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(tParams);

    // assert
    expect(result, const Left(tFailure));
    verify(() => mockExpenseRepository.getExpenseSummary(
          startDate: tStartDate,
          endDate: tEndDate,
        ));
    verifyNoMoreInteractions(mockExpenseRepository);
  });
}
