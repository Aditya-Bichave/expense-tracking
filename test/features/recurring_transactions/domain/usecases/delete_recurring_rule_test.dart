
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

  const tRuleId = '1';

  test('should delete a recurring rule from the repository', () async {
    // arrange
    when(() => mockRepository.deleteRecurringRule(any()))
        .thenAnswer((_) async => const Right(null));
    // act
    final result = await useCase(tRuleId);
    // assert
    expect(result, const Right(null));
    verify(() => mockRepository.deleteRecurringRule(tRuleId));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return a failure when the repository call is unsuccessful',
      () async {
    // arrange
    when(() => mockRepository.deleteRecurringRule(any()))
        .thenAnswer((_) async => Left(ServerFailure('Server Failure')));
    // act
    final result = await useCase(tRuleId);
    // assert
    expect(result, Left(ServerFailure('Server Failure')));
    verify(() => mockRepository.deleteRecurringRule(tRuleId));
    verifyNoMoreInteractions(mockRepository);
  });
}
