import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/income/domain/usecases/delete_income.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIncomeRepository extends Mock implements IncomeRepository {}

void main() {
  late DeleteIncomeUseCase useCase;
  late MockIncomeRepository mockRepository;

  setUp(() {
    mockRepository = MockIncomeRepository();
    useCase = DeleteIncomeUseCase(mockRepository);
  });

  const tId = '1';

  test('should delete income from repository', () async {
    // Arrange
    when(
      () => mockRepository.deleteIncome(any()),
    ).thenAnswer((_) async => const Right(null));

    // Act
    final result = await useCase(const DeleteIncomeParams(tId));

    // Assert
    expect(result, const Right(null));
    verify(() => mockRepository.deleteIncome(tId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return Failure when repository fails', () async {
    // Arrange
    when(
      () => mockRepository.deleteIncome(any()),
    ).thenAnswer((_) async => const Left(CacheFailure("Delete failed")));

    // Act
    final result = await useCase(const DeleteIncomeParams(tId));

    // Assert
    expect(result, const Left(CacheFailure("Delete failed")));
    verify(() => mockRepository.deleteIncome(tId)).called(1);
  });
}
