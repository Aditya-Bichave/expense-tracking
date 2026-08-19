import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
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

/// The categorizer runs a fixed rule cascade:
///   1. merchant history   (high confidence, categorized)
///   2. description history(medium, needs review)
///   3. merchant database  (medium, needs review)
///   4. keyword match      (medium, needs review)
///   5. nothing            (uncategorized)
///
/// These tests pin the precedence between those rules and the fall-through
/// behaviour when a rule points at a category that no longer exists — which is
/// how a deleted category would otherwise surface as a crash or a silently
/// wrong assignment.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CategorizeTransactionUseCase usecase;
  late MockUserHistoryRepository historyRepository;
  late MockMerchantCategoryRepository merchantRepository;
  late MockCategoryRepository categoryRepository;

  const food = Category(
    id: 'c-food',
    name: 'Food',
    iconName: 'restaurant',
    colorHex: '#FF0000',
    type: CategoryType.expense,
    isCustom: false,
  );
  const travel = Category(
    id: 'c-travel',
    name: 'Travel',
    iconName: 'flight',
    colorHex: '#00FF00',
    type: CategoryType.expense,
    isCustom: false,
  );

  UserHistoryRule rule(RuleType type, String matcher, String categoryId) =>
      UserHistoryRule(
        id: 'r-$matcher',
        ruleType: type,
        matcher: matcher,
        assignedCategoryId: categoryId,
        timestamp: DateTime(2024, 1, 1),
      );

  setUpAll(() {
    registerFallbackValue(RuleType.merchant);
  });

  setUp(() {
    historyRepository = MockUserHistoryRepository();
    merchantRepository = MockMerchantCategoryRepository();
    categoryRepository = MockCategoryRepository();
    usecase = CategorizeTransactionUseCase(
      userHistoryRepository: historyRepository,
      merchantCategoryRepository: merchantRepository,
      categoryRepository: categoryRepository,
    );

    // Default: no rules anywhere. Individual tests opt into a match.
    when(
      () => historyRepository.findRule(any(), any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => merchantRepository.getDefaultCategoryId(any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => categoryRepository.getCategoryById(any()),
    ).thenAnswer((_) async => const Right<Failure, Category?>(null));
  });

  void stubCategory(Category category) {
    when(
      () => categoryRepository.getCategoryById(category.id),
    ).thenAnswer((_) async => Right(category));
  }

  Future<CategorizationResult> categorize({
    String description = 'Some purchase',
    String? merchantId,
  }) async {
    final result = await usecase(
      CategorizeTransactionParams(
        description: description,
        merchantId: merchantId,
      ),
    );
    return result.fold((l) => fail('expected a result, got $l'), (r) => r);
  }

  group('rule precedence', () {
    test('merchant history wins and is high confidence', () async {
      when(
        () => historyRepository.findRule(RuleType.merchant, 'starbucks'),
      ).thenAnswer(
        (_) async => Right(rule(RuleType.merchant, 'starbucks', food.id)),
      );
      stubCategory(food);

      final result = await categorize(merchantId: 'starbucks');

      expect(result.status, CategorizationStatus.categorized);
      expect(result.category?.id, food.id);
      expect(result.confidence, CategorizeTransactionUseCase.confidenceHigh);
      // A merchant-history hit short-circuits: nothing further is consulted.
      verifyNever(() => merchantRepository.getDefaultCategoryId(any()));
    });

    test('description history is used when there is no merchant', () async {
      when(
        () => historyRepository.findRule(RuleType.description, 'monthly rent'),
      ).thenAnswer(
        (_) async => Right(rule(RuleType.description, 'monthly rent', food.id)),
      );
      stubCategory(food);

      final result = await categorize(description: 'Monthly Rent');

      expect(result.status, CategorizationStatus.needsReview);
      expect(result.category?.id, food.id);
      expect(
        result.confidence,
        CategorizeTransactionUseCase.confidenceMediumDescriptionHistory,
      );
    });

    test('the description matcher is trimmed and lowercased', () async {
      when(
        () => historyRepository.findRule(RuleType.description, 'monthly rent'),
      ).thenAnswer(
        (_) async => Right(rule(RuleType.description, 'monthly rent', food.id)),
      );
      stubCategory(food);

      await categorize(description: '   MONTHLY Rent   ');

      verify(
        () => historyRepository.findRule(RuleType.description, 'monthly rent'),
      ).called(1);
    });

    test('the merchant database is consulted after both histories', () async {
      when(
        () => merchantRepository.getDefaultCategoryId('acme'),
      ).thenAnswer((_) async => Right(travel.id));
      stubCategory(travel);

      final result = await categorize(merchantId: 'acme');

      expect(result.status, CategorizationStatus.needsReview);
      expect(result.category?.id, travel.id);
      expect(
        result.confidence,
        CategorizeTransactionUseCase.confidenceMediumMerchant,
      );
    });

    test('nothing matching yields an uncategorized result', () async {
      final result = await categorize(
        description: 'zzzz unmatchable qqqq',
        merchantId: 'unknown-merchant',
      );

      expect(result.status, CategorizationStatus.uncategorized);
      expect(result.category, isNull);
      expect(result.confidence, isNull);
    });

    test('an empty merchant id skips both merchant rules', () async {
      await categorize(merchantId: '');

      verifyNever(() => historyRepository.findRule(RuleType.merchant, any()));
      verifyNever(() => merchantRepository.getDefaultCategoryId(any()));
    });

    test('an empty description skips the description history rule', () async {
      await categorize(description: '   ');

      verifyNever(
        () => historyRepository.findRule(RuleType.description, any()),
      );
    });
  });

  group('rules pointing at a missing category', () {
    test(
      'a stale merchant-history rule falls through to the next rule',
      () async {
        when(
          () => historyRepository.findRule(RuleType.merchant, 'ghost'),
        ).thenAnswer(
          (_) async =>
              Right(rule(RuleType.merchant, 'ghost', 'deleted-category')),
        );
        // The referenced category no longer exists.
        when(
          () => categoryRepository.getCategoryById('deleted-category'),
        ).thenAnswer((_) async => const Right<Failure, Category?>(null));
        // ...but the merchant database still knows the merchant.
        when(
          () => merchantRepository.getDefaultCategoryId('ghost'),
        ).thenAnswer((_) async => Right(travel.id));
        stubCategory(travel);

        final result = await categorize(merchantId: 'ghost');

        // It must not return a null category as "categorized"; it falls through.
        expect(result.status, CategorizationStatus.needsReview);
        expect(result.category?.id, travel.id);
      },
    );

    test('a stale rule with no fallback ends uncategorized', () async {
      when(
        () => historyRepository.findRule(RuleType.merchant, 'ghost'),
      ).thenAnswer(
        (_) async =>
            Right(rule(RuleType.merchant, 'ghost', 'deleted-category')),
      );

      final result = await categorize(
        description: 'zzzz unmatchable qqqq',
        merchantId: 'ghost',
      );

      expect(result.status, CategorizationStatus.uncategorized);
      expect(result.category, isNull);
    });

    test('a category lookup failure is treated as no category', () async {
      when(
        () => historyRepository.findRule(RuleType.merchant, 'acme'),
      ).thenAnswer(
        (_) async => Right(rule(RuleType.merchant, 'acme', food.id)),
      );
      when(() => categoryRepository.getCategoryById(food.id)).thenAnswer(
        (_) async => const Left(CacheFailure('category box closed')),
      );

      final result = await categorize(
        description: 'zzzz unmatchable qqqq',
        merchantId: 'acme',
      );

      expect(result.status, CategorizationStatus.uncategorized);
    });
  });

  group('repository failures are tolerated', () {
    test('a history lookup failure does not abort the cascade', () async {
      when(() => historyRepository.findRule(any(), any())).thenAnswer(
        (_) async => const Left(CacheFailure('history unavailable')),
      );
      when(
        () => merchantRepository.getDefaultCategoryId('acme'),
      ).thenAnswer((_) async => Right(travel.id));
      stubCategory(travel);

      final result = await categorize(merchantId: 'acme');

      // The cascade degrades rather than failing the whole categorization.
      expect(result.category?.id, travel.id);
    });

    test('a merchant database failure still yields a result', () async {
      when(
        () => merchantRepository.getDefaultCategoryId(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('mcdb unavailable')));

      final result = await categorize(
        description: 'zzzz unmatchable qqqq',
        merchantId: 'acme',
      );

      expect(result.status, CategorizationStatus.uncategorized);
    });

    test('an unexpected throw is mapped to UnexpectedFailure', () async {
      when(
        () => historyRepository.findRule(any(), any()),
      ).thenThrow(StateError('boom'));

      final result = await usecase(
        const CategorizeTransactionParams(
          description: 'Anything',
          merchantId: 'acme',
        ),
      );

      expect(
        result.fold((l) => l, (r) => null),
        isA<UnexpectedFailure>().having(
          (f) => f.message,
          'message',
          contains('Error during categorization'),
        ),
      );
    });
  });

  group('CategorizationResult', () {
    test('the uncategorized factory carries no category or confidence', () {
      final result = CategorizationResult.uncategorized();

      expect(result.status, CategorizationStatus.uncategorized);
      expect(result.category, isNull);
      expect(result.confidence, isNull);
    });

    test('results compare by value', () {
      const a = CategorizationResult(
        status: CategorizationStatus.categorized,
        category: food,
        confidence: 0.9,
      );
      const b = CategorizationResult(
        status: CategorizationStatus.categorized,
        category: food,
        confidence: 0.9,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(CategorizationResult.uncategorized())));
    });

    test('the confidence ladder is ordered high to low', () {
      expect(
        CategorizeTransactionUseCase.confidenceHigh,
        greaterThan(
          CategorizeTransactionUseCase.confidenceMediumDescriptionHistory,
        ),
      );
      expect(
        CategorizeTransactionUseCase.confidenceMediumDescriptionHistory,
        greaterThan(CategorizeTransactionUseCase.confidenceMediumMerchant),
      );
      expect(
        CategorizeTransactionUseCase.confidenceMediumMerchant,
        greaterThan(CategorizeTransactionUseCase.confidenceMediumKeyword),
      );
    });
  });
}
