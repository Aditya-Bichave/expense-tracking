import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/get_recurring_rules.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringTransactionRepository extends Mock
    implements RecurringTransactionRepository {}

void main() {
  late GetRecurringRules useCase;
  late MockRecurringTransactionRepository mockRepository;

  setUp(() {
    mockRepository = MockRecurringTransactionRepository();
    useCase = GetRecurringRules(mockRepository);
  });

  final tRecurringRule = RecurringRule(
    id: '1',
    description: 'Rent',
    amount: 1000.0,
    frequency: Frequency.monthly,
    interval: 1,
    nextOccurrenceDate: DateTime.now(),
    startDate: DateTime.now(),
    status: RuleStatus.active,
    occurrencesGenerated: 0,
    categoryId: 'cat1',
    accountId: 'acc1',
    transactionType: TransactionType.expense,
    endConditionType: EndConditionType.never,
  );

  test('should get recurring rules from repository', () async {
    // Arrange
    when(
      () => mockRepository.getRecurringRules(),
    ).thenAnswer((_) async => Right([tRecurringRule]));

    // Act
    final result = await useCase(const NoParams());

    // Assert
    expect(result.isRight(), isTrue);
    result.fold(
      (failure) => fail('Should have returned Right'),
      (rules) {
        expect(rules.length, 1);
        expect(rules.first, tRecurringRule);
      }
    );
    verify(() => mockRepository.getRecurringRules()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // Arrange
    when(
      () => mockRepository.getRecurringRules(),
    ).thenAnswer((_) async => const Left(CacheFailure('Error')));

    // Act
    final result = await useCase(const NoParams());

    // Assert
    expect(result, const Left(CacheFailure('Error')));
    verify(() => mockRepository.getRecurringRules()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
