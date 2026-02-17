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
  late UpdateCustomCategoryUseCase useCase;
  late MockCategoryRepository mockRepository;

  setUp(() {
    mockRepository = MockCategoryRepository();
    useCase = UpdateCustomCategoryUseCase(mockRepository);
  });

  const tCategory = Category(
    id: '1',
    name: 'Updated Name',
    iconName: 'icon',
    colorHex: '#000000',
    type: CategoryType.expense,
    isCustom: true,
  );

  final tParams = const UpdateCustomCategoryParams(category: tCategory);

  test('should update a custom category in the repository', () async {
    // arrange
    when(
      () => mockRepository.getAllCategories(),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => mockRepository.updateCategory(any()),
    ).thenAnswer((_) async => const Right(null));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result, const Right(null));
    verify(() => mockRepository.updateCategory(tCategory));
    verify(() => mockRepository.getAllCategories());
  });

  test('should return validation failure if category is not custom', () async {
    // arrange
    const nonCustomCategory = Category(
      id: '1',
      name: 'Default',
      iconName: 'icon',
      colorHex: '#000000',
      type: CategoryType.expense,
      isCustom: false,
    );
    final params = const UpdateCustomCategoryParams(
      category: nonCustomCategory,
    );

    // act
    final result = await useCase(params);

    // assert
    expect(
      result,
      const Left(ValidationFailure("Only custom categories can be updated.")),
    );
    verifyZeroInteractions(mockRepository);
  });
}
