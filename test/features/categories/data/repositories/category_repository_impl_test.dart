import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_local_data_source.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_predefined_data_source.dart';
import 'package:expense_tracker/features/categories/data/repositories/category_repository_impl.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryLocalDataSource extends Mock implements CategoryLocalDataSource {}

class MockCategoryPredefinedDataSource extends Mock
    implements CategoryPredefinedDataSource {}

void main() {
  late CategoryRepositoryImpl repository;
  late MockCategoryLocalDataSource mockLocalDataSource;
  late MockCategoryPredefinedDataSource mockExpensePredefinedDataSource;
  late MockCategoryPredefinedDataSource mockIncomePredefinedDataSource;

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

  test('should return ValidationFailure when updating non-custom category',
      () async {
    const nonCustomCategory = Category(
      id: '1',
      name: 'Food',
      iconName: 'food',
      colorHex: '#FFFFFF',
      type: CategoryType.expense,
      isCustom: false,
    );

    final result = await repository.updateCategory(nonCustomCategory);

    expect(
      result,
      equals(const Left(
          ValidationFailure('Only custom categories can be updated.'))),
    );
    verifyZeroInteractions(mockLocalDataSource);
  });
}
