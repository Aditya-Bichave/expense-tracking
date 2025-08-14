import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/add_expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
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
    registerFallbackValue(RecurringRule(
      id: '',
      description: '',
      amount: 0,
      transactionType: TransactionType.expense,
      accountId: '',
      categoryId: '',
      frequency: Frequency.monthly,
      dayOfMonth: 1,
      interval: 1,
      startDate: DateTime.now(),
      endConditionType: EndConditionType.never,
      status: RuleStatus.active,
      nextOccurrenceDate: DateTime.now(),
      occurrencesGenerated: 0,
    ));
  });

  setUp(() {
    mockRecurringTransactionRepository = MockRecurringTransactionRepository();
    mockCategoryRepository = MockCategoryRepository();
    mockAddExpenseUseCase = MockAddExpenseUseCase();
    mockAddIncomeUseCase = MockAddIncomeUseCase();
    mockUuid = MockUuid();
    when(() => mockUuid.v4()).thenReturn('new_id');
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

  final tIncomeRule = tRule.copyWith(
    id: 'income_1',
    description: 'Test Income',
    transactionType: TransactionType.income,
    categoryId: 'cat2',
  );

  final tIncomeCategory = const Category(
    id: 'cat2',
    name: 'Income Category',
    iconName: 'icon',
    colorHex: '#FFFFFF',
    type: CategoryType.income,
    isCustom: false,
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
    verifyNever(
        () => mockRecurringTransactionRepository.updateRecurringRule(any()));
  });

  test('should return failure when addExpense fails', () async {
    // Arrange
    const failure = ServerFailure('addExpense failed');
    when(() => mockRecurringTransactionRepository.getRecurringRules())
        .thenAnswer((_) async => Right([tRule]));
    when(() => mockCategoryRepository.getCategoryById(any()))
        .thenAnswer((_) async => Right(tCategory));
    when(() => mockAddExpenseUseCase(any()))
        .thenAnswer((_) async => const Left(failure));

    // Act
    final result = await usecase(const NoParams());

    // Assert
    expect(result, equals(const Left(failure)));
    verify(() => mockAddExpenseUseCase(any())).called(1);
    verifyNever(
        () => mockRecurringTransactionRepository.updateRecurringRule(any()));
  });

  test('should return failure when addIncome fails', () async {
    // Arrange
    const failure = ServerFailure('addIncome failed');
    when(() => mockRecurringTransactionRepository.getRecurringRules())
        .thenAnswer((_) async => Right([tIncomeRule]));
    when(() => mockCategoryRepository.getCategoryById(any()))
        .thenAnswer((_) async => Right(tIncomeCategory));
    when(() => mockAddIncomeUseCase(any()))
        .thenAnswer((_) async => const Left(failure));

    // Act
    final result = await usecase(const NoParams());

    // Assert
    expect(result, equals(const Left(failure)));
    verify(() => mockAddIncomeUseCase(any())).called(1);
    verifyNever(
        () => mockRecurringTransactionRepository.updateRecurringRule(any()));
  });

  test('should return failure when updateRecurringRule fails', () async {
    // Arrange
    const failure = ServerFailure('updateRecurringRule failed');
    when(() => mockRecurringTransactionRepository.getRecurringRules())
        .thenAnswer((_) async => Right([tRule]));
    when(() => mockCategoryRepository.getCategoryById(any()))
        .thenAnswer((_) async => Right(tCategory));
    when(() => mockAddExpenseUseCase(any()))
        .thenAnswer((_) async => Right(tExpense));
    when(() => mockRecurringTransactionRepository.updateRecurringRule(any()))
        .thenAnswer((_) async => const Left(failure));

    // Act
    final result = await usecase(const NoParams());

    // Assert
    expect(result, equals(const Left(failure)));
    verify(() => mockAddExpenseUseCase(any())).called(1);
    verify(() => mockRecurringTransactionRepository.updateRecurringRule(any()))
        .called(1);
  });

  test('should return failure when category lookup fails', () async {
    // Arrange
    const failure = ServerFailure('getCategoryById failed');
    when(() => mockRecurringTransactionRepository.getRecurringRules())
        .thenAnswer((_) async => Right([tRule]));
    when(() => mockCategoryRepository.getCategoryById(any()))
        .thenAnswer((_) async => const Left(failure));

    // Act
    final result = await usecase(const NoParams());

    // Assert
    expect(result, equals(const Left(failure)));
    verify(() => mockCategoryRepository.getCategoryById(any())).called(1);
    verifyNever(() => mockAddExpenseUseCase(any()));
    verifyNever(
        () => mockRecurringTransactionRepository.updateRecurringRule(any()));
  });

  test('should handle monthly rule without dayOfMonth by defaulting to current day',
      () async {
    // Arrange
    final ruleWithoutDayOfMonth = RecurringRule(
      id: '3',
      description: 'No dayOfMonth',
      amount: 40,
      transactionType: TransactionType.expense,
      accountId: 'acc1',
      categoryId: 'cat1',
      frequency: Frequency.monthly,
      interval: 1,
      startDate: DateTime(2023, 1, 31),
      endConditionType: EndConditionType.never,
      status: RuleStatus.active,
      nextOccurrenceDate: DateTime(2023, 1, 31),
      occurrencesGenerated: 0,
    );

    final expectedNextDate = DateTime(2023, 2, 28);

    when(() => mockRecurringTransactionRepository.getRecurringRules())
        .thenAnswer((_) async => Right([ruleWithoutDayOfMonth]));
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
    final captured = verify(() =>
            mockRecurringTransactionRepository.updateRecurringRule(captureAny()))
        .captured
        .single as RecurringRule;
    expect(captured.nextOccurrenceDate, expectedNextDate);
  });
}
