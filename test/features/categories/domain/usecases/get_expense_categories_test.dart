
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_expense_categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late GetExpenseCategoriesUseCase useCase;
  late MockCategoryRepository mockRepository;

  setUp(() {
    mockRepository = MockCategoryRepository();
    useCase = GetExpenseCategoriesUseCase(mockRepository);
  });

  final tCategories = [
    const Category(
      id: '1',
      name: 'Food',
      iconName: 'food',
      colorHex: '#000000',
      type: CategoryType.expense,
      isCustom: false,
    ),
  ];

  test('should get expense categories from the repository', () async {
    // arrange
    when(
      () => mockRepository.getSpecificCategories(
        type: CategoryType.expense,
        includeCustom: true,
      ),
    ).thenAnswer((_) async => Right(tCategories));

    // act
    final result = await useCase(NoParams());

    // assert
    expect(result, Right(tCategories));
    verify(
      () => mockRepository.getSpecificCategories(
        type: CategoryType.expense,
        includeCustom: true,
      ),
    );
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return a failure when the repository call is unsuccessful',
      () async {
    // arrange
    when(
      () => mockRepository.getSpecificCategories(
        type: CategoryType.expense,
        includeCustom: true,
      ),
    ).thenAnswer((_) async => Left(ServerFailure('Server Failure')));

    // act
    final result = await useCase(NoParams());

    // assert
    expect(result, Left(ServerFailure('Server Failure')));
    verify(
      () => mockRepository.getSpecificCategories(
        type: CategoryType.expense,
        includeCustom: true,
      ),
    );
    verifyNoMoreInteractions(mockRepository);
  });
}
