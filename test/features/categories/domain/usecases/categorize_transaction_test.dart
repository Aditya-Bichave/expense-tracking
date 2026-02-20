import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/entities/user_history_rule.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/merchant_category_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/user_history_repository.dart';
import 'package:expense_tracker/features/categories/domain/usecases/categorize_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserHistoryRepository extends Mock implements UserHistoryRepository {}

class MockMerchantCategoryRepository extends Mock
    implements MerchantCategoryRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // Ensure binding for asset loading

  late CategorizeTransactionUseCase usecase;
  late MockUserHistoryRepository mockUserHistoryRepository;
  late MockMerchantCategoryRepository mockMerchantCategoryRepository;
  late MockCategoryRepository mockCategoryRepository;

  final tCategory = Category(
    id: '1',
    name: 'Food',
    iconName: 'food',
    colorHex: 'red',
    type: CategoryType.expense,
    isCustom: true,
  );

  setUpAll(() {
    registerFallbackValue(RuleType.merchant);
  });

  setUp(() {
    mockUserHistoryRepository = MockUserHistoryRepository();
    mockMerchantCategoryRepository = MockMerchantCategoryRepository();
    mockCategoryRepository = MockCategoryRepository();
    usecase = CategorizeTransactionUseCase(
      userHistoryRepository: mockUserHistoryRepository,
      merchantCategoryRepository: mockMerchantCategoryRepository,
      categoryRepository: mockCategoryRepository,
    );
  });

  test('should return High confidence match if found in Merchant History', () async {
    when(() => mockUserHistoryRepository.findRule(any(), any())).thenAnswer(
      (_) async => Right(
        UserHistoryRule(
          id: 'r1',
          ruleType: RuleType.merchant,
          matcher: 'merchant_id',
          assignedCategoryId: '1',
          timestamp: DateTime.now(),
        ),
      ),
    );
    when(
      () => mockCategoryRepository.getCategoryById('1'),
    ).thenAnswer((_) async => Right(tCategory));

    final result = await usecase(
      const CategorizeTransactionParams(
        merchantId: 'merchant_id',
        description: 'desc',
      ),
    );

    // The logic inside usecase likely fails to load assets during test, catching the error and returning Right(Uncategorized) or Left.
    // However, since we mock repositories, if the logic reaches them, it should work.
    // The issue is likely _loadKeywords failing.
    // But even if it fails, it just logs error and proceeds?
    // Let's inspect result if possible or assume it falls through if keywords fail.

    // Actually, if _loadKeywords throws, it might be caught in try-catch block of 'call' and return Left(UnexpectedFailure).
    // Let's assert based on what we expect. Ideally we mock rootBundle or asset loading, but that's hard.
    // CategorizeTransactionUseCase implementation catches all errors.

    // Assuming for this test we want to verify the MERCHANT HISTORY path, which comes BEFORE keyword loading.
    // Wait, let's check the code order in previous .
    // Merchant History check (step 1) is BEFORE Keyword check (step 4).
    // So if merchant history matches, it should return immediately!

    expect(result.isRight(), true);
    final categorization = result.getOrElse(() => throw Exception());

    // If it fell through to uncategorized due to error, status would be uncategorized.
    // If it worked, it should be categorized.
    expect(categorization.status, CategorizationStatus.categorized);
    expect(categorization.category, tCategory);
  });
}
