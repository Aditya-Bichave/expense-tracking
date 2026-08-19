import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/either_matchers.dart';

class MockBudgetLocalDataSource extends Mock implements BudgetLocalDataSource {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class _FakeBudgetModel extends Fake implements BudgetModel {}

void main() {
  late MockBudgetLocalDataSource dataSource;
  late MockExpenseRepository expenseRepository;
  late BudgetRepositoryImpl repository;

  final createdAt = DateTime(2024, 1, 1);
  final periodStart = DateTime(2024, 3, 1);
  final periodEnd = DateTime(2024, 3, 31);

  Budget budget({
    String id = 'b1',
    String name = 'Groceries',
    BudgetType type = BudgetType.overall,
    List<String>? categoryIds,
    BudgetPeriodType period = BudgetPeriodType.recurringMonthly,
    double target = 500,
  }) => Budget(
    id: id,
    name: name,
    type: type,
    targetAmount: target,
    period: period,
    categoryIds: categoryIds,
    createdAt: createdAt,
  );

  BudgetModel modelOf(Budget b) => BudgetModel.fromEntity(b);

  ExpenseModel expense(double amount, {String? categoryId}) => ExpenseModel(
    id: 'e-$amount-$categoryId',
    title: 'Item',
    amount: amount,
    date: periodStart,
    categoryId: categoryId,
    accountId: 'a1',
  );

  void stubExistingBudgets(List<Budget> budgets) {
    when(
      () => dataSource.getBudgets(),
    ).thenAnswer((_) async => budgets.map(modelOf).toList());
  }

  void stubExpenses(List<ExpenseModel> expenses) {
    when(
      () => expenseRepository.getExpenses(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
      ),
    ).thenAnswer((_) async => Right(expenses));
  }

  setUpAll(() {
    registerFallbackValue(_FakeBudgetModel());
  });

  setUp(() {
    dataSource = MockBudgetLocalDataSource();
    expenseRepository = MockExpenseRepository();
    repository = BudgetRepositoryImpl(
      localDataSource: dataSource,
      expenseRepository: expenseRepository,
    );
    when(() => dataSource.saveBudget(any())).thenAnswer((_) async {});
  });

  group('addBudget', () {
    test('an overall budget skips the overlap check entirely', () async {
      final result = await repository.addBudget(budget());

      expect(rightOf(result).id, 'b1');
      verify(() => dataSource.saveBudget(any())).called(1);
      verifyNever(() => dataSource.getBudgets());
    });

    test('a category budget with no conflicting peer is saved', () async {
      stubExistingBudgets([
        budget(
          id: 'b0',
          name: 'Travel',
          type: BudgetType.categorySpecific,
          categoryIds: ['c-travel'],
        ),
      ]);

      final result = await repository.addBudget(
        budget(type: BudgetType.categorySpecific, categoryIds: ['c-food']),
      );

      expect(result.isRight(), isTrue);
      verify(() => dataSource.saveBudget(any())).called(1);
    });

    test('two recurring budgets sharing a category are rejected', () async {
      stubExistingBudgets([
        budget(
          id: 'b0',
          name: 'Existing Food',
          type: BudgetType.categorySpecific,
          categoryIds: ['c-food', 'c-drink'],
        ),
      ]);

      final result = await repository.addBudget(
        budget(type: BudgetType.categorySpecific, categoryIds: ['c-food']),
      );

      expect(
        leftOf(result),
        isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          contains("Existing Food"),
        ),
      );
      verifyNever(() => dataSource.saveBudget(any()));
    });

    test('an overall peer never counts as an overlap', () async {
      stubExistingBudgets([budget(id: 'b0', name: 'Everything')]);

      final result = await repository.addBudget(
        budget(type: BudgetType.categorySpecific, categoryIds: ['c-food']),
      );

      expect(result.isRight(), isTrue);
    });

    test('a failure fetching peers aborts the add', () async {
      when(() => dataSource.getBudgets()).thenThrow(const CacheFailure('io'));

      final result = await repository.addBudget(
        budget(type: BudgetType.categorySpecific, categoryIds: ['c-food']),
      );

      expect(result.isLeft(), isTrue);
      verifyNever(() => dataSource.saveBudget(any()));
    });

    test('maps a write error to CacheFailure', () async {
      when(() => dataSource.saveBudget(any())).thenThrow(Exception('disk'));

      expect(
        leftOf(await repository.addBudget(budget())).message,
        contains('Failed to add budget'),
      );
    });
  });

  group('updateBudget', () {
    test('a budget does not overlap with itself', () async {
      final existing = budget(
        type: BudgetType.categorySpecific,
        categoryIds: ['c-food'],
      );
      stubExistingBudgets([existing]);

      final result = await repository.updateBudget(
        budget(
          name: 'Renamed',
          type: BudgetType.categorySpecific,
          categoryIds: ['c-food'],
        ),
      );

      expect(result.isRight(), isTrue);
      verify(() => dataSource.saveBudget(any())).called(1);
    });

    test('overlapping a different budget is rejected', () async {
      stubExistingBudgets([
        budget(
          id: 'b2',
          name: 'Other Food',
          type: BudgetType.categorySpecific,
          categoryIds: ['c-food'],
        ),
      ]);

      final result = await repository.updateBudget(
        budget(type: BudgetType.categorySpecific, categoryIds: ['c-food']),
      );

      expect(leftOf(result), isA<ValidationFailure>());
      verifyNever(() => dataSource.saveBudget(any()));
    });

    test('an overall budget skips the overlap check', () async {
      final result = await repository.updateBudget(budget());

      expect(result.isRight(), isTrue);
      verifyNever(() => dataSource.getBudgets());
    });

    test('maps a write error to CacheFailure', () async {
      when(() => dataSource.saveBudget(any())).thenThrow(Exception('disk'));

      expect(
        leftOf(await repository.updateBudget(budget())).message,
        contains('Failed to update budget'),
      );
    });
  });

