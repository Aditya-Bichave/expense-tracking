import 'package:dartz/dartz.dart';
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

  const tExpenseSummary = ExpenseSummary(
    totalExpenses: 100.0,
    categoryBreakdown: {'Food': 100.0},
  );
  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  final tParams = GetSummaryParams(startDate: tStartDate, endDate: tEndDate);

  test(
    'should get expense summary from the repository',
    () async {
      // arrange
      when(() => mockExpenseRepository.getExpenseSummary(
            startDate: tStartDate,
            endDate: tEndDate,
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
    },
  );

  test(
    'should return null for start and end dates when params are empty',
    () async {
      // arrange
      when(() => mockExpenseRepository.getExpenseSummary(
            startDate: null,
            endDate: null,
          )).thenAnswer((_) async => const Right(tExpenseSummary));
      // act
      final result = await usecase(const GetSummaryParams());
      // assert
      expect(result, const Right(tExpenseSummary));
      verify(() => mockExpenseRepository.getExpenseSummary(
            startDate: null,
            endDate: null,
          ));
      verifyNoMoreInteractions(mockExpenseRepository);
    },
  );
}
