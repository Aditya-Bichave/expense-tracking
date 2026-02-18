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

class FakeRecurringRule extends Fake implements RecurringRule {}

void main() {
  late AddRecurringRule useCase;
  late MockRecurringTransactionRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeRecurringRule());
  });

  setUp(() {
    mockRepository = MockRecurringTransactionRepository();
    useCase = AddRecurringRule(mockRepository);
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

  test('should add recurring rule to repository', () async {
    // Arrange
    when(
      () => mockRepository.addRecurringRule(any()),
    ).thenAnswer((_) async => const Right(null));

    // Act
    final result = await useCase(tRecurringRule);

    // Assert
    expect(result, const Right(null));
    verify(() => mockRepository.addRecurringRule(tRecurringRule)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // Arrange
    when(
      () => mockRepository.addRecurringRule(any()),
    ).thenAnswer((_) async => const Left(CacheFailure('Error')));

    // Act
    final result = await useCase(tRecurringRule);

    // Assert
    expect(result, const Left(CacheFailure('Error')));
    verify(() => mockRepository.addRecurringRule(tRecurringRule)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
