import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/pause_resume_recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/update_recurring_rule.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringTransactionRepository extends Mock
    implements RecurringTransactionRepository {}

class MockUpdateRecurringRule extends Mock implements UpdateRecurringRule {}

class FakeRecurringRule extends Fake implements RecurringRule {}

void main() {
  late PauseResumeRecurringRule useCase;
  late MockRecurringTransactionRepository mockRepository;
  late MockUpdateRecurringRule mockUpdateRecurringRule;

  setUpAll(() {
    registerFallbackValue(FakeRecurringRule());
  });

  setUp(() {
    mockRepository = MockRecurringTransactionRepository();
    mockUpdateRecurringRule = MockUpdateRecurringRule();
    useCase = PauseResumeRecurringRule(
      repository: mockRepository,
      updateRecurringRule: mockUpdateRecurringRule,
    );
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

  test('should pause an active rule', () async {
    // Arrange
    when(
      () => mockRepository.getRecurringRuleById(any()),
    ).thenAnswer((_) async => Right(tRecurringRule));
    when(
      () => mockUpdateRecurringRule(any()),
    ).thenAnswer((_) async => const Right(null));

    // Act
    final result = await useCase(tRecurringRule.id);

    // Assert
    expect(result, const Right(null));
    verify(() => mockRepository.getRecurringRuleById(tRecurringRule.id)).called(1);
    final updatedRule = tRecurringRule.copyWith(status: RuleStatus.paused);
    verify(() => mockUpdateRecurringRule(updatedRule)).called(1);
  });

  test('should resume a paused rule', () async {
    // Arrange
    final tPausedRule = tRecurringRule.copyWith(status: RuleStatus.paused);
    when(
      () => mockRepository.getRecurringRuleById(any()),
    ).thenAnswer((_) async => Right(tPausedRule));
    when(
      () => mockUpdateRecurringRule(any()),
    ).thenAnswer((_) async => const Right(null));

    // Act
    final result = await useCase(tPausedRule.id);

    // Assert
    expect(result, const Right(null));
    verify(() => mockRepository.getRecurringRuleById(tPausedRule.id)).called(1);
    final updatedRule = tPausedRule.copyWith(status: RuleStatus.active);
    verify(() => mockUpdateRecurringRule(updatedRule)).called(1);
  });
}
