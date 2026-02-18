import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_audit_log.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/add_audit_log.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/get_recurring_rule_by_id.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/update_recurring_rule.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockRecurringTransactionRepository extends Mock
    implements RecurringTransactionRepository {}

class MockGetRecurringRuleById extends Mock implements GetRecurringRuleById {}

class MockAddAuditLog extends Mock implements AddAuditLog {}

class MockUuid extends Mock implements Uuid {}

class FakeRecurringRule extends Fake implements RecurringRule {}

class FakeRecurringRuleAuditLog extends Fake implements RecurringRuleAuditLog {}

void main() {
  late UpdateRecurringRule useCase;
  late MockRecurringTransactionRepository mockRepository;
  late MockGetRecurringRuleById mockGetRecurringRuleById;
  late MockAddAuditLog mockAddAuditLog;
  late MockUuid mockUuid;

  setUpAll(() {
    registerFallbackValue(FakeRecurringRule());
    registerFallbackValue(FakeRecurringRuleAuditLog());
  });

  setUp(() {
    mockRepository = MockRecurringTransactionRepository();
    mockGetRecurringRuleById = MockGetRecurringRuleById();
    mockAddAuditLog = MockAddAuditLog();
    mockUuid = MockUuid();

    useCase = UpdateRecurringRule(
      repository: mockRepository,
      getRecurringRuleById: mockGetRecurringRuleById,
      addAuditLog: mockAddAuditLog,
      uuid: mockUuid,
      userId: 'user1',
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

  final tUpdatedRule = tRecurringRule.copyWith(amount: 1200.0);

  test('should update recurring rule and add audit logs', () async {
    // Arrange
    when(
      () => mockGetRecurringRuleById(any()),
    ).thenAnswer((_) async => Right(tRecurringRule));
    when(() => mockUuid.v4()).thenReturn('log1');
    when(
      () => mockAddAuditLog(any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => mockRepository.updateRecurringRule(any()),
    ).thenAnswer((_) async => const Right(null));

    // Act
    final result = await useCase(tUpdatedRule);

    // Assert
    expect(result, const Right(null));
    verify(() => mockGetRecurringRuleById(tUpdatedRule.id)).called(1);
    // Should add log because amount changed
    verify(() => mockAddAuditLog(any())).called(1);
    verify(() => mockRepository.updateRecurringRule(tUpdatedRule)).called(1);
  });

  test('should return failure when getRecurringRuleById fails', () async {
    // Arrange
    when(
      () => mockGetRecurringRuleById(any()),
    ).thenAnswer((_) async => const Left(CacheFailure('Error')));

    // Act
    final result = await useCase(tUpdatedRule);

    // Assert
    expect(result, const Left(CacheFailure('Error')));
    verify(() => mockGetRecurringRuleById(tUpdatedRule.id)).called(1);
    verifyZeroInteractions(mockAddAuditLog);
    verifyZeroInteractions(mockRepository);
  });
}
