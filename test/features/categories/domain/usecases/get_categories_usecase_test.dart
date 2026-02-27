import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
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

  test('should call repository.getAllCategories', () async {
    final tCategories = <Category>[];
    when(
      () => mockRepository.getAllCategories(),
    ).thenAnswer((_) async => Right(tCategories));

    final result = await useCase(NoParams());

    expect(result, Right(tCategories));
    verify(() => mockRepository.getAllCategories()).called(1);
  });
}
