import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/usecases/update_income.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_helpers.dart';

class _FakeIncome extends Fake implements Income {}

void main() {
  late UpdateIncomeUseCase useCase;
  late MockIncomeRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(_FakeIncome());
  });

  setUp(() {
    mockRepository = MockIncomeRepository();
    useCase = UpdateIncomeUseCase(mockRepository);
    registerFallbackValues();
  });

  final tIncome = Income(
    id: '1',
    title: 'Salary',
    amount: 5000.0,
    date: DateTime.fromMillisecondsSinceEpoch(0),
    accountId: 'acc1',
    category: const Category(
      id: 'cat1',
      name: 'Salary',
      iconName: 'work',
      colorHex: '#000000',
      type: CategoryType.income,
      isCustom: false,
    ),
    notes: 'Monthly salary',
    status: CategorizationStatus.categorized,
    confidenceScore: 1.0,
    isRecurring: true,
  );

  final tParams = UpdateIncomeParams(tIncome);

  test('should call updateIncome on the repository when inputs are valid',
      () async {
    // Arrange
    when(() => mockRepository.updateIncome(any()))
        .thenAnswer((_) async => Right(tIncome));

    // Act
    final result = await useCase(tParams);

    // Assert
    expect(result, Right(tIncome));
    verify(() => mockRepository.updateIncome(tIncome)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ValidationFailure when title is empty', () async {
    // Arrange
    final invalidIncome = tIncome.copyWith(title: '');
    final invalidParams = UpdateIncomeParams(invalidIncome);

    // Act
    final result = await useCase(invalidParams);

    // Assert
    expect(result, const Left(ValidationFailure("Title cannot be empty.")));
    verifyZeroInteractions(mockRepository);
  });

  test('should return ValidationFailure when amount is zero', () async {
    // Arrange
    final invalidIncome = tIncome.copyWith(amount: 0.0);
    final invalidParams = UpdateIncomeParams(invalidIncome);

    // Act
    final result = await useCase(invalidParams);

    // Assert
    expect(result, const Left(ValidationFailure("Amount must be positive.")));
    verifyZeroInteractions(mockRepository);
  });

  test('should return ValidationFailure when accountId is empty', () async {
    // Arrange
    final invalidIncome = tIncome.copyWith(accountId: '');
    final invalidParams = UpdateIncomeParams(invalidIncome);

    // Act
    final result = await useCase(invalidParams);

    // Assert
    expect(result, const Left(ValidationFailure("Please select an account.")));
    verifyZeroInteractions(mockRepository);
  });

  test('should propagate Failure from repository', () async {
    // Arrange
    when(() => mockRepository.updateIncome(any()))
        .thenAnswer((_) async => const Left(CacheFailure("Error")));

    // Act
    final result = await useCase(tParams);

    // Assert
    expect(result, const Left(CacheFailure("Error")));
    verify(() => mockRepository.updateIncome(tIncome)).called(1);
  });
}
