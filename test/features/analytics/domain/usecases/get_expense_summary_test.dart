import 'package:dartz/dartz.dart';
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

  const tStartDate = null;
  const tEndDate = null;
  const tParams = GetSummaryParams(startDate: tStartDate, endDate: tEndDate);
  const tExpenseSummary = ExpenseSummary(
    totalExpenses: 100.0,
    categoryBreakdown: {'Food': 50.0, 'Transport': 50.0},
  );

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
          ));
      verifyNoMoreInteractions(mockExpenseRepository);
    },
  );
}
