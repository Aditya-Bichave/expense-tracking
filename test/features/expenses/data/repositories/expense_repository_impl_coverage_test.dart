import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/either_matchers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockExpenseLocalDataSource extends Mock
    implements ExpenseLocalDataSource {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class _FakeExpenseModel extends Fake implements ExpenseModel {}

void main() {
  late MockExpenseLocalDataSource dataSource;
  late MockCategoryRepository categoryRepository;
  late MockSupabaseClient supabase;
  late ExpenseRepositoryImpl repository;

  const foodCategory = Category(
    id: 'c-food',
    name: 'Food',
    iconName: 'restaurant',
    colorHex: '#FF0000',
    type: CategoryType.expense,
    isCustom: false,
  );

  ExpenseModel model({
    String id = '1',
    String title = 'Coffee',
    double amount = 3,
    DateTime? date,
    String? categoryId,
    String accountId = 'a1',
    String status = 'uncategorized',
  }) => ExpenseModel(
    id: id,
    title: title,
    amount: amount,
    date: date ?? DateTime(2024, 1, 1),
    categoryId: categoryId,
    accountId: accountId,
    categorizationStatusValue: status,
  );

  Expense entity({
    String id = '1',
    String title = 'Coffee',
    double amount = 3,
    String accountId = 'a1',
  }) => Expense(
    id: id,
    title: title,
    amount: amount,
    date: DateTime(2024, 1, 1),
    accountId: accountId,
  );

  setUpAll(() {
    registerFallbackValue(_FakeExpenseModel());
  });

  setUp(() {
    dataSource = MockExpenseLocalDataSource();
    categoryRepository = MockCategoryRepository();
    supabase = MockSupabaseClient();
    repository = ExpenseRepositoryImpl(
      localDataSource: dataSource,
      categoryRepository: categoryRepository,
      supabaseClient: supabase,
    );
  });

  group('addExpense', () {
    test('persists the model and returns the hydrated entity', () async {
      when(
        () => dataSource.addExpense(any()),
      ).thenAnswer((i) async => i.positionalArguments.first as ExpenseModel);

      final result = await repository.addExpense(entity(title: 'Lunch'));

      expect(result.isRight(), isTrue);
      expect(rightOf(result).title, 'Lunch');
      verify(() => dataSource.addExpense(any())).called(1);
    });

    test('hydrates the category when the expense has one', () async {
      when(
        () => dataSource.addExpense(any()),
      ).thenAnswer((i) async => i.positionalArguments.first as ExpenseModel);
      when(
        () => categoryRepository.getCategoryById('c-food'),
      ).thenAnswer((_) async => const Right(foodCategory));

      final result = await repository.addExpense(
        Expense(
          id: '1',
          title: 'Lunch',
          amount: 12,
          date: DateTime(2024, 1, 1),
          accountId: 'a1',
          category: foodCategory,
        ),
      );

      expect(rightOf(result).category?.name, 'Food');
    });

    test('leaves the category null when lookup fails', () async {
      when(
        () => dataSource.addExpense(any()),
      ).thenAnswer((i) async => i.positionalArguments.first as ExpenseModel);
      when(
        () => categoryRepository.getCategoryById('c-food'),
      ).thenAnswer((_) async => const Left(CacheFailure('no such category')));

      final result = await repository.addExpense(
        Expense(
          id: '1',
          title: 'Lunch',
          amount: 12,
          date: DateTime(2024, 1, 1),
          accountId: 'a1',
          category: foodCategory,
        ),
      );

      expect(rightOf(result).category, isNull);
    });

    test('propagates a CacheFailure from the data source', () async {
      when(
        () => dataSource.addExpense(any()),
      ).thenThrow(const CacheFailure('disk full'));

      final result = await repository.addExpense(entity());

      expect(
        leftOf(result),
        isA<CacheFailure>().having((f) => f.message, 'message', 'disk full'),
      );
    });

    test('wraps an unexpected error as UnexpectedFailure', () async {
      when(() => dataSource.addExpense(any())).thenThrow(StateError('boom'));

      final result = await repository.addExpense(entity());

      expect(
        leftOf(result),
        isA<UnexpectedFailure>().having(
          (f) => f.message,
          'message',
          contains('boom'),
        ),
      );
    });
  });

  group('updateExpense', () {
    test('persists the update and returns the hydrated entity', () async {
      when(
        () => dataSource.updateExpense(any()),
      ).thenAnswer((i) async => i.positionalArguments.first as ExpenseModel);

      final result = await repository.updateExpense(entity(title: 'Brunch'));

      expect(rightOf(result).title, 'Brunch');
      verify(() => dataSource.updateExpense(any())).called(1);
    });

    test('propagates a CacheFailure from the data source', () async {
      when(
        () => dataSource.updateExpense(any()),
      ).thenThrow(const CacheFailure('locked'));

      final result = await repository.updateExpense(entity());

      expect(leftOf(result), isA<CacheFailure>());
    });

    test('wraps an unexpected error as UnexpectedFailure', () async {
      when(() => dataSource.updateExpense(any())).thenThrow(Exception('nope'));

      final result = await repository.updateExpense(entity());

      expect(leftOf(result), isA<UnexpectedFailure>());
    });
  });

  group('getExpenseById', () {
    test('returns null when nothing is stored under that id', () async {
      when(
        () => dataSource.getExpenseById('missing'),
      ).thenAnswer((_) async => null);

      final result = await repository.getExpenseById('missing');

      expect(rightOf(result), isNull);
    });

    test('returns the hydrated expense when present', () async {
      when(
        () => dataSource.getExpenseById('1'),
      ).thenAnswer((_) async => model(title: 'Tea'));

      final result = await repository.getExpenseById('1');

      expect(rightOf(result)?.title, 'Tea');
    });

    test('maps a thrown error to CacheFailure', () async {
      when(() => dataSource.getExpenseById('1')).thenThrow(Exception('io'));

      final result = await repository.getExpenseById('1');

      expect(
        leftOf(result),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          contains('Error getting expense'),
        ),
      );
    });
  });

  group('deleteExpense', () {
    test('returns success when the data source deletes', () async {
      when(() => dataSource.deleteExpense('1')).thenAnswer((_) async {});

      final result = await repository.deleteExpense('1');

      expect(result.isRight(), isTrue);
      verify(() => dataSource.deleteExpense('1')).called(1);
    });

    test('propagates a CacheFailure', () async {
      when(
        () => dataSource.deleteExpense('1'),
      ).thenThrow(const CacheFailure('busy'));

      final result = await repository.deleteExpense('1');

      expect(
        leftOf(result),
        isA<CacheFailure>().having((f) => f.message, 'message', 'busy'),
      );
    });

    test('wraps other errors as UnexpectedFailure', () async {
      when(() => dataSource.deleteExpense('1')).thenThrow(StateError('x'));

      final result = await repository.deleteExpense('1');

      expect(leftOf(result), isA<UnexpectedFailure>());
    });
  });

  group('getTotalExpensesForAccount', () {
    test('sums the amounts of the matching expenses', () async {
      when(
        () => dataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer(
        (_) async => [model(id: '1', amount: 10), model(id: '2', amount: 15.5)],
      );

      final result = await repository.getTotalExpensesForAccount('a1');

      expect(result.getOrElse(() => -1), 25.5);
    });

    test('treats an empty account id as "no account filter"', () async {
      when(
        () => dataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => []);

      expect(rightOf(await repository.getTotalExpensesForAccount('')), 0.0);

      verify(
        () => dataSource.getExpenses(
          startDate: null,
          endDate: null,
          categoryId: null,
          accountId: null,
        ),
      ).called(1);
    });

    test('returns zero when there are no expenses', () async {
      when(
        () => dataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => []);

      expect(
        (await repository.getTotalExpensesForAccount('a1')).getOrElse(() => -1),
        0.0,
      );
    });

    test('propagates a data source failure', () async {
      when(
        () => dataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenThrow(const CacheFailure('unreadable'));

      final result = await repository.getTotalExpensesForAccount('a1');

      expect(result.isLeft(), isTrue);
    });
  });

  group('getExpenseSummary', () {
    void stubExpenses(List<ExpenseModel> models) {
      when(
        () => dataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => models);
    }

    test('breaks the total down by category name, highest first', () async {
      stubExpenses([
        model(id: '1', amount: 10, categoryId: 'c-food'),
        model(id: '2', amount: 30, categoryId: 'c-travel'),
        model(id: '3', amount: 5, categoryId: 'c-food'),
      ]);
      when(() => categoryRepository.getAllCategories()).thenAnswer(
        (_) async => const Right([
          foodCategory,
          Category(
            id: 'c-travel',
            name: 'Travel',
            iconName: 'flight',
            colorHex: '#00FF00',
            type: CategoryType.expense,
            isCustom: false,
          ),
        ]),
      );

      final summary = rightOf(await repository.getExpenseSummary());

      expect(summary.totalExpenses, 45);
      expect(summary.categoryBreakdown.keys.toList(), ['Travel', 'Food']);
      expect(summary.categoryBreakdown['Food'], 15);
      expect(summary.categoryBreakdown['Travel'], 30);
    });

    test('falls back to the uncategorized bucket for unknown ids', () async {
      stubExpenses([model(id: '1', amount: 7, categoryId: 'ghost')]);
      when(
        () => categoryRepository.getAllCategories(),
      ).thenAnswer((_) async => const Right([]));

      final summary = rightOf(await repository.getExpenseSummary());

      expect(summary.categoryBreakdown[Category.uncategorized.name], 7);
    });

    test('still summarises when the category lookup fails', () async {
      stubExpenses([model(id: '1', amount: 7, categoryId: 'c-food')]);
      when(() => categoryRepository.getAllCategories()).thenAnswer(
        (_) async => const Left(CacheFailure('categories unavailable')),
      );

      final summary = rightOf(await repository.getExpenseSummary());

      expect(summary.totalExpenses, 7);
      expect(summary.categoryBreakdown[Category.uncategorized.name], 7);
    });

    test('propagates a failure from the expense fetch', () async {
      when(
        () => dataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenThrow(const CacheFailure('gone'));

      final result = await repository.getExpenseSummary();

      expect(result.isLeft(), isTrue);
    });
  });

  group('updateExpenseCategorization', () {
    test('returns CacheFailure when the expense does not exist', () async {
      when(
        () => dataSource.getExpenseById('nope'),
      ).thenAnswer((_) async => null);

      final result = await repository.updateExpenseCategorization(
        'nope',
        'c-food',
        CategorizationStatus.categorized,
        0.9,
      );

      expect(
        leftOf(result),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          'Expense not found',
        ),
      );
    });

    test('writes back the new category, status and confidence', () async {
      when(
        () => dataSource.getExpenseById('1'),
      ).thenAnswer((_) async => model(id: '1', title: 'Coffee'));
      when(
        () => dataSource.updateExpense(any()),
      ).thenAnswer((i) async => i.positionalArguments.first as ExpenseModel);

      final result = await repository.updateExpenseCategorization(
        '1',
        'c-food',
        CategorizationStatus.categorized,
        0.87,
      );

      expect(result.isRight(), isTrue);
      final written =
          verify(() => dataSource.updateExpense(captureAny())).captured.single
              as ExpenseModel;
      expect(written.id, '1');
      expect(written.title, 'Coffee');
      expect(written.categoryId, 'c-food');
      expect(
        written.categorizationStatusValue,
        CategorizationStatus.categorized.value,
      );
      expect(written.confidenceScoreValue, 0.87);
    });

    test('clearing a category writes a null category id', () async {
      when(
        () => dataSource.getExpenseById('1'),
      ).thenAnswer((_) async => model(id: '1', categoryId: 'c-food'));
      when(
        () => dataSource.updateExpense(any()),
      ).thenAnswer((i) async => i.positionalArguments.first as ExpenseModel);

      await repository.updateExpenseCategorization(
        '1',
        null,
        CategorizationStatus.uncategorized,
        null,
      );

      final written =
          verify(() => dataSource.updateExpense(captureAny())).captured.single
              as ExpenseModel;
      expect(written.categoryId, isNull);
      expect(written.confidenceScoreValue, isNull);
    });

    test('wraps a write error as UnexpectedFailure', () async {
      when(
        () => dataSource.getExpenseById('1'),
      ).thenAnswer((_) async => model(id: '1'));
      when(() => dataSource.updateExpense(any())).thenThrow(Exception('io'));

      final result = await repository.updateExpenseCategorization(
        '1',
        'c-food',
        CategorizationStatus.categorized,
        1,
      );

      expect(leftOf(result), isA<UnexpectedFailure>());
    });
  });

  group('reassignExpensesCategory', () {
    test('returns zero and writes nothing when nothing matches', () async {
      when(
        () => dataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => [model(id: '1', categoryId: 'other')]);

      final result = await repository.reassignExpensesCategory('old', 'new');

      expect(result.getOrElse(() => -1), 0);
      verifyNever(() => dataSource.updateExpense(any()));
    });

    test('rewrites every matching expense and reports the count', () async {
      when(
        () => dataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer(
        (_) async => [
          model(id: '1', categoryId: 'old'),
          model(id: '2', categoryId: 'other'),
          model(id: '3', categoryId: 'old'),
        ],
      );
      when(
        () => dataSource.updateExpense(any()),
      ).thenAnswer((i) async => i.positionalArguments.first as ExpenseModel);

      final result = await repository.reassignExpensesCategory('old', 'new');

      expect(result.getOrElse(() => -1), 2);
      final written = verify(
        () => dataSource.updateExpense(captureAny()),
      ).captured.cast<ExpenseModel>();
      expect(written.map((m) => m.id), ['1', '3']);
      expect(written.every((m) => m.categoryId == 'new'), isTrue);
      // Reassignment implies an explicit, confident categorization.
      expect(
        written.every(
          (m) =>
              m.categorizationStatusValue ==
              CategorizationStatus.categorized.value,
        ),
        isTrue,
      );
      expect(written.every((m) => m.confidenceScoreValue == null), isTrue);
    });

    test('wraps a read error as UnexpectedFailure', () async {
      when(
        () => dataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenThrow(Exception('io'));

      final result = await repository.reassignExpensesCategory('old', 'new');

      expect(leftOf(result), isA<UnexpectedFailure>());
    });
  });
}
