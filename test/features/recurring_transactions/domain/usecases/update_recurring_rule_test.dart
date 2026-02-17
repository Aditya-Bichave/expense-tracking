
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

void main() {
  late UpdateRecurringRule useCase;
  late MockRecurringTransactionRepository mockRepository;
  late MockGetRecurringRuleById mockGetRecurringRuleById;
  late MockAddAuditLog mockAddAuditLog;
  late MockUuid mockUuid;

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

    registerFallbackValue(
      RecurringRule(
        id: '1',
        amount: 100.0,
        description: 'Rent',
        categoryId: 'cat1',
        accountId: 'acc1',
        transactionType: TransactionType.expense,
        frequency: Frequency.monthly,
        interval: 1,
        startDate: DateTime(2023, 1, 1),
        endConditionType: EndConditionType.never,
        status: RuleStatus.active,
        nextOccurrenceDate: DateTime(2023, 2, 1),
        occurrencesGenerated: 0,
      ),
    );
    registerFallbackValue(
      RecurringRuleAuditLog(
        id: '1',
        ruleId: '1',
        timestamp: DateTime(2023, 1, 1),
        userId: 'user1',
        fieldChanged: 'amount',
        oldValue: '100.0',
        newValue: '120.0',
      ),
    );
  });

  final tRule = RecurringRule(
    id: '1',
    amount: 120.0, // Changed amount
    description: 'Rent',
    categoryId: 'cat1',
    accountId: 'acc1',
    transactionType: TransactionType.expense,
    frequency: Frequency.monthly,
    interval: 1,
    startDate: DateTime(2023, 1, 1),
    endConditionType: EndConditionType.never,
    status: RuleStatus.active,
    nextOccurrenceDate: DateTime(2023, 2, 1),
    occurrencesGenerated: 0,
  );

  final tOldRule = RecurringRule(
    id: '1',
    amount: 100.0,
    description: 'Rent',
    categoryId: 'cat1',
    accountId: 'acc1',
    transactionType: TransactionType.expense,
    frequency: Frequency.monthly,
    interval: 1,
    startDate: DateTime(2023, 1, 1),
    endConditionType: EndConditionType.never,
    status: RuleStatus.active,
    nextOccurrenceDate: DateTime(2023, 2, 1),
    occurrencesGenerated: 0,
  );

  test('should update a recurring rule in the repository and add audit logs',
      () async {
    // arrange
    when(() => mockGetRecurringRuleById(any()))
        .thenAnswer((_) async => Right(tOldRule));
    when(() => mockUuid.v4()).thenReturn('log1');
    when(() => mockAddAuditLog(any()))
        .thenAnswer((_) async => const Right(null));
    when(() => mockRepository.updateRecurringRule(any()))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await useCase(tRule);

    // assert
    expect(result, const Right(null));
    verify(() => mockGetRecurringRuleById(tRule.id));
    // Verify audit log for amount change
    verify(() => mockAddAuditLog(any())).called(1);
    verify(() => mockRepository.updateRecurringRule(tRule));
  });

  test('should return failure when getting old rule fails', () async {
    // arrange
    when(() => mockGetRecurringRuleById(any()))
        .thenAnswer((_) async => Left(ServerFailure('Fetch Failed')));

    // act
    final result = await useCase(tRule);

    // assert
    expect(result, Left(ServerFailure('Fetch Failed')));
    verify(() => mockGetRecurringRuleById(tRule.id));
    verifyZeroInteractions(mockAddAuditLog);
    verifyZeroInteractions(mockRepository);
  });
}
