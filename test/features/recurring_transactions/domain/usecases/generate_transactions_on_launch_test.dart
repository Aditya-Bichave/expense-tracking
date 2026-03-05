import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
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

void main() {
  late GenerateTransactionsOnLaunch usecase;
  late MockRecurringTransactionRepository mockRecurringTransactionRepository;
  late MockCategoryRepository mockCategoryRepository;
  late MockAddExpenseUseCase mockAddExpenseUseCase;
  late MockAddIncomeUseCase mockAddIncomeUseCase;
  late MockUuid mockUuid;

  setUpAll(() {
    registerFallbackValue(
      RecurringRule(
        id: 'fallback',
        description: 'fallback',
        amount: 1,
        transactionType: TransactionType.expense,
        accountId: 'acc1',
        categoryId: 'cat1',
        frequency: Frequency.monthly,
        interval: 1,
        startDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
        endConditionType: EndConditionType.never,
        status: RuleStatus.active,
        nextOccurrenceDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
        occurrencesGenerated: 0,
      ),
    );
    registerFallbackValue(
      AddExpenseParams(
        Expense(
          id: '1',
          title: 'test',
          amount: 1,
          date: DateTime.now(),
          accountId: '1',
        ),
      ),
    );
    registerFallbackValue(
      AddIncomeParams(
        Income(
          id: '1',
          title: 'test',
          amount: 1,
          date: DateTime.now(),
          category: null,
          accountId: '1',
          notes: '',
        ),
      ),
    );
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
    when(() => mockUuid.v4()).thenReturn('new_id'); // Match tExpense ID
  });

  final tRule = RecurringRule(
    id: '1',
    description: 'Test Rule',
    amount: 10,
    transactionType: TransactionType.expense,
    accountId: 'acc1',
    categoryId: 'cat1',
    frequency: Frequency.monthly,
    interval: 1,
    startDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day), // Run for today
    endConditionType: EndConditionType.never,
    status: RuleStatus.active,
    nextOccurrenceDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day), // Run for today
    occurrencesGenerated: 0,
  );

  final tCategory = Category(
    id: 'cat1',
    name: 'Test Category',
    iconName: 'icon',
    colorHex: '#000000',
    type: CategoryType.expense,
    isCustom: false,
  );

  // Updated tExpense to match mockUuid.v4() return value 'new_id'
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

  final tIncomeCategory = Category(
    id: 'cat2',
    name: 'Income Category',
    iconName: 'icon',
    colorHex: '#FFFFFF',
    type: CategoryType.income,
    isCustom: false,
  );

  // Updated tIncome to match mockUuid.v4() return value 'new_id'
  final tIncome = Income(
    id: 'new_id',
    title: tIncomeRule.description,
    amount: tIncomeRule.amount,
    date: tIncomeRule.nextOccurrenceDate,
    category: tIncomeCategory,
    accountId: tIncomeRule.accountId,
    notes: '',
    isRecurring: true,
  );

  test('should clamp next occurrence date for monthly rules', () async {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    // Use a date in the past that would evaluate just once if we trick the repo, or set nextOccurrence to today.
    // Wait, if it's today, it will just jump to next month from today. If we want to test Jan -> Feb logic specifically:
    // We can just test calculateNextOccurrence directly, or mock the date, but since we can't, we just test with current date if it's Jan 31? No.
    // What if we test with an occurrence date of `today` but we force the rule to have dayOfMonth=31 and frequency=monthly, and we just look at the captured rule's nextOccurrenceDate?
    // Let's use a date in the current year. But we can't guarantee today is not the 31st.
    // The previous test logic expected one loop execution. We can achieve this by making `occurrencesGenerated` reach totalOccurrences so it terminates after 1 loop!
    final janRule = tRule.copyWith(
      startDate: DateTime(2023, 1, 31),
      nextOccurrenceDate: DateTime(2023, 1, 31),
      dayOfMonth: 31,
      endConditionType: EndConditionType.afterOccurrences,
      totalOccurrences: 1, // End immediately
    );

    when(
      () => mockRecurringTransactionRepository.getRecurringRules(),
    ).thenAnswer((_) async => Right([janRule]));
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => Right([tCategory]));
    when(
      () => mockAddExpenseUseCase(any()),
    ).thenAnswer((_) async => Right(tExpense));

    RecurringRule? capturedRule;
    when(
      () => mockRecurringTransactionRepository.updateRecurringRule(any()),
    ).thenAnswer((invocation) async {
      capturedRule = invocation.positionalArguments.first as RecurringRule;
      return const Right(null); // Stop loop intentionally for this test
    });

    await usecase(const NoParams());

    expect(capturedRule, isNotNull);
    expect(capturedRule!.nextOccurrenceDate, equals(DateTime(2023, 2, 28)));
  });

  test('should generate a transaction for a due rule', () async {
    when(
      () => mockRecurringTransactionRepository.getRecurringRules(),
    ).thenAnswer((_) async => Right([tRule]));
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => Right([tCategory]));
    when(
      () => mockAddExpenseUseCase(any()),
    ).thenAnswer((_) async => Right(tExpense));
    when(
      () => mockRecurringTransactionRepository.updateRecurringRule(any()),
    ).thenAnswer((_) async => const Right(null));

    await usecase(const NoParams());

    verify(() => mockCategoryRepository.getAllCategories()).called(1);
    verify(() => mockAddExpenseUseCase(any())).called(1);
    verify(
      () => mockRecurringTransactionRepository.updateRecurringRule(any()),
    ).called(1);
  });

  test('should not generate a transaction for a future rule', () async {
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

    when(
      () => mockRecurringTransactionRepository.getRecurringRules(),
    ).thenAnswer((_) async => Right([futureRule]));
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => Right([tCategory]));

    await usecase(const NoParams());

    verifyNever(() => mockAddExpenseUseCase(any()));
    verifyNever(() => mockAddIncomeUseCase(any()));
    verifyNever(
      () => mockRecurringTransactionRepository.updateRecurringRule(any()),
    );
  });

  test('should return failure when addExpense fails', () async {
    final runRule = tRule.copyWith(nextOccurrenceDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
    const failure = ServerFailure('addExpense failed');
    when(
      () => mockRecurringTransactionRepository.getRecurringRules(),
    ).thenAnswer((_) async => Right([runRule]));
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => Right([tCategory]));
    when(
      () => mockAddExpenseUseCase(any()),
    ).thenAnswer((_) async => const Left(failure));

    final result = await usecase(const NoParams());

    expect(result, equals(const Left(failure)));
    verify(() => mockAddExpenseUseCase(any())).called(1);
    verifyNever(
      () => mockRecurringTransactionRepository.updateRecurringRule(any()),
    );
  });

  test('should return failure when addIncome fails', () async {
    final runRule = tIncomeRule.copyWith(nextOccurrenceDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
    const failure = ServerFailure('addIncome failed');
    when(
      () => mockRecurringTransactionRepository.getRecurringRules(),
    ).thenAnswer((_) async => Right([runRule]));
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => Right([tIncomeCategory]));
    when(
      () => mockAddIncomeUseCase(any()),
    ).thenAnswer((_) async => const Left(failure));

    final result = await usecase(const NoParams());

    expect(result, equals(const Left(failure)));
    verify(() => mockAddIncomeUseCase(any())).called(1);
    verifyNever(
      () => mockRecurringTransactionRepository.updateRecurringRule(any()),
    );
  });

  test('should return failure when updateRecurringRule fails', () async {
    final runRule = tRule.copyWith(nextOccurrenceDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
    const failure = ServerFailure('updateRecurringRule failed');
    when(
      () => mockRecurringTransactionRepository.getRecurringRules(),
    ).thenAnswer((_) async => Right([runRule]));
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => Right([tCategory]));
    when(
      () => mockAddExpenseUseCase(any()),
    ).thenAnswer((_) async => Right(tExpense));
    when(
      () => mockRecurringTransactionRepository.updateRecurringRule(any()),
    ).thenAnswer((_) async => const Left(failure));

    final result = await usecase(const NoParams());

    expect(result, equals(const Left(failure)));
    verify(() => mockAddExpenseUseCase(any())).called(1);
    verify(
      () => mockRecurringTransactionRepository.updateRecurringRule(any()),
    ).called(1);
  });

  test('should return failure when category fetch fails', () async {
    final runRule = tRule.copyWith(nextOccurrenceDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
    const failure = ServerFailure('getAllCategories failed');
    when(
      () => mockRecurringTransactionRepository.getRecurringRules(),
    ).thenAnswer((_) async => Right([runRule]));
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => const Left(failure));

    final result = await usecase(const NoParams());

    expect(result, equals(const Left(failure)));
    verify(() => mockCategoryRepository.getAllCategories()).called(1);
    verifyNever(() => mockAddExpenseUseCase(any()));
    verifyNever(
      () => mockRecurringTransactionRepository.updateRecurringRule(any()),
    );
  });

  test(
    'should handle monthly rule without dayOfMonth by defaulting to current day',
    () async {
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
        endConditionType: EndConditionType.afterOccurrences,
        totalOccurrences: 1,
        status: RuleStatus.active,
        nextOccurrenceDate: DateTime(2023, 1, 31),
        occurrencesGenerated: 0,
      );

      final expectedNextDate = DateTime(2023, 2, 28, 0, 0, 0, 0, 0); // Explicit zeros for precision

      when(
        () => mockRecurringTransactionRepository.getRecurringRules(),
      ).thenAnswer((_) async => Right([ruleWithoutDayOfMonth]));
      when(
        () => mockCategoryRepository.getAllCategories(),
      ).thenAnswer((_) async => Right([tCategory]));
      when(
        () => mockAddExpenseUseCase(any()),
      ).thenAnswer((_) async => Right(tExpense));
      RecurringRule? capturedRule;
      when(
        () => mockRecurringTransactionRepository.updateRecurringRule(any()),
      ).thenAnswer((invocation) async {
        capturedRule = invocation.positionalArguments.first as RecurringRule;
        return const Right(null);
      });

      // Removed repetitive mockUuid setup as it's in setUp()

      await usecase(const NoParams());

      expect(capturedRule, isNotNull);
      expect(capturedRule!.nextOccurrenceDate, expectedNextDate);
    },
  );

  test(
    'should use original startDate day for monthly rule without dayOfMonth when previous month is shorter',
    () async {
      final ruleAfterShortMonth = RecurringRule(
        id: '4',
        description: 'After February',
        amount: 40,
        transactionType: TransactionType.expense,
        accountId: 'acc1',
        categoryId: 'cat1',
        frequency: Frequency.monthly,
        interval: 1,
        startDate: DateTime(2023, 1, 31),
        endConditionType: EndConditionType.afterOccurrences,
        totalOccurrences: 2,
        status: RuleStatus.active,
        nextOccurrenceDate: DateTime(2023, 2, 28), // Run for today or past
        occurrencesGenerated: 1, // Will reach 2 and complete
      );

      final expectedNextDate = DateTime(2023, 3, 31, 0, 0, 0, 0, 0); // Explicit zeros for precision

      when(
        () => mockRecurringTransactionRepository.getRecurringRules(),
      ).thenAnswer((_) async => Right([ruleAfterShortMonth]));
      when(
        () => mockCategoryRepository.getAllCategories(),
      ).thenAnswer((_) async => Right([tCategory]));
      when(
        () => mockAddExpenseUseCase(any()),
      ).thenAnswer((_) async => Right(tExpense));

      RecurringRule? capturedRule;
      when(
        () => mockRecurringTransactionRepository.updateRecurringRule(any()),
      ).thenAnswer((invocation) async {
        capturedRule = invocation.positionalArguments.first as RecurringRule;
        return const Right(null);
      });

      await usecase(const NoParams());

      expect(capturedRule, isNotNull);
      expect(capturedRule!.nextOccurrenceDate, expectedNextDate);
    },
  );

  // --- New Tests ---

  test('should process multiple due rules sequentially', () async {
    // Ensure they are due by setting nextOccurrenceDate to today or past
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    // Use endConditionType to make sure they only run once
    final rule1 = tRule.copyWith(id: 'r1', description: 'Rule 1', nextOccurrenceDate: today.subtract(const Duration(days: 1)), endConditionType: EndConditionType.afterOccurrences, totalOccurrences: 1);
    final rule2 = tRule.copyWith(id: 'r2', description: 'Rule 2', nextOccurrenceDate: today.subtract(const Duration(days: 1)), endConditionType: EndConditionType.afterOccurrences, totalOccurrences: 1);

    when(
      () => mockRecurringTransactionRepository.getRecurringRules(),
    ).thenAnswer((_) async => Right([rule1, rule2]));
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => Right([tCategory]));
    when(
      () => mockAddExpenseUseCase(any()),
    ).thenAnswer((_) async => Right(tExpense));
    when(
      () => mockRecurringTransactionRepository.updateRecurringRule(any()),
    ).thenAnswer((_) async => const Right(null));

    await usecase(const NoParams());

    verify(() => mockAddExpenseUseCase(any())).called(2);
    verify(
      () => mockRecurringTransactionRepository.updateRecurringRule(any()),
    ).called(2);
  });

  test('should handle missing category gracefully', () async {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final ruleWithMissingCategory = tRule.copyWith(categoryId: 'missing_cat', nextOccurrenceDate: today.subtract(const Duration(days: 1)), endConditionType: EndConditionType.afterOccurrences, totalOccurrences: 1);

    when(
      () => mockRecurringTransactionRepository.getRecurringRules(),
    ).thenAnswer((_) async => Right([ruleWithMissingCategory]));
    when(() => mockCategoryRepository.getAllCategories()).thenAnswer(
      (_) async => Right([tCategory]),
    ); // Category missing_cat not in list
    when(
      () => mockAddExpenseUseCase(any()),
    ).thenAnswer((_) async => Right(tExpense));
    when(
      () => mockRecurringTransactionRepository.updateRecurringRule(any()),
    ).thenAnswer((_) async => const Right(null));

    await usecase(const NoParams());

    final capturedParams =
        verify(() => mockAddExpenseUseCase(captureAny())).captured.single
            as AddExpenseParams;
    expect(capturedParams.expense.category, isNull); // Verify category is null
    verify(
      () => mockRecurringTransactionRepository.updateRecurringRule(any()),
    ).called(1);
  });

  test(
    'should mark rule as completed when total occurrences reached',
    () async {
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final finishingRule = tRule.copyWith(
        totalOccurrences: 5,
        occurrencesGenerated: 4, // This will be the 5th
        endConditionType: EndConditionType.afterOccurrences,
        nextOccurrenceDate: today.subtract(const Duration(days: 1)),
      );

      when(
        () => mockRecurringTransactionRepository.getRecurringRules(),
      ).thenAnswer((_) async => Right([finishingRule]));
      when(
        () => mockCategoryRepository.getAllCategories(),
      ).thenAnswer((_) async => Right([tCategory]));
      when(
        () => mockAddExpenseUseCase(any()),
      ).thenAnswer((_) async => Right(tExpense));
      when(
        () => mockRecurringTransactionRepository.updateRecurringRule(any()),
      ).thenAnswer((_) async => const Right(null));

      await usecase(const NoParams());

      final capturedList =
          verify(
                () => mockRecurringTransactionRepository.updateRecurringRule(
                  captureAny(),
                ),
              ).captured;
      final capturedRule = capturedList.first as RecurringRule;

      expect(capturedRule.status, RuleStatus.completed);
      expect(capturedRule.occurrencesGenerated, 5);
    },
  );

  test('should mark rule as completed when end date exceeded', () async {
    final finishingRule = tRule.copyWith(
      startDate: DateTime(2023, 1, 1),
      nextOccurrenceDate: DateTime(2023, 1, 1),
      endDate: DateTime(2023, 1, 2), // Next occurrence (calculated as feb) will be after this
      endConditionType: EndConditionType.onDate,
    );

    when(
      () => mockRecurringTransactionRepository.getRecurringRules(),
    ).thenAnswer((_) async => Right([finishingRule]));
    when(
      () => mockCategoryRepository.getAllCategories(),
    ).thenAnswer((_) async => Right([tCategory]));
    when(
      () => mockAddExpenseUseCase(any()),
    ).thenAnswer((_) async => Right(tExpense));
      RecurringRule? capturedRule;
    when(
      () => mockRecurringTransactionRepository.updateRecurringRule(any()),
      ).thenAnswer((invocation) async {
        capturedRule = invocation.positionalArguments.first as RecurringRule;
        return const Right(null);
      });

      await usecase(const NoParams());

      expect(capturedRule, isNotNull);
      expect(capturedRule!.status, RuleStatus.completed);
  });

  // Verify Leap Year Handling
  test(
    'should clamp Feb 29 to Feb 28 in non-leap years for yearly rules',
    () async {
      final leapYearRule = tRule.copyWith(
        frequency: Frequency.yearly,
        interval: 1,
        endConditionType: EndConditionType.afterOccurrences,
        totalOccurrences: 1, // Only run once
        // Feb 29, 2024 is a leap year date
        startDate: DateTime(2024, 2, 29),
        nextOccurrenceDate: DateTime(2024, 2, 29),
      );

      when(
        () => mockRecurringTransactionRepository.getRecurringRules(),
      ).thenAnswer((_) async => Right([leapYearRule]));
      when(
        () => mockCategoryRepository.getAllCategories(),
      ).thenAnswer((_) async => Right([tCategory]));
      when(
        () => mockAddExpenseUseCase(any()),
      ).thenAnswer((_) async => Right(tExpense));

      RecurringRule? capturedRule;
      when(
        () => mockRecurringTransactionRepository.updateRecurringRule(any()),
      ).thenAnswer((invocation) async {
        capturedRule = invocation.positionalArguments.first as RecurringRule;
        return const Right(null);
      });

      await usecase(const NoParams());

      expect(capturedRule, isNotNull);
      // 2025 is NOT a leap year, so Feb 29 becomes Feb 28.
      // Standard DateTime(2025, 2, 29) would normalize to Mar 1.
      expect(capturedRule!.nextOccurrenceDate, equals(DateTime(2025, 2, 28)));
    },
  );
}
