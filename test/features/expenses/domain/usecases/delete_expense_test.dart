import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/delete_expense.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late DeleteExpenseUseCase useCase;
  late MockExpenseRepository mockRepository;

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = DeleteExpenseUseCase(mockRepository);
  });

  const tId = '1';

  test('should delete expense from repository', () async {
    // Arrange
    when(() => mockRepository.deleteExpense(any()))
        .thenAnswer((_) async => const Right(null));

    // Act
    final result = await useCase(const DeleteExpenseParams(tId));

    // Assert
    expect(result, const Right(null));
    verify(() => mockRepository.deleteExpense(tId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return Failure when repository fails', () async {
    // Arrange
    when(() => mockRepository.deleteExpense(any()))
        .thenAnswer((_) async => const Left(CacheFailure("Delete failed")));

    // Act
    final result = await useCase(const DeleteExpenseParams(tId));

    // Assert
    expect(result, const Left(CacheFailure("Delete failed")));
    verify(() => mockRepository.deleteExpense(tId)).called(1);
  });
}
