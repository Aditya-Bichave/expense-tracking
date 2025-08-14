import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/pause_resume_recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/update_recurring_rule.dart';
import 'package:expense_tracker/core/services/auth_service.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringTransactionRepository extends Mock
    implements RecurringTransactionRepository {}

class MockUpdateRecurringRule extends Mock implements UpdateRecurringRule {}

class MockAuthService extends Mock implements AuthService {}

void main() {
  final tActiveRule = RecurringRule(
    id: '1',
    description: 'Test',
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
    occurrencesGenerated: 1,
  );

  late PauseResumeRecurringRule usecase;
  late MockRecurringTransactionRepository mockRepository;
  late MockUpdateRecurringRule mockUpdateRecurringRule;
  late MockAuthService mockAuthService;

  setUp(() {
    mockRepository = MockRecurringTransactionRepository();
    mockUpdateRecurringRule = MockUpdateRecurringRule();
    mockAuthService = MockAuthService();
    registerFallbackValue(
        UpdateRecurringRuleParams(newRule: tActiveRule, userId: 'user-1'));
    usecase = PauseResumeRecurringRule(
      repository: mockRepository,
      updateRecurringRule: mockUpdateRecurringRule,
      authService: mockAuthService,
    );
    registerFallbackValue(
      RecurringRule(
        id: '',
        description: '',
        amount: 0,
        transactionType: TransactionType.expense,
        accountId: '',
        categoryId: '',
        frequency: Frequency.monthly,
        interval: 1,
        startDate: DateTime.now(),
        endConditionType: EndConditionType.never,
        status: RuleStatus.active,
        nextOccurrenceDate: DateTime.now(),
        occurrencesGenerated: 0,
      ),
    );
  });

  test('should pause an active rule', () async {
    // Arrange
    when(
      () => mockRepository.getRecurringRuleById(any()),
    ).thenAnswer((_) async => Right(tActiveRule));
    when(() => mockAuthService.getCurrentUserId()).thenReturn('user-1');
    when(
      () => mockUpdateRecurringRule(any()),
    ).thenAnswer((_) async => const Right(null));

    // Act
    await usecase('1');

    // Assert
    final captured = verify(() => mockUpdateRecurringRule(captureAny()))
        .captured
        .single as UpdateRecurringRuleParams;
    expect(captured.newRule.status, RuleStatus.paused);
    expect(captured.userId, 'user-1');
  });
}
