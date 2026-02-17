
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_income_categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late GetIncomeCategoriesUseCase useCase;
  late MockCategoryRepository mockRepository;

  setUp(() {
    mockRepository = MockCategoryRepository();
    useCase = GetIncomeCategoriesUseCase(mockRepository);
  });

  final tCategories = [
    const Category(
      id: '1',
      name: 'Salary',
      iconName: 'cash',
      colorHex: '#000000',
      type: CategoryType.income,
      isCustom: false,
    ),
  ];

  test('should get income categories from the repository', () async {
    // arrange
    when(
      () => mockRepository.getSpecificCategories(
        type: CategoryType.income,
        includeCustom: true,
      ),
    ).thenAnswer((_) async => Right(tCategories));

    // act
    final result = await useCase(NoParams());

    // assert
    expect(result, Right(tCategories));
    verify(
      () => mockRepository.getSpecificCategories(
        type: CategoryType.income,
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
        type: CategoryType.income,
        includeCustom: true,
      ),
    ).thenAnswer((_) async => Left(ServerFailure('Server Failure')));

    // act
    final result = await useCase(NoParams());

    // assert
    expect(result, Left(ServerFailure('Server Failure')));
    verify(
      () => mockRepository.getSpecificCategories(
        type: CategoryType.income,
        includeCustom: true,
      ),
    );
    verifyNoMoreInteractions(mockRepository);
  });
}
