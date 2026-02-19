import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/data/datasources/merchant_category_data_source.dart';
import 'package:expense_tracker/features/categories/data/repositories/merchant_category_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockMerchantCategoryDataSource extends Mock
    implements MerchantCategoryDataSource {}

void main() {
  late MerchantCategoryRepositoryImpl repository;
  late MockMerchantCategoryDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockMerchantCategoryDataSource();
    repository = MerchantCategoryRepositoryImpl(dataSource: mockDataSource);
  });

  const tMerchantId = 'uber';
  const tCategoryId = 'transport';

  test('should return categoryId from dataSource when success', () async {
    // Arrange
    when(
      () => mockDataSource.getDefaultCategoryId(tMerchantId),
    ).thenAnswer((_) async => tCategoryId);

    // Act
    final result = await repository.getDefaultCategoryId(tMerchantId);

    // Assert
    expect(result, const Right(tCategoryId));
    verify(() => mockDataSource.getDefaultCategoryId(tMerchantId)).called(1);
  });

  test(
    'should return CacheFailure when dataSource throws CacheFailure',
    () async {
      // Arrange
      when(
        () => mockDataSource.getDefaultCategoryId(tMerchantId),
      ).thenThrow(const CacheFailure('Failed'));

      // Act
      final result = await repository.getDefaultCategoryId(tMerchantId);

      // Assert
      expect(result, const Left(CacheFailure('Failed')));
      verify(() => mockDataSource.getDefaultCategoryId(tMerchantId)).called(1);
    },
  );
}
