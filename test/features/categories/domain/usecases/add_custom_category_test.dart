import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/usecases/add_custom_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}
class MockUuid extends Mock implements Uuid {}

void main() {
  late AddCustomCategoryUseCase usecase;
  late MockCategoryRepository mockCategoryRepository;
  late MockUuid mockUuid;

  setUp(() {
    mockCategoryRepository = MockCategoryRepository();
    mockUuid = MockUuid();
    usecase = AddCustomCategoryUseCase(mockCategoryRepository, mockUuid);
  });

  const tCategory = Category(
    id: '1',
    name: 'Test',
    iconName: 'icon',
    colorHex: '#ffffff',
    type: CategoryType.expense,
    isCustom: true,
  );

  test('should return validation failure when category with same name exists', () async {
    // Arrange
    when(() => mockCategoryRepository.getAllCategories()).thenAnswer((_) async => const Right([tCategory]));
    const params = AddCustomCategoryParams(
      name: 'Test',
      iconName: 'icon',
      colorHex: '#ffffff',
      type: CategoryType.expense,
    );

    // Act
    final result = await usecase(params);

    // Assert
    expect(result, const Left(ValidationFailure('A category with this name already exists in the selected category group.')));
    verify(() => mockCategoryRepository.getAllCategories()).called(1);
    verifyNoMoreInteractions(mockCategoryRepository);
  });
}
