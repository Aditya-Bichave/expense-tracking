
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
  late AddCustomCategoryUseCase useCase;
  late MockCategoryRepository mockRepository;
  late MockUuid mockUuid;

  setUp(() {
    mockRepository = MockCategoryRepository();
    mockUuid = MockUuid();
    useCase = AddCustomCategoryUseCase(mockRepository, mockUuid);
  });

  const tName = 'New Category';
  const tIcon = 'icon';
  const tColor = '#FFFFFF';
  const tType = CategoryType.expense;
  const tId = 'generated-id';

  final tParams = const AddCustomCategoryParams(
    name: tName,
    iconName: tIcon,
    colorHex: tColor,
    type: tType,
  );

  final tCategory = Category(
    id: tId,
    name: tName,
    iconName: tIcon,
    colorHex: tColor,
    type: tType,
    isCustom: true,
  );

  test('should add a custom category to the repository', () async {
    // arrange
    when(() => mockUuid.v4()).thenReturn(tId);
    when(() => mockRepository.getAllCategories())
        .thenAnswer((_) async => const Right([]));
    when(() => mockRepository.addCustomCategory(any()))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result, const Right(null));
    verify(() => mockRepository.addCustomCategory(tCategory));
    verify(() => mockRepository.getAllCategories());
  });

  test('should return validation failure if name is empty', () async {
    // arrange
    final invalidParams = const AddCustomCategoryParams(
      name: '',
      iconName: tIcon,
      colorHex: tColor,
      type: tType,
    );

    // act
    final result = await useCase(invalidParams);

    // assert
    expect(result, const Left(ValidationFailure("Category name cannot be empty.")));
    verifyZeroInteractions(mockRepository);
  });

    test('should return validation failure if category exists', () async {
    // arrange
    when(() => mockUuid.v4()).thenReturn(tId);
    when(() => mockRepository.getAllCategories())
        .thenAnswer((_) async => Right([tCategory])); // Existing category

    // act
    final result = await useCase(tParams);

    // assert
    expect(
        result,
        const Left(ValidationFailure(
            "A category with this name already exists in the selected category group.")));
    verify(() => mockRepository.getAllCategories());
    verifyNever(() => mockRepository.addCustomCategory(any()));
  });
}
