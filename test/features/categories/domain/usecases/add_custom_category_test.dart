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

  const tParams = AddCustomCategoryParams(
    name: 'New Cat',
    iconName: 'icon',
    colorHex: '#000000',
    type: CategoryType.expense,
  );

  test('should add custom category when validation passes', () async {
    // Arrange
    when(
      () => mockRepository.getAllCategories(),
    ).thenAnswer((_) async => const Right([]));
    when(() => mockUuid.v4()).thenReturn('new-id');
    when(
      () => mockRepository.addCustomCategory(any()),
    ).thenAnswer((_) async => const Right(null));

    // Act
    final result = await useCase(tParams);

    // Assert
    expect(result, const Right(null));
    verify(() => mockRepository.addCustomCategory(any<Category>())).called(1);
  });

  test('should return ValidationFailure when name is empty', () async {
    // Arrange
    final params = AddCustomCategoryParams(
      name: '',
      iconName: 'icon',
      colorHex: '#000000',
      type: CategoryType.expense,
    );

    // Act
    final result = await useCase(params);

    // Assert
    expect(result.isLeft(), isTrue);
    expect(result.fold((l) => l, (r) => null), isA<ValidationFailure>());
  });

  test(
    'should return ValidationFailure when category already exists',
    () async {
      // Arrange
      final existingCategory = Category(
        id: '1',
        name: 'New Cat',
        iconName: 'icon',
        colorHex: '#000000',
        type: CategoryType.expense,
        isCustom: true,
      );
      when(
        () => mockRepository.getAllCategories(),
      ).thenAnswer((_) async => Right([existingCategory]));

      // Act
      final result = await useCase(tParams);

      // Assert
      expect(result.isLeft(), isTrue);
      expect(result.fold((l) => l, (r) => null), isA<ValidationFailure>());
    },
  );
}
