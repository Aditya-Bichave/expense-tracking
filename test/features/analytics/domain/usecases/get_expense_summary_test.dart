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
  late MockExpenseRepository mockRepository;

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = GetExpenseSummaryUseCase(mockRepository);
  });

  const tExpenseSummary = ExpenseSummary(
    totalExpenses: 100.0,
    categoryBreakdown: {'Food': 100.0},
  );

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  final tParams = GetSummaryParams(startDate: tStartDate, endDate: tEndDate);

  test('should get expense summary from the repository', () async {
    // arrange
    when(() => mockRepository.getExpenseSummary(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => const Right(tExpenseSummary));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result, const Right(tExpenseSummary));
    verify(() => mockRepository.getExpenseSummary(
          startDate: tStartDate,
          endDate: tEndDate,
        )).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return a failure when the repository call is unsuccessful',
      () async {
    // arrange
    when(() => mockRepository.getExpenseSummary(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => const Left(CacheFailure('Error')));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result, const Left(CacheFailure('Error')));
    verify(() => mockRepository.getExpenseSummary(
          startDate: tStartDate,
          endDate: tEndDate,
        )).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
