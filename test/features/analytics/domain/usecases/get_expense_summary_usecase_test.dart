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

  const tExpenseSummary = ExpenseSummary(
    totalExpenses: 500,
    categoryBreakdown: {'Food': 300, 'Rent': 200},
  );

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  final tParams = GetSummaryParams(startDate: tStartDate, endDate: tEndDate);

  test(
    'should get expense summary from the repository',
    () async {
      // arrange
      when(() => mockExpenseRepository.getExpenseSummary(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          )).thenAnswer((_) async => const Right(tExpenseSummary));

      // act
      final result = await useCase(tParams);

      // assert
      expect(result, const Right(tExpenseSummary));
      verify(() => mockExpenseRepository.getExpenseSummary(
            startDate: tStartDate,
            endDate: tEndDate,
          )).called(1);
      verifyNoMoreInteractions(mockExpenseRepository);
    },
  );

  test(
    'should return a Failure when the repository call is unsuccessful',
    () async {
      // arrange
      when(() => mockExpenseRepository.getExpenseSummary(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
          )).thenAnswer((_) async => const Left(CacheFailure()));

      // act
      final result = await useCase(tParams);

      // assert
      expect(result, const Left(CacheFailure()));
      verify(() => mockExpenseRepository.getExpenseSummary(
            startDate: tStartDate,
            endDate: tEndDate,
          )).called(1);
      verifyNoMoreInteractions(mockExpenseRepository);
    },
  );
}
