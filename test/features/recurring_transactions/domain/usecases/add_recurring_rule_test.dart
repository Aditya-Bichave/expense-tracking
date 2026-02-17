
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/add_recurring_rule.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringTransactionRepository extends Mock
    implements RecurringTransactionRepository {}

void main() {
  late AddRecurringRule useCase;
  late MockRecurringTransactionRepository mockRepository;

  setUp(() {
    mockRepository = MockRecurringTransactionRepository();
    useCase = AddRecurringRule(mockRepository);
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
  });

  final tRule = RecurringRule(
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

  test('should add a recurring rule to the repository', () async {
    // arrange
    when(() => mockRepository.addRecurringRule(any()))
        .thenAnswer((_) async => const Right(null));
    // act
    final result = await useCase(tRule);
    // assert
    expect(result, const Right(null));
    verify(() => mockRepository.addRecurringRule(tRule));
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return a failure when the repository call is unsuccessful',
      () async {
    // arrange
    when(() => mockRepository.addRecurringRule(any()))
        .thenAnswer((_) async => Left(ServerFailure('Server Failure')));
    // act
    final result = await useCase(tRule);
    // assert
    expect(result, Left(ServerFailure('Server Failure')));
    verify(() => mockRepository.addRecurringRule(tRule));
    verifyNoMoreInteractions(mockRepository);
  });
}
