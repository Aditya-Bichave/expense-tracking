
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/income/domain/usecases/add_income.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIncomeRepository extends Mock implements IncomeRepository {}

// Create a Fake Income class for fallback
class FakeIncome extends Fake implements Income {}

void main() {
  late AddIncomeUseCase useCase;
  late MockIncomeRepository mockRepository;

  setUpAll(() {
    // Register fallback value using Fake or actual instance
    registerFallbackValue(FakeIncome());
  });

  setUp(() {
    mockRepository = MockIncomeRepository();
    useCase = AddIncomeUseCase(mockRepository);
  });

  final tIncome = Income(
    id: '1',
    title: 'Salary',
    amount: 100.0,
    date: DateTime.now(),
    accountId: 'acc1',
  );

  test('should call repository.addIncome when validation passes', () async {
    // Arrange
    when(() => mockRepository.addIncome(any()))
        .thenAnswer((_) async => Right(tIncome));

    // Act
    final result = await useCase(AddIncomeParams(tIncome));

    // Assert
    verify(() => mockRepository.addIncome(tIncome)).called(1);
    expect(result, Right(tIncome));
  });

  test('should return ValidationFailure when title is empty', () async {
    // Arrange
    final invalidIncome = tIncome.copyWith(title: '');

    // Act
    final result = await useCase(AddIncomeParams(invalidIncome));

    // Assert
    verifyNever(() => mockRepository.addIncome(any()));
    expect(result.isLeft(), true);
    expect(
        result.fold((l) => l, (r) => null), isA<ValidationFailure>());
  });

  test('should return ValidationFailure when amount is zero or negative', () async {
    // Arrange
    final invalidIncome = tIncome.copyWith(amount: 0);

    // Act
    final result = await useCase(AddIncomeParams(invalidIncome));

    // Assert
    verifyNever(() => mockRepository.addIncome(any()));
    expect(result.isLeft(), true);
  });

  test('should return ValidationFailure when accountId is empty', () async {
    // Arrange
    final invalidIncome = tIncome.copyWith(accountId: '');

    // Act
    final result = await useCase(AddIncomeParams(invalidIncome));

    // Assert
    verifyNever(() => mockRepository.addIncome(any()));
    expect(result.isLeft(), true);
  });
}
