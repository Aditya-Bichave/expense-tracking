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

class FakeCategoryModel extends Fake implements CategoryModel {}

void main() {
  late CategoryRepositoryImpl repository;
  late MockCategoryLocalDataSource mockLocalDataSource;
  late MockCategoryPredefinedDataSource mockExpensePredefinedDataSource;
  late MockCategoryPredefinedDataSource mockIncomePredefinedDataSource;

  setUpAll(() {
    registerFallbackValue(FakeCategoryModel());
  });

  setUp(() {
    mockLocalDataSource = MockCategoryLocalDataSource();
    mockExpensePredefinedDataSource = MockCategoryPredefinedDataSource();
    mockIncomePredefinedDataSource = MockCategoryPredefinedDataSource();
    repository = CategoryRepositoryImpl(
      localDataSource: mockLocalDataSource,
      expensePredefinedDataSource: mockExpensePredefinedDataSource,
      incomePredefinedDataSource: mockIncomePredefinedDataSource,
    );
  });

  const tCategory = Category(
    id: '1',
    name: 'Custom',
    iconName: 'icon',
    colorHex: '#000000',
    type: CategoryType.expense,
    isCustom: true,
  );

  final tCategoryModel = CategoryModel(
    id: '1',
    name: 'Custom',
    iconName: 'icon',
    colorHex: '#000000',
    typeIndex: 0,
    isCustom: true,
  );

  group('getAllCategories', () {
    test('should return combined list of categories', () async {
      // Arrange
      when(
        () => mockExpensePredefinedDataSource.getPredefinedCategories(),
      ).thenAnswer((_) async => []);
      when(
        () => mockIncomePredefinedDataSource.getPredefinedCategories(),
      ).thenAnswer((_) async => []);
      when(
        () => mockLocalDataSource.getCustomCategories(),
      ).thenAnswer((_) async => [tCategoryModel]);

      // Act
      final result = await repository.getAllCategories();

      // Assert
      expect(result.isRight(), isTrue);
      final categories = result.getOrElse(() => []);
      expect(categories.length, 1);
      expect(categories.first.id, tCategory.id);
    });

    test('should return CacheFailure when any source fails', () async {
      // Arrange
      when(
        () => mockExpensePredefinedDataSource.getPredefinedCategories(),
      ).thenThrow(Exception());
      when(
        () => mockIncomePredefinedDataSource.getPredefinedCategories(),
      ).thenAnswer((_) async => []);
      when(
        () => mockLocalDataSource.getCustomCategories(),
      ).thenAnswer((_) async => []);

      // Act
      final result = await repository.getAllCategories();

      // Assert
      expect(result.isLeft(), isTrue);
      expect(result.fold((l) => l, (r) => null), isA<CacheFailure>());
    });
  });

  group('addCustomCategory', () {
    test('should call saveCustomCategory on local data source', () async {
      // Arrange
      when(
        () => mockLocalDataSource.saveCustomCategory(any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.addCustomCategory(tCategory);

      // Assert
      verify(
        () => mockLocalDataSource.saveCustomCategory(any<CategoryModel>()),
      ).called(1);
      expect(result, const Right(null));
    });

    test('should return ValidationFailure if category is not custom', () async {
      // Arrange
      final nonCustom = tCategory.copyWith(isCustom: false);

      // Act
      final result = await repository.addCustomCategory(nonCustom);

      // Assert
      expect(result.isLeft(), isTrue);
      expect(result.fold((l) => l, (r) => null), isA<ValidationFailure>());
      verifyNever(() => mockLocalDataSource.saveCustomCategory(any()));
    });
  });

  group('deleteCustomCategory', () {
    test('should call deleteCustomCategory on local data source', () async {
      // Arrange
      when(
        () => mockLocalDataSource.deleteCustomCategory(any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.deleteCustomCategory('1', 'fallback');

      // Assert
      verify(() => mockLocalDataSource.deleteCustomCategory('1')).called(1);
      expect(result, const Right(null));
    });
  });
}
