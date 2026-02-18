import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/update_expense.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class FakeExpense extends Fake implements Expense {}

void main() {
  late UpdateExpenseUseCase useCase;
  late MockExpenseRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeExpense());
  });

  setUp(() {
    mockRepository = MockExpenseRepository();
    useCase = UpdateExpenseUseCase(mockRepository);
  });

  final tExpense = Expense(
    id: '1',
    title: 'Groceries',
    amount: 50.0,
    date: DateTime(2024, 1, 1),
    accountId: 'acc1',
  );

  test('should update expense in repository when validation passes', () async {
    // Arrange
    when(
      () => mockRepository.updateExpense(any()),
    ).thenAnswer((_) async => Right(tExpense));

    // Act
    final result = await useCase(UpdateExpenseParams(tExpense));

    // Assert
    expect(result, Right(tExpense));
    verify(() => mockRepository.updateExpense(tExpense)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ValidationFailure when title is empty', () async {
    // Arrange
    final invalidExpense = tExpense.copyWith(title: '');

    // Act
    final result = await useCase(UpdateExpenseParams(invalidExpense));

    // Assert
    expect(result, const Left(ValidationFailure("Title cannot be empty.")));
    verifyZeroInteractions(mockRepository);
  });

  test(
    'should return ValidationFailure when amount is zero or negative',
    () async {
      // Arrange
      final invalidExpense = tExpense.copyWith(amount: 0);

      // Act
      final result = await useCase(UpdateExpenseParams(invalidExpense));

      // Assert
      expect(result, const Left(ValidationFailure("Amount must be positive.")));
      verifyZeroInteractions(mockRepository);
    },
  );

  test('should return ValidationFailure when accountId is empty', () async {
    // Arrange
    final invalidExpense = tExpense.copyWith(accountId: '');

    // Act
    final result = await useCase(UpdateExpenseParams(invalidExpense));

    // Assert
    expect(result, const Left(ValidationFailure("Please select an account.")));
    verifyZeroInteractions(mockRepository);
  });

  test('should return Failure when repository fails', () async {
    // Arrange
    when(
      () => mockRepository.updateExpense(any()),
    ).thenAnswer((_) async => const Left(CacheFailure("Cache Error")));

    // Act
    final result = await useCase(UpdateExpenseParams(tExpense));

    // Assert
    expect(result, const Left(CacheFailure("Cache Error")));
    verify(() => mockRepository.updateExpense(tExpense)).called(1);
  });
}
