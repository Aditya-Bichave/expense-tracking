import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/usecases/update_custom_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

class FakeCategory extends Fake implements Category {}

void main() {
  late UpdateCustomCategoryUseCase useCase;
  late MockCategoryRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeCategory());
  });

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

  test('should update category when validation passes', () async {
    // Arrange
    when(
      () => mockRepository.getAllCategories(),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => mockRepository.updateCategory(any()),
    ).thenAnswer((_) async => const Right(null));

    // Act
    final result = await useCase(const UpdateCustomCategoryParams(category: tCategory));

    // Assert
    expect(result, const Right(null));
    verify(() => mockRepository.updateCategory(tCategory)).called(1);
  });

  test('should return ValidationFailure when category is not custom', () async {
    // Arrange
    final nonCustom = tCategory.copyWith(isCustom: false);

    // Act
    final result = await useCase(UpdateCustomCategoryParams(category: nonCustom));

    // Assert
    expect(result.isLeft(), isTrue);
    expect(result.fold((l) => l, (r) => null), isA<ValidationFailure>());
  });
}
