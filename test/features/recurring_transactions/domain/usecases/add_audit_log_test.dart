import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_audit_log.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/add_audit_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringTransactionRepository extends Mock
    implements RecurringTransactionRepository {}

void main() {
  late AddAuditLog usecase;
  late MockRecurringTransactionRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      RecurringRuleAuditLog(
        id: '',
        ruleId: '',
        timestamp: DateTime.now(),
        userId: '',
        fieldChanged: '',
        oldValue: '',
        newValue: '',
      ),
    );
  });

  setUp(() {
    mockRepository = MockRecurringTransactionRepository();
    usecase = AddAuditLog(mockRepository);
  });

  final tLog = RecurringRuleAuditLog(
    id: '1',
    ruleId: 'rule1',
    timestamp: DateTime(2023, 1, 1),
    userId: 'user1',
    fieldChanged: 'amount',
    oldValue: '10',
    newValue: '20',
  );

  test('should add audit log to repository', () async {
    // Arrange
    when(() => mockRepository.addAuditLog(any()))
        .thenAnswer((_) async => const Right(null));

    // Act
    final result = await usecase(tLog);

    // Assert
    expect(result, const Right(null));
    verify(() => mockRepository.addAuditLog(tLog)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
