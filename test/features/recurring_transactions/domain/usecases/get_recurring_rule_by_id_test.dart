import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/get_recurring_rule_by_id.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringTransactionRepository extends Mock
    implements RecurringTransactionRepository {}

void main() {
  late GetRecurringRuleById usecase;
  late MockRecurringTransactionRepository mockRepository;

  setUp(() {
    mockRepository = MockRecurringTransactionRepository();
    usecase = GetRecurringRuleById(mockRepository);
  });

  const tId = 'rule1';
  final tRule = RecurringRule(
    id: tId,
    description: 'Test Rule',
    amount: 100,
    transactionType: TransactionType.expense,
    accountId: 'acc1',
    categoryId: 'cat1',
    frequency: Frequency.monthly,
    interval: 1,
    startDate: DateTime(2023, 1, 1),
    endConditionType: EndConditionType.never,
    status: RuleStatus.active,
    nextOccurrenceDate: DateTime(2023, 2, 1),
    occurrencesGenerated: 0,
  );

  test('should get recurring rule by id from repository', () async {
    // Arrange
    when(
      () => mockRepository.getRecurringRuleById(tId),
    ).thenAnswer((_) async => Right(tRule));

    // Act
    final result = await usecase(tId);

    // Assert
    expect(result, Right(tRule));
    verify(() => mockRepository.getRecurringRuleById(tId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure if repository fails', () async {
    // Arrange
    when(
      () => mockRepository.getRecurringRuleById(tId),
    ).thenAnswer((_) async => const Left(CacheFailure('Failed')));

    // Act
    final result = await usecase(tId);

    // Assert
    expect(result, const Left(CacheFailure('Failed')));
    verify(() => mockRepository.getRecurringRuleById(tId)).called(1);
  });
}
