import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late GetCategoriesUseCase useCase;
  late MockCategoryRepository mockRepository;

  setUp(() {
    mockRepository = MockCategoryRepository();
    useCase = GetCategoriesUseCase(mockRepository);
  });

  const tCategory = Category(
    id: '1',
    name: 'Test',
    iconName: 'icon',
    colorHex: '#000000',
    type: CategoryType.expense,
    isCustom: false,
  );

  test('should return categories from repository', () async {
    // Arrange
    when(
      () => mockRepository.getAllCategories(),
    ).thenAnswer((_) async => const Right([tCategory]));

    // Act
    final result = await useCase(const NoParams());

    // Assert
    expect(result, const Right([tCategory]));
    verify(() => mockRepository.getAllCategories()).called(1);
  });

  test('should return Failure when repository fails', () async {
    // Arrange
    when(
      () => mockRepository.getAllCategories(),
    ).thenAnswer((_) async => const Left(ServerFailure()));

    // Act
    final result = await useCase(const NoParams());

    // Assert
    expect(result, const Left(ServerFailure()));
  });
}
