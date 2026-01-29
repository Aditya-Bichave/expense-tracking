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

  const tSummary = ExpenseSummary(
    totalExpenses: 100.0,
    categoryBreakdown: {'Food': 100.0},
  );
  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  const tParams = GetSummaryParams(startDate: null, endDate: null);

  test('should get expense summary from the repository', () async {
    // Arrange
    when(() => mockExpenseRepository.getExpenseSummary(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => const Right(tSummary));

    // Act
    final result = await useCase(GetSummaryParams(startDate: tStartDate, endDate: tEndDate));

    // Assert
    expect(result, const Right(tSummary));
    verify(() => mockExpenseRepository.getExpenseSummary(
          startDate: tStartDate,
          endDate: tEndDate,
        )).called(1);
    verifyNoMoreInteractions(mockExpenseRepository);
  });

  test('should return a failure when the repository fails', () async {
    // Arrange
    when(() => mockExpenseRepository.getExpenseSummary(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => Left(CacheFailure()));

    // Act
    final result = await useCase(tParams);

    // Assert
    expect(result, Left(CacheFailure()));
    verify(() => mockExpenseRepository.getExpenseSummary(
          startDate: null,
          endDate: null,
        )).called(1);
    verifyNoMoreInteractions(mockExpenseRepository);
  });
}
