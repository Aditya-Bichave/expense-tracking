
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

  final tRules = [tRule];

  test('should get recurring rules from the repository', () async {
    // arrange
    when(() => mockRepository.getRecurringRules())
        .thenAnswer((_) async => Right(tRules));
    // act
    final result = await useCase(NoParams());
    // assert
    expect(result, Right(tRules));
    verify(() => mockRepository.getRecurringRules());
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return a failure when the repository call is unsuccessful',
      () async {
    // arrange
    when(() => mockRepository.getRecurringRules())
        .thenAnswer((_) async => Left(ServerFailure('Server Failure')));
    // act
    final result = await useCase(NoParams());
    // assert
    expect(result, Left(ServerFailure('Server Failure')));
    verify(() => mockRepository.getRecurringRules());
    verifyNoMoreInteractions(mockRepository);
  });
}
