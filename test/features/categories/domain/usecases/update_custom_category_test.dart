import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/usecases/update_custom_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late UpdateCustomCategoryUseCase usecase;
  late MockCategoryRepository mockRepository;

  setUp(() {
    mockRepository = MockCategoryRepository();
    usecase = UpdateCustomCategoryUseCase(mockRepository);
  });

  test('should return ValidationFailure when category is not custom', () async {
    const nonCustomCategory = Category(
      id: '1',
      name: 'Food',
      iconName: 'food',
      colorHex: '#FFFFFF',
      type: CategoryType.expense,
      isCustom: false,
    );

    final params = UpdateCustomCategoryParams(category: nonCustomCategory);
    final result = await usecase(params);

    expect(
      result,
      equals(
        const Left(ValidationFailure('Only custom categories can be updated.')),
      ),
    );
    verifyZeroInteractions(mockRepository);
  });
}
