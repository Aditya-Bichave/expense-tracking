import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/income/domain/usecases/update_income.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIncomeRepository extends Mock implements IncomeRepository {}

class FakeIncome extends Fake implements Income {}

void main() {
  late UpdateIncomeUseCase useCase;
  late MockIncomeRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeIncome());
  });

  setUp(() {
    mockRepository = MockIncomeRepository();
    useCase = UpdateIncomeUseCase(mockRepository);
  });

  final tIncome = Income(
    id: '1',
    title: 'Salary',
    amount: 5000.0,
    date: DateTime(2024, 1, 1),
    accountId: 'acc1',
  );

  test('should update income in repository when validation passes', () async {
    // Arrange
    when(() => mockRepository.updateIncome(any()))
        .thenAnswer((_) async => Right(tIncome));

    // Act
    final result = await useCase(UpdateIncomeParams(tIncome));

    // Assert
    expect(result, Right(tIncome));
    verify(() => mockRepository.updateIncome(tIncome)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ValidationFailure when title is empty', () async {
    // Arrange
    final invalidIncome = tIncome.copyWith(title: '');

    // Act
    final result = await useCase(UpdateIncomeParams(invalidIncome));

    // Assert
    expect(result, const Left(ValidationFailure("Title cannot be empty.")));
    verifyZeroInteractions(mockRepository);
  });

  test('should return ValidationFailure when amount is zero or negative', () async {
    // Arrange
    final invalidIncome = tIncome.copyWith(amount: 0);

    // Act
    final result = await useCase(UpdateIncomeParams(invalidIncome));

    // Assert
    expect(result, const Left(ValidationFailure("Amount must be positive.")));
    verifyZeroInteractions(mockRepository);
  });

  test('should return ValidationFailure when accountId is empty', () async {
    // Arrange
    final invalidIncome = tIncome.copyWith(accountId: '');

    // Act
    final result = await useCase(UpdateIncomeParams(invalidIncome));

    // Assert
    expect(result, const Left(ValidationFailure("Please select an account.")));
    verifyZeroInteractions(mockRepository);
  });

  test('should return Failure when repository fails', () async {
    // Arrange
    when(() => mockRepository.updateIncome(any()))
        .thenAnswer((_) async => const Left(CacheFailure("Cache Error")));

    // Act
    final result = await useCase(UpdateIncomeParams(tIncome));

    // Assert
    expect(result, const Left(CacheFailure("Cache Error")));
    verify(() => mockRepository.updateIncome(tIncome)).called(1);
  });
}
