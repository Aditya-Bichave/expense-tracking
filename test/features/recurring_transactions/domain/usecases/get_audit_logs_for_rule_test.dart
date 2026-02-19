import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_audit_log.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/get_audit_logs_for_rule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringTransactionRepository extends Mock
    implements RecurringTransactionRepository {}

void main() {
  late GetAuditLogsForRule usecase;
  late MockRecurringTransactionRepository mockRepository;

  setUp(() {
    mockRepository = MockRecurringTransactionRepository();
    usecase = GetAuditLogsForRule(mockRepository);
  });

  const tRuleId = 'rule1';
  final tLog = RecurringRuleAuditLog(
    id: '1',
    ruleId: tRuleId,
    timestamp: DateTime(2023, 1, 1),
    userId: 'user1',
    fieldChanged: 'amount',
    oldValue: '10',
    newValue: '20',
  );

  test('should get audit logs for rule from repository', () async {
    // Arrange
    when(
      () => mockRepository.getAuditLogsForRule(tRuleId),
    ).thenAnswer((_) async => Right([tLog]));

    // Act
    final result = await usecase(tRuleId);

    // Assert
    expect(result.isRight(), true);
    result.fold((l) => fail('Should be Right'), (r) => expect(r, [tLog]));
    verify(() => mockRepository.getAuditLogsForRule(tRuleId)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
