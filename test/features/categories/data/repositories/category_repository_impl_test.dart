import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_local_data_source.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_predefined_data_source.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/categories/data/repositories/category_repository_impl.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryLocalDataSource extends Mock
    implements CategoryLocalDataSource {}

class MockCategoryPredefinedDataSource extends Mock
    implements CategoryPredefinedDataSource {}

void main() {
  late CategoryRepositoryImpl repository;
  late MockCategoryLocalDataSource mockLocalDataSource;
  late MockCategoryPredefinedDataSource mockExpenseDataSource;
  late MockCategoryPredefinedDataSource mockIncomeDataSource;

  setUp(() {
    mockLocalDataSource = MockCategoryLocalDataSource();
    mockExpenseDataSource = MockCategoryPredefinedDataSource();
    mockIncomeDataSource = MockCategoryPredefinedDataSource();
    repository = CategoryRepositoryImpl(
      localDataSource: mockLocalDataSource,
      expensePredefinedDataSource: mockExpenseDataSource,
      incomePredefinedDataSource: mockIncomeDataSource,
    );
    registerFallbackValue(
      CategoryModel(
        id: '1',
        name: 'test',
        iconName: 'icon',
        colorHex: '#000000',
        typeIndex: 0,
        isCustom: true,
      ),
    );
  });

  const tCategory = Category(
    id: '1',
    name: 'Food',
    iconName: 'food',
    colorHex: '#FFFFFF',
    type: CategoryType.expense,
    isCustom: true,
  );

  group('getAllCategories', () {
    test('should aggregate all sources', () async {
      when(
        () => mockExpenseDataSource.getPredefinedCategories(),
      ).thenAnswer((_) async => []);
      when(
        () => mockIncomeDataSource.getPredefinedCategories(),
      ).thenAnswer((_) async => []);
      when(
        () => mockLocalDataSource.getCustomCategories(),
      ).thenAnswer((_) async => [CategoryModel.fromEntity(tCategory)]);

      final result = await repository.getAllCategories();

      expect(result.isRight(), true);
      result.fold((l) => null, (list) {
        expect(list.length, 1);
        expect(list.first.id, '1');
      });
    });

    test('should return cached data on subsequent calls', () async {
      // First call
      when(
        () => mockExpenseDataSource.getPredefinedCategories(),
      ).thenAnswer((_) async => []);
      when(
        () => mockIncomeDataSource.getPredefinedCategories(),
      ).thenAnswer((_) async => []);
      when(
        () => mockLocalDataSource.getCustomCategories(),
      ).thenAnswer((_) async => []);

      await repository.getAllCategories();

      // Second call - should not invoke data sources again
      await repository.getAllCategories();

      verify(() => mockLocalDataSource.getCustomCategories()).called(1);
    });
  });

  group('addCustomCategory', () {
    test('should save custom category', () async {
      when(
        () => mockLocalDataSource.saveCustomCategory(any()),
      ).thenAnswer((_) async => null);

      final result = await repository.addCustomCategory(tCategory);

      expect(result, const Right(null));
      verify(() => mockLocalDataSource.saveCustomCategory(any())).called(1);
    });

    test('should fail if category is not custom', () async {
      final nonCustom = tCategory.copyWith(isCustom: false);
      final result = await repository.addCustomCategory(nonCustom);
      expect(result, isA<Left>());
    });
  });
}
