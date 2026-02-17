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

  final tCategories = [
    Category(
      id: '1',
      name: 'Food',
      iconName: 'food',
      colorHex: '#FFFFFF',
      type: CategoryType.expense,
      isCustom: false,
    ),
  ];

  test('should get categories from repository', () async {
    // arrange
    when(
      () => mockRepository.getAllCategories(),
    ).thenAnswer((_) async => Right(tCategories));

    // act
    final result = await useCase(NoParams());

    // assert
    expect(result, Right(tCategories));
    verify(() => mockRepository.getAllCategories());
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // arrange
    when(
      () => mockRepository.getAllCategories(),
    ).thenAnswer((_) async => Left(CacheFailure()));

    // act
    final result = await useCase(NoParams());

    // assert
    expect(result.isLeft(), true);
    verify(() => mockRepository.getAllCategories());
  });
}
