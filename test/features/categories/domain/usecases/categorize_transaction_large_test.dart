import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/categories/domain/usecases/categorize_transaction.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/merchant_category_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/user_history_repository.dart';

class MockCategoryRepo extends Mock implements CategoryRepository {}

class MockMerchantRepo extends Mock implements MerchantCategoryRepository {}

class MockUserHistoryRepo extends Mock implements UserHistoryRepository {}

void main() {
  late CategorizeTransactionUseCase usecase;

  setUp(() {
    usecase = CategorizeTransactionUseCase(
      categoryRepository: MockCategoryRepo(),
      merchantCategoryRepository: MockMerchantRepo(),
      userHistoryRepository: MockUserHistoryRepo(),
    );
  });

  test('can be instantiated', () {
    expect(usecase, isNotNull);
  });
}
