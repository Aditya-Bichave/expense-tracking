import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_local_data_source.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox extends Mock implements Box<CategoryModel> {}

void main() {
  late HiveCategoryLocalDataSource dataSource;
  late MockBox mockBox;

  setUp(() {
    mockBox = MockBox();
    dataSource = HiveCategoryLocalDataSource(mockBox);
  });

  final tCategoryModel = CategoryModel(
    id: '1',
    name: 'Custom Cat',
    iconName: 'icon',
    colorHex: '#000000',
    typeIndex: 0,
    isCustom: true,
  );

  group('getCustomCategories', () {
    test('should return list of CategoryModel from Hive', () async {
      // Arrange
      when(() => mockBox.values).thenReturn([tCategoryModel]);

      // Act
      final result = await dataSource.getCustomCategories();

      // Assert
      expect(result, [tCategoryModel]);
    });

    test('should throw CacheFailure when Hive access fails', () async {
      // Arrange
      when(() => mockBox.values).thenThrow(Exception());

      // Act & Assert
      expect(
        () => dataSource.getCustomCategories(),
        throwsA(isA<CacheFailure>()),
      );
    });
  });

  group('saveCustomCategory', () {
    test('should save custom category to Hive', () async {
      // Arrange
      when(
        () => mockBox.put(any(), any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      await dataSource.saveCustomCategory(tCategoryModel);

      // Assert
      verify(() => mockBox.put(tCategoryModel.id, tCategoryModel)).called(1);
    });

    test('should NOT save non-custom category', () async {
      // Arrange
      final nonCustomModel = CategoryModel(
        id: '2',
        name: 'Predefined',
        iconName: 'icon',
        colorHex: '#000000',
        typeIndex: 0,
        isCustom: false,
      );

      // Act
      await dataSource.saveCustomCategory(nonCustomModel);

      // Assert
      verifyNever(() => mockBox.put(any(), any()));
    });

    test('should throw CacheFailure when saving fails', () async {
      // Arrange
      when(() => mockBox.put(any(), any())).thenThrow(Exception());

      // Act & Assert
      expect(
        () => dataSource.saveCustomCategory(tCategoryModel),
        throwsA(isA<CacheFailure>()),
      );
    });
  });

  group('updateCustomCategory', () {
    test('should update existing custom category', () async {
      // Arrange
      when(() => mockBox.containsKey(any())).thenReturn(true);
      when(
        () => mockBox.put(any(), any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      await dataSource.updateCustomCategory(tCategoryModel);

      // Assert
      verify(() => mockBox.put(tCategoryModel.id, tCategoryModel)).called(1);
    });

    test('should throw CacheFailure if category does not exist', () async {
      // Arrange
      when(() => mockBox.containsKey(any())).thenReturn(false);

      // Act & Assert
      expect(
        () => dataSource.updateCustomCategory(tCategoryModel),
        throwsA(isA<CacheFailure>()),
      );
      verifyNever(() => mockBox.put(any(), any()));
    });
  });

  group('deleteCustomCategory', () {
    test('should delete category from Hive', () async {
      // Arrange
      when(() => mockBox.delete(any())).thenAnswer((_) async => Future.value());

      // Act
      await dataSource.deleteCustomCategory('1');

      // Assert
      verify(() => mockBox.delete('1')).called(1);
    });

    test('should throw CacheFailure when deletion fails', () async {
      // Arrange
      when(() => mockBox.delete(any())).thenThrow(Exception());

      // Act & Assert
      expect(
        () => dataSource.deleteCustomCategory('1'),
        throwsA(isA<CacheFailure>()),
      );
    });
  });
}
