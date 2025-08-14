import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/add_expense.dart';
import 'package:expense_tracker/features/income/domain/usecases/add_income.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/generate_transactions_on_launch.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockRecurringTransactionRepository extends Mock
    implements RecurringTransactionRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockAddExpenseUseCase extends Mock implements AddExpenseUseCase {}

class MockAddIncomeUseCase extends Mock implements AddIncomeUseCase {}

class MockUuid extends Mock implements Uuid {}

class _RecurringRuleFake extends Fake implements RecurringRule {}

void main() {
  late GenerateTransactionsOnLaunch usecase;
  late MockRecurringTransactionRepository mockRecurringTransactionRepository;
  late MockCategoryRepository mockCategoryRepository;
  late MockAddExpenseUseCase mockAddExpenseUseCase;
  late MockAddIncomeUseCase mockAddIncomeUseCase;
  late MockUuid mockUuid;

  setUpAll(() {
    registerFallbackValue(AddExpenseParams(Expense(
      id: '',
      title: '',
      amount: 0,
      date: DateTime.now(),
      accountId: '',
    )));
    registerFallbackValue(AddIncomeParams(Income(
      id: '',
      title: '',
      amount: 0,
      date: DateTime.now(),
      accountId: '',
    )));
    registerFallbackValue(_RecurringRuleFake());
  });

  setUp(() {
    mockRecurringTransactionRepository = MockRecurringTransactionRepository();
    mockCategoryRepository = MockCategoryRepository();
    mockAddExpenseUseCase = MockAddExpenseUseCase();
    mockAddIncomeUseCase = MockAddIncomeUseCase();
    mockUuid = MockUuid();
    usecase = GenerateTransactionsOnLaunch(
      recurringTransactionRepository: mockRecurringTransactionRepository,
      categoryRepository: mockCategoryRepository,
      addExpense: mockAddExpenseUseCase,
      addIncome: mockAddIncomeUseCase,
      uuid: mockUuid,
    );
  });

  final tRule = RecurringRule(
    id: '1',
    description: 'Test Expense',
    amount: 50,
    transactionType: TransactionType.expense,
    accountId: 'acc1',
    categoryId: 'cat1',
    frequency: Frequency.monthly,
    dayOfMonth: 15,
    interval: 1,
    startDate: DateTime(2023, 1, 15),
    endConditionType: EndConditionType.never,
    status: RuleStatus.active,
    nextOccurrenceDate: DateTime.now().subtract(const Duration(days: 1)),
    occurrencesGenerated: 5,
  );

  final tCategory = const Category(
    id: 'cat1',
    name: 'Test Category',
    iconName: 'icon',
    colorHex: '#FFFFFF',
    type: CategoryType.expense,
    isCustom: false,
  );

  final tExpense = Expense(
    id: 'new_id',
    title: tRule.description,
    amount: tRule.amount,
    date: tRule.nextOccurrenceDate,
    category: tCategory,
    accountId: tRule.accountId,
    isRecurring: true,
  );

  test('should generate a transaction for a due rule', () async {
    // Arrange
    when(() => mockRecurringTransactionRepository.getRecurringRules())
        .thenAnswer((_) async => Right([tRule]));
    when(() => mockCategoryRepository.getCategoryById(any()))
        .thenAnswer((_) async => Right(tCategory));
    when(() => mockAddExpenseUseCase(any()))
        .thenAnswer((_) async => Right(tExpense));
    when(() => mockRecurringTransactionRepository.updateRecurringRule(any()))
        .thenAnswer((_) async => const Right(null));
    when(() => mockUuid.v4()).thenReturn('new_id');

    // Act
    await usecase(const NoParams());

    // Assert
    verify(() => mockAddExpenseUseCase(any())).called(1);
    verify(() => mockRecurringTransactionRepository.updateRecurringRule(any()))
        .called(1);
  });

  test('should not generate a transaction for a future rule', () async {
    // Arrange
    final futureRule = RecurringRule(
      id: '2',
      description: 'Future Expense',
      amount: 20,
      transactionType: TransactionType.expense,
      accountId: 'acc1',
      categoryId: 'cat1',
      frequency: Frequency.monthly,
      dayOfMonth: 15,
      interval: 1,
      startDate: DateTime(2023, 1, 15),
      endConditionType: EndConditionType.never,
      status: RuleStatus.active,
      nextOccurrenceDate: DateTime.now().add(const Duration(days: 1)),
      occurrencesGenerated: 0,
    );

    when(() => mockRecurringTransactionRepository.getRecurringRules())
        .thenAnswer((_) async => Right([futureRule]));

    // Act
    await usecase(const NoParams());

    // Assert
    verifyNever(() => mockAddExpenseUseCase(any()));
    verifyNever(() => mockAddIncomeUseCase(any()));
    verifyNever(() =>
        mockRecurringTransactionRepository.updateRecurringRule(any()));
  });

  test(
      'should return failure and not generate transaction when category lookup fails',
      () async {
    // Arrange
    final failure = CacheFailure('cache error');
    when(() => mockRecurringTransactionRepository.getRecurringRules())
        .thenAnswer((_) async => Right([tRule]));
    when(() => mockCategoryRepository.getCategoryById(any()))
        .thenAnswer((_) async => Left(failure));

    // Act
    final result = await usecase(const NoParams());

    // Assert
    expect(result, Left(failure));
    verifyNever(() => mockAddExpenseUseCase(any()));
    verifyNever(() => mockAddIncomeUseCase(any()));
    verifyNever(
        () => mockRecurringTransactionRepository.updateRecurringRule(any()));
  });
}