  group('calculateAmountSpent', () {
    test('an overall budget counts every expense in the period', () async {
      stubExpenses([
        expense(10, categoryId: 'c-food'),
        expense(15, categoryId: 'c-travel'),
        expense(5),
      ]);

      final total = rightOf(
        await repository.calculateAmountSpent(
          budget: budget(),
          periodStart: periodStart,
          periodEnd: periodEnd,
        ),
      );

      expect(total, 30);
    });

    test('a category budget counts only its own categories', () async {
      stubExpenses([
        expense(10, categoryId: 'c-food'),
        expense(15, categoryId: 'c-travel'),
        expense(7, categoryId: 'c-drink'),
      ]);

      final total = rightOf(
        await repository.calculateAmountSpent(
          budget: budget(
            type: BudgetType.categorySpecific,
            categoryIds: ['c-food', 'c-drink'],
          ),
          periodStart: periodStart,
          periodEnd: periodEnd,
        ),
      );

      expect(total, 17);
    });

    test(
      'an uncategorized expense is excluded from a category budget',
      () async {
        stubExpenses([expense(10), expense(20, categoryId: 'c-food')]);

        final total = rightOf(
          await repository.calculateAmountSpent(
            budget: budget(
              type: BudgetType.categorySpecific,
              categoryIds: ['c-food'],
            ),
            periodStart: periodStart,
            periodEnd: periodEnd,
          ),
        );

        expect(total, 20);
      },
    );

    test(
      'a category budget with an empty category list spends nothing',
      () async {
        stubExpenses([expense(10, categoryId: 'c-food')]);

        final total = rightOf(
          await repository.calculateAmountSpent(
            budget: budget(
              type: BudgetType.categorySpecific,
              categoryIds: const [],
            ),
            periodStart: periodStart,
            periodEnd: periodEnd,
          ),
        );

        expect(total, 0);
      },
    );

    test('no expenses in the period totals zero', () async {
      stubExpenses([]);

      expect(
        rightOf(
          await repository.calculateAmountSpent(
            budget: budget(),
            periodStart: periodStart,
            periodEnd: periodEnd,
          ),
        ),
        0,
      );
    });

    test('forwards the period bounds to the expense repository', () async {
      stubExpenses([]);

      await repository.calculateAmountSpent(
        budget: budget(),
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      verify(
        () => expenseRepository.getExpenses(
          startDate: periodStart,
          endDate: periodEnd,
        ),
      ).called(1);
    });

    test('propagates a failure from the expense repository', () async {
      when(
        () => expenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => const Left(CacheFailure('expenses gone')));

      expect(
        leftOf(
          await repository.calculateAmountSpent(
            budget: budget(),
            periodStart: periodStart,
            periodEnd: periodEnd,
          ),
        ),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          'expenses gone',
        ),
      );
    });
  });

  group('getBudgets', () {
    test(
      'sorts overall budgets first, then by name case-insensitively',
      () async {
        stubExistingBudgets([
          budget(
            id: 'b1',
            name: 'zebra',
            type: BudgetType.categorySpecific,
            categoryIds: ['c1'],
          ),
          budget(id: 'b2', name: 'Everything'),
          budget(
            id: 'b3',
            name: 'Apples',
            type: BudgetType.categorySpecific,
            categoryIds: ['c2'],
          ),
        ]);

        final budgets = rightOf(await repository.getBudgets());

        expect(budgets.map((b) => b.name), ['Everything', 'Apples', 'zebra']);
      },
    );

    test('returns an empty list when there are none', () async {
      stubExistingBudgets([]);

      expect(rightOf(await repository.getBudgets()), isEmpty);
    });

    test('maps a read error to CacheFailure', () async {
      when(() => dataSource.getBudgets()).thenThrow(Exception('io'));

      expect(
        leftOf(await repository.getBudgets()).message,
        contains('Failed to load budgets'),
      );
    });
  });

  group('getBudgetById', () {
    test('returns the mapped entity when present', () async {
      when(
        () => dataSource.getBudgetById('b1'),
      ).thenAnswer((_) async => modelOf(budget(name: 'Rent')));

      expect(rightOf(await repository.getBudgetById('b1'))?.name, 'Rent');
    });

    test('a missing budget is a null success, not a failure', () async {
      when(
        () => dataSource.getBudgetById('ghost'),
      ).thenAnswer((_) async => null);

      final result = await repository.getBudgetById('ghost');

      expect(result.isRight(), isTrue);
      expect(rightOf(result), isNull);
    });

    test('maps a read error to CacheFailure', () async {
      when(() => dataSource.getBudgetById('b1')).thenThrow(Exception('io'));

      expect(
        leftOf(await repository.getBudgetById('b1')).message,
        contains('Failed to get budget details'),
      );
    });
  });

  group('deleteBudget', () {
    test('delegates to the data source', () async {
      when(() => dataSource.deleteBudget('b1')).thenAnswer((_) async {});

      expect((await repository.deleteBudget('b1')).isRight(), isTrue);
      verify(() => dataSource.deleteBudget('b1')).called(1);
    });

    test('maps a delete error to CacheFailure', () async {
      when(() => dataSource.deleteBudget('b1')).thenThrow(Exception('locked'));

      expect(
        leftOf(await repository.deleteBudget('b1')).message,
        contains('Failed to delete budget'),
      );
    });
  });
}
