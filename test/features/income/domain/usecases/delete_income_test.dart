import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/income/domain/usecases/delete_income.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_helpers.dart';

void main() {
  late DeleteIncomeUseCase useCase;
  late MockIncomeRepository mockRepository;

  setUp(() {
    mockRepository = MockIncomeRepository();
    useCase = DeleteIncomeUseCase(mockRepository);
    registerFallbackValues();
  });

  const tId = 'test_id';
  const tParams = DeleteIncomeParams(tId);

  test('should call deleteIncome on the repository', () async {
    // Arrange
    when(() => mockRepository.deleteIncome(any()))
        .thenAnswer((_) async => const Right(null));

    // Act
    final result = await useCase(tParams);

    // Assert
    expect(result, const Right(null));
    verify(() => mockRepository.deleteIncome(tId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should propagate Failure from repository', () async {
    // Arrange
    when(() => mockRepository.deleteIncome(any()))
        .thenAnswer((_) async => const Left(CacheFailure("Error")));

    // Act
    final result = await useCase(tParams);

    // Assert
    expect(result, const Left(CacheFailure("Error")));
    verify(() => mockRepository.deleteIncome(tId)).called(1);
  });
}
