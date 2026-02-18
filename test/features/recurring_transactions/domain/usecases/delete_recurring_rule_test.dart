import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/delete_recurring_rule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringTransactionRepository extends Mock
    implements RecurringTransactionRepository {}

void main() {
  late DeleteRecurringRule useCase;
  late MockRecurringTransactionRepository mockRepository;

  setUp(() {
    mockRepository = MockRecurringTransactionRepository();
    useCase = DeleteRecurringRule(mockRepository);
  });

  const tId = '1';

  test('should delete recurring rule from repository', () async {
    // Arrange
    when(
      () => mockRepository.deleteRecurringRule(any()),
    ).thenAnswer((_) async => const Right(null));

    // Act
    final result = await useCase(tId);

    // Assert
    expect(result, const Right(null));
    verify(() => mockRepository.deleteRecurringRule(tId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // Arrange
    when(
      () => mockRepository.deleteRecurringRule(any()),
    ).thenAnswer((_) async => const Left(CacheFailure('Error')));

    // Act
    final result = await useCase(tId);

    // Assert
    expect(result, const Left(CacheFailure('Error')));
    verify(() => mockRepository.deleteRecurringRule(tId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
