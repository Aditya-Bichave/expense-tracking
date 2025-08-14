import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_local_data_source.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_predefined_data_source.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/categories/data/repositories/category_repository_impl.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryLocalDataSource extends Mock implements CategoryLocalDataSource {}

class MockCategoryPredefinedDataSource extends Mock
    implements CategoryPredefinedDataSource {}

void main() {
  late CategoryRepositoryImpl repository;
  late MockCategoryLocalDataSource mockLocal;
  late MockCategoryPredefinedDataSource mockExpensePredefined;
  late MockCategoryPredefinedDataSource mockIncomePredefined;

  setUp(() {
    mockLocal = MockCategoryLocalDataSource();
    mockExpensePredefined = MockCategoryPredefinedDataSource();
    mockIncomePredefined = MockCategoryPredefinedDataSource();
    repository = CategoryRepositoryImpl(
      localDataSource: mockLocal,
      expensePredefinedDataSource: mockExpensePredefined,
      incomePredefinedDataSource: mockIncomePredefined,
    );
  });

  final expenseModel = CategoryModel(
    id: 'e1',
    name: 'Expense',
    iconName: 'icon',
    colorHex: '#000000',
    isCustom: false,
    typeIndex: CategoryType.expense.index,
  );

  test('returns NotFoundFailure when category ID missing', () async {
    when(() => mockExpensePredefined.getPredefinedCategories())
        .thenAnswer((_) async => [expenseModel]);
    when(() => mockIncomePredefined.getPredefinedCategories())
        .thenAnswer((_) async => []);
    when(() => mockLocal.getCustomCategories()).thenAnswer((_) async => []);

    final result = await repository.getCategoryById('missing');

    expect(result.isLeft(), true);
    result.fold(
      (failure) => expect(failure, isA<NotFoundFailure>()),
      (_) => fail('Expected failure'),
    );
  });
}
