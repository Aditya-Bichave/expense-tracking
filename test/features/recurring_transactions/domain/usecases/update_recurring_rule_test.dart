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

class MockRecurringTransactionRepository extends Mock implements RecurringTransactionRepository {}
class MockGetRecurringRuleById extends Mock implements GetRecurringRuleById {}
class MockAddAuditLog extends Mock implements AddAuditLog {}
class MockUuid extends Mock implements Uuid {}

void main() {
  late UpdateRecurringRule usecase;
  late MockRecurringTransactionRepository mockRepository;
  late MockGetRecurringRuleById mockGetRecurringRuleById;
  late MockAddAuditLog mockAddAuditLog;
  late MockUuid mockUuid;

  final tOldRule = RecurringRule(
    id: '1',
    description: 'Old Description',
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

  final tNewRule = tOldRule.copyWith(description: 'New Description', amount: 150);

  setUpAll(() {
    registerFallbackValue(tOldRule);
    registerFallbackValue(
      RecurringRuleAuditLog(
        id: 'log',
        ruleId: 'rule',
        timestamp: DateTime(2023, 1, 1),
        userId: 'user',
        fieldChanged: 'field',
        oldValue: 'old',
        newValue: 'new',
      ),
    );
  });

  setUp(() {
    mockRepository = MockRecurringTransactionRepository();
    mockGetRecurringRuleById = MockGetRecurringRuleById();
    mockAddAuditLog = MockAddAuditLog();
    mockUuid = MockUuid();
    usecase = UpdateRecurringRule(
      repository: mockRepository,
      getRecurringRuleById: mockGetRecurringRuleById,
      addAuditLog: mockAddAuditLog,
      uuid: mockUuid,
    );
  });

  test('should create audit logs for changed fields', () async {
    // Arrange
    when(() => mockGetRecurringRuleById(any())).thenAnswer((_) async => Right(tOldRule));
    when(() => mockAddAuditLog(any())).thenAnswer((_) async => const Right(null));
    when(() => mockRepository.updateRecurringRule(any())).thenAnswer((_) async => const Right(null));
    when(() => mockUuid.v4()).thenReturn('new_log_id');

    // Act
    await usecase(tNewRule);

    // Assert
    verify(() => mockAddAuditLog(any())).called(2); // For description and amount
    verify(() => mockRepository.updateRecurringRule(tNewRule)).called(1);
  });

  test('should return failure and not update when an audit log fails', () async {
    // Arrange
    const failure = ServerFailure();
    when(() => mockGetRecurringRuleById(any())).thenAnswer((_) async => Right(tOldRule));
    when(() => mockAddAuditLog(any())).thenAnswer((_) async => Left(failure));
    when(() => mockRepository.updateRecurringRule(any())).thenAnswer((_) async => const Right(null));
    when(() => mockUuid.v4()).thenReturn('new_log_id');

    // Act
    final result = await usecase(tNewRule);

    // Assert
    expect(result, equals(Left(failure)));
    verify(() => mockAddAuditLog(any())).called(1);
    verifyNever(() => mockRepository.updateRecurringRule(any()));
  });
}
