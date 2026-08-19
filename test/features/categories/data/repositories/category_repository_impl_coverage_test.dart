import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_local_data_source.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_predefined_data_source.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/categories/data/repositories/category_repository_impl.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/either_matchers.dart';

class MockCategoryLocalDataSource extends Mock
    implements CategoryLocalDataSource {}

class MockExpensePredefinedDataSource extends Mock
    implements CategoryPredefinedDataSource {}

class MockIncomePredefinedDataSource extends Mock
    implements CategoryPredefinedDataSource {}

class _FakeCategoryModel extends Fake implements CategoryModel {}

void main() {
  late MockCategoryLocalDataSource localDataSource;
  late MockExpensePredefinedDataSource expensePredefined;
  late MockIncomePredefinedDataSource incomePredefined;
  late CategoryRepositoryImpl repository;

  CategoryModel model({
    required String id,
    required String name,
    CategoryType type = CategoryType.expense,
    bool isCustom = false,
  }) => CategoryModel(
    id: id,
    name: name,
    iconName: 'icon',
    colorHex: '#FF0000',
    typeIndex: type.index,
    isCustom: isCustom,
  );

  Category entity({
    required String id,
    required String name,
    CategoryType type = CategoryType.expense,
    bool isCustom = true,
  }) => Category(
    id: id,
    name: name,
    iconName: 'icon',
    colorHex: '#FF0000',
    type: type,
    isCustom: isCustom,
  );

  void stubSources({
    List<CategoryModel>? expense,
    List<CategoryModel>? income,
    List<CategoryModel>? custom,
  }) {
    when(
      () => expensePredefined.getPredefinedCategories(),
    ).thenAnswer((_) async => expense ?? []);
    when(
      () => incomePredefined.getPredefinedCategories(),
    ).thenAnswer((_) async => income ?? []);
    when(
      () => localDataSource.getCustomCategories(),
    ).thenAnswer((_) async => custom ?? []);
  }

  setUpAll(() {
    registerFallbackValue(_FakeCategoryModel());
  });

  setUp(() {
    localDataSource = MockCategoryLocalDataSource();
    expensePredefined = MockExpensePredefinedDataSource();
    incomePredefined = MockIncomePredefinedDataSource();
    repository = CategoryRepositoryImpl(
      localDataSource: localDataSource,
      expensePredefinedDataSource: expensePredefined,
      incomePredefinedDataSource: incomePredefined,
    );
  });

  group('getAllCategories', () {
    test('merges predefined expense, income and custom categories', () async {
      stubSources(
        expense: [model(id: 'e1', name: 'Food')],
        income: [model(id: 'i1', name: 'Salary', type: CategoryType.income)],
        custom: [model(id: 'c1', name: 'Hobbies', isCustom: true)],
      );

      final categories = rightOf(await repository.getAllCategories());

      expect(categories.map((c) => c.id), containsAll(['e1', 'i1', 'c1']));
      expect(categories, hasLength(3));
    });

    test('sorts by name, case-insensitively', () async {
      stubSources(
        expense: [
          model(id: 'e1', name: 'zebra'),
          model(id: 'e2', name: 'Apples'),
          model(id: 'e3', name: 'mangoes'),
        ],
      );

      final categories = rightOf(await repository.getAllCategories());

      expect(categories.map((c) => c.name), ['Apples', 'mangoes', 'zebra']);
    });

    test(
      'a custom category overrides a predefined one with the same id',
      () async {
        stubSources(
          expense: [model(id: 'shared', name: 'Predefined')],
          custom: [model(id: 'shared', name: 'Customised', isCustom: true)],
        );

        final categories = rightOf(await repository.getAllCategories());

        expect(categories, hasLength(1));
        expect(categories.single.name, 'Customised');
        expect(categories.single.isCustom, isTrue);
      },
    );

    test('the second call is served from cache without re-reading', () async {
      stubSources(
        expense: [model(id: 'e1', name: 'Food')],
      );

      await repository.getAllCategories();
      await repository.getAllCategories();

      verify(() => expensePredefined.getPredefinedCategories()).called(1);
      verify(() => localDataSource.getCustomCategories()).called(1);
    });

    test('invalidateCache forces the next call to re-read', () async {
      stubSources(
        expense: [model(id: 'e1', name: 'Food')],
      );

      await repository.getAllCategories();
      repository.invalidateCache();
      await repository.getAllCategories();

      verify(() => expensePredefined.getPredefinedCategories()).called(2);
    });

    test('maps a source failure to CacheFailure', () async {
      when(
        () => expensePredefined.getPredefinedCategories(),
      ).thenThrow(Exception('assets missing'));
      when(
        () => incomePredefined.getPredefinedCategories(),
      ).thenAnswer((_) async => []);
      when(
        () => localDataSource.getCustomCategories(),
      ).thenAnswer((_) async => []);

      expect(
        leftOf(await repository.getAllCategories()),
        isA<CacheFailure>().having(
          (f) => f.message,
          'message',
          contains('Failed to load all categories'),
        ),
      );
    });

    test('a failure clears the cache so a later call retries', () async {
      when(
        () => expensePredefined.getPredefinedCategories(),
      ).thenThrow(Exception('assets missing'));
      when(
        () => incomePredefined.getPredefinedCategories(),
      ).thenAnswer((_) async => []);
      when(
        () => localDataSource.getCustomCategories(),
      ).thenAnswer((_) async => []);

      await repository.getAllCategories();

      stubSources(
        expense: [model(id: 'e1', name: 'Food')],
      );
      final recovered = rightOf(await repository.getAllCategories());

      expect(recovered, hasLength(1));
    });
  });

  group('getSpecificCategories', () {
    setUp(() {
      stubSources(
        expense: [model(id: 'e1', name: 'Food')],
        income: [model(id: 'i1', name: 'Salary', type: CategoryType.income)],
        custom: [
          model(id: 'c1', name: 'Hobbies', isCustom: true),
          model(
            id: 'c2',
            name: 'Freelance',
            type: CategoryType.income,
            isCustom: true,
          ),
        ],
      );
    });

    test('filters by type', () async {
      final expense = rightOf(
        await repository.getSpecificCategories(type: CategoryType.expense),
      );

      expect(expense.map((c) => c.id), ['e1', 'c1']);
    });

    test('excluding custom leaves only predefined', () async {
      final result = rightOf(
        await repository.getSpecificCategories(
          type: CategoryType.expense,
          includeCustom: false,
        ),
      );

      expect(result.map((c) => c.id), ['e1']);
    });

    test('a null type returns every category', () async {
      final result = rightOf(await repository.getSpecificCategories());

      expect(result, hasLength(4));
    });

    test('propagates a load failure', () async {
      repository.invalidateCache();
      when(
        () => expensePredefined.getPredefinedCategories(),
      ).thenThrow(Exception('io'));

      expect(
        leftOf(await repository.getSpecificCategories()),
        isA<CacheFailure>(),
      );
    });
  });

  group('getCustomCategories', () {
    setUp(() {
      stubSources(
        expense: [model(id: 'e1', name: 'Food')],
        custom: [
          model(id: 'c1', name: 'Hobbies', isCustom: true),
          model(
            id: 'c2',
            name: 'Freelance',
            type: CategoryType.income,
            isCustom: true,
          ),
        ],
      );
    });

    test('returns only custom categories', () async {
      final result = rightOf(await repository.getCustomCategories());

      expect(result.map((c) => c.id), ['c2', 'c1']);
      expect(result.every((c) => c.isCustom), isTrue);
    });

    test('filters custom categories by type', () async {
      final result = rightOf(
        await repository.getCustomCategories(type: CategoryType.income),
      );

      expect(result.map((c) => c.id), ['c2']);
    });
  });

  group('getCategoryById', () {
    test('finds a category across every source', () async {
      stubSources(
        expense: [model(id: 'e1', name: 'Food')],
        custom: [model(id: 'c1', name: 'Hobbies', isCustom: true)],
      );

      expect(rightOf(await repository.getCategoryById('c1'))?.name, 'Hobbies');
    });

    test('an unknown id is a null success, not a failure', () async {
      stubSources(
        expense: [model(id: 'e1', name: 'Food')],
      );

      final result = await repository.getCategoryById('ghost');

      expect(result.isRight(), isTrue);
      expect(rightOf(result), isNull);
    });

    test('propagates a load failure', () async {
      when(
        () => expensePredefined.getPredefinedCategories(),
      ).thenThrow(Exception('io'));
      when(
        () => incomePredefined.getPredefinedCategories(),
      ).thenAnswer((_) async => []);
      when(
        () => localDataSource.getCustomCategories(),
      ).thenAnswer((_) async => []);

      expect(
        leftOf(await repository.getCategoryById('e1')),
        isA<CacheFailure>(),
      );
    });
  });

  group('addCustomCategory', () {
    test('refuses to add a predefined category', () async {
      final result = await repository.addCustomCategory(
        entity(id: 'p1', name: 'Predefined', isCustom: false),
      );

      expect(
        leftOf(result),
        isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          'Only custom categories can be added.',
        ),
      );
      verifyNever(() => localDataSource.saveCustomCategory(any()));
    });

    test('saves a custom category and invalidates the cache', () async {
      stubSources(
        expense: [model(id: 'e1', name: 'Food')],
      );
      when(
        () => localDataSource.saveCustomCategory(any()),
      ).thenAnswer((_) async {});

      await repository.getAllCategories();
      final result = await repository.addCustomCategory(
        entity(id: 'c1', name: 'Hobbies'),
      );
      await repository.getAllCategories();

      expect(result.isRight(), isTrue);
      // The cache must not survive a write, or the new category stays hidden.
      verify(() => expensePredefined.getPredefinedCategories()).called(2);
    });

    test('maps a write error to CacheFailure', () async {
      when(
        () => localDataSource.saveCustomCategory(any()),
      ).thenThrow(Exception('disk'));

      expect(
        leftOf(
          await repository.addCustomCategory(entity(id: 'c1', name: 'X')),
        ).message,
        contains('Failed to add category'),
      );
    });
  });

  group('updateCategory', () {
    test('refuses to update a predefined category', () async {
      final result = await repository.updateCategory(
        entity(id: 'p1', name: 'Predefined', isCustom: false),
      );

      expect(
        leftOf(result),
        isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          'Only custom categories can be updated.',
        ),
      );
      verifyNever(() => localDataSource.updateCustomCategory(any()));
    });

    test('updates a custom category and invalidates the cache', () async {
      stubSources(
        expense: [model(id: 'e1', name: 'Food')],
      );
      when(
        () => localDataSource.updateCustomCategory(any()),
      ).thenAnswer((_) async {});

      await repository.getAllCategories();
      final result = await repository.updateCategory(
        entity(id: 'c1', name: 'Renamed'),
      );
      await repository.getAllCategories();

      expect(result.isRight(), isTrue);
      verify(() => expensePredefined.getPredefinedCategories()).called(2);
    });

    test('maps a write error to CacheFailure', () async {
      when(
        () => localDataSource.updateCustomCategory(any()),
      ).thenThrow(Exception('locked'));

      expect(
        leftOf(
          await repository.updateCategory(entity(id: 'c1', name: 'X')),
        ).message,
        contains('Failed to update category'),
      );
    });
  });

  group('deleteCustomCategory', () {
    test('deletes and invalidates the cache', () async {
      stubSources(
        expense: [model(id: 'e1', name: 'Food')],
      );
      when(
        () => localDataSource.deleteCustomCategory('c1'),
      ).thenAnswer((_) async {});

      await repository.getAllCategories();
      final result = await repository.deleteCustomCategory('c1', 'fallback');
      await repository.getAllCategories();

      expect(result.isRight(), isTrue);
      verify(() => localDataSource.deleteCustomCategory('c1')).called(1);
      verify(() => expensePredefined.getPredefinedCategories()).called(2);
    });

    test('maps a delete error to CacheFailure', () async {
      when(
        () => localDataSource.deleteCustomCategory('c1'),
      ).thenThrow(Exception('locked'));

      expect(
        leftOf(await repository.deleteCustomCategory('c1', 'fallback')).message,
        contains('Failed to delete category'),
      );
    });
  });
}
