import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/recurring_transactions/data/datasources/recurring_transaction_local_data_source.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/repositories/recurring_transaction_repository_impl.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringTransactionLocalDataSource extends Mock
    implements RecurringTransactionLocalDataSource {}

void main() {
  late RecurringTransactionRepositoryImpl repository;
  late MockRecurringTransactionLocalDataSource mockDataSource;

  setUpAll(() {
    registerFallbackValue(
      RecurringRuleModel(
        id: '',
        description: '',
        amount: 0,
        transactionTypeIndex: 0,
        accountId: '',
        categoryId: '',
        frequencyIndex: 0,
        interval: 1,
        startDate: DateTime.now(),
        endConditionTypeIndex: 0,
        statusIndex: 0,
        nextOccurrenceDate: DateTime.now(),
        occurrencesGenerated: 0,
      ),
    );
  });

  setUp(() {
    mockDataSource = MockRecurringTransactionLocalDataSource();
    repository = RecurringTransactionRepositoryImpl(dataSource: mockDataSource);
  });

  final tRule = RecurringRule(
    id: '1',
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
  final tRuleModel = RecurringRuleModel.fromEntity(tRule);

  test('should return list of rules from dataSource', () async {
    // Arrange
    when(() => mockDataSource.getRecurringRules())
        .thenAnswer((_) async => [tRuleModel]);

    // Act
    final result = await repository.getRecurringRules();

    // Assert
    expect(result, Right([tRule]));
    verify(() => mockDataSource.getRecurringRules()).called(1);
  });

  test('should return failure when dataSource throws', () async {
    // Arrange
    when(() => mockDataSource.getRecurringRules())
        .thenThrow(const CacheFailure('Failed'));

    // Act
    final result = await repository.getRecurringRules();

    // Assert
    expect(result, const Left(CacheFailure('Failed')));
  });

  test('should save rule to dataSource', () async {
    // Arrange
    when(() => mockDataSource.saveRecurringRule(any()))
        .thenAnswer((_) async => {});

    // Act
    final result = await repository.addRecurringRule(tRule);

    // Assert
    expect(result, const Right(null));
    verify(() => mockDataSource.saveRecurringRule(tRuleModel)).called(1);
  });
}
