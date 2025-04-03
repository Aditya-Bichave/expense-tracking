import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_suggestion.dart'; // Make sure this exists
import 'package:expense_tracker/features/categories/domain/entities/user_history_rule.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/user_history_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/merchant_category_repository.dart';
import 'package:expense_tracker/core/utils/enums.dart'; // Import CategorizationStatus
import 'package:expense_tracker/main.dart'; // logger

// Input parameters for the use case
class CategorizeTransactionParams extends Equatable {
  final String? merchantId; // Can be null
  final String description;
  // Add amount, date etc. if needed for more advanced rules

  const CategorizeTransactionParams({
    this.merchantId,
    required this.description,
  });

  @override
  List<Object?> get props => [merchantId, description];
}

// Output structure
class CategorizationResult extends Equatable {
  final CategorizationStatus status;
  final Category? category; // Null if uncategorized
  final double? confidence; // Null if uncategorized

  const CategorizationResult({
    required this.status,
    this.category,
    this.confidence,
  });

  // Helper factory for uncategorized result
  factory CategorizationResult.uncategorized() {
    return CategorizationResult(
      status: CategorizationStatus.uncategorized,
      category: null,
      confidence: null,
    );
  }

  @override
  List<Object?> get props => [status, category, confidence];
}

class CategorizeTransactionUseCase
    implements UseCase<CategorizationResult, CategorizeTransactionParams> {
  final UserHistoryRepository userHistoryRepository;
  final MerchantCategoryRepository merchantCategoryRepository;
  final CategoryRepository
      categoryRepository; // Needed to get Category object from ID

  // TODO: Inject keyword matching service/logic if it becomes complex
  // final KeywordMatcherService keywordMatcher;

  // --- Keyword Matching Data (Simple Example) ---
  static const Map<String, List<String>> _keywordCategoryMap = {
    // Use Category ID as key now for consistency
    'transport': [
      'uber',
      'lyft',
      'taxi',
      'bus fare',
      'train ticket',
      'subway',
      'transportation',
      'gas',
      'fuel',
      'parking'
    ],
    'groceries': [
      'grocery',
      'supermarket',
      'market',
      'safeway',
      'kroger',
      'tesco',
      'waitrose'
    ],
    'subscriptions': [
      'netflix',
      'spotify',
      'hulu',
      'disney+',
      'prime video',
      'subscription',
      'membership',
      'patreon'
    ],
    'food': [
      'restaurant',
      'cafe',
      'coffee',
      'lunch',
      'dinner',
      'meal',
      'food',
      'takeaway',
      'delivery'
    ],
    'utilities': [
      'utility',
      'electric',
      'water bill',
      'gas bill',
      'internet',
      'phone bill',
      'power'
    ],
    'housing': ['rent', 'mortgage', 'lease'],
    'shopping': [
      'amazon',
      'target',
      'walmart',
      'clothes',
      'shopping',
      'purchase'
    ],
    'salary': ['salary', 'payroll', 'paycheck', 'direct deposit'],
    'freelance': ['freelance', 'invoice', 'contract'],
    'interest': ['interest payment', 'bank interest'],
    'other': ['other'], // Ensure 'other' is defined as a predefined category ID
    // Add more mappings... Ensure keys match predefined category IDs or names if needed
  };
  // --- End Keyword Data ---

  CategorizeTransactionUseCase({
    required this.userHistoryRepository,
    required this.merchantCategoryRepository,
    required this.categoryRepository,
    // required this.keywordMatcher,
  });

  static const double confidenceHigh = 0.9;
  static const double confidenceMediumMerchant = 0.7;
  static const double confidenceMediumKeyword = 0.6;
  static const double confidenceMediumDescriptionHistory = 0.75;

  @override
  Future<Either<Failure, CategorizationResult>> call(
      CategorizeTransactionParams params) async {
    log.info(
        "[CategorizeUseCase] Executing for Merchant: '${params.merchantId}', Desc: '${params.description}'");

    try {
      // --- Rule Cascade ---

      // 1. Check User History (Merchant)
      if (params.merchantId != null && params.merchantId!.isNotEmpty) {
        final historyResult = await userHistoryRepository.findRule(
            RuleType.merchant, params.merchantId!);
        if (historyResult.isRight()) {
          final rule = historyResult.getOrElse(() => null);
          if (rule != null) {
            log.info(
                "[CategorizeUseCase] Found HIGH confidence match via Merchant History: CatID ${rule.assignedCategoryId}");
            final category = await _getCategoryById(rule.assignedCategoryId);
            if (category != null) {
              return Right(CategorizationResult(
                status: CategorizationStatus.categorized,
                category: category,
                confidence: confidenceHigh,
              ));
            } else {
              log.warning(
                  "[CategorizeUseCase] Merchant history rule points to non-existent category ID: ${rule.assignedCategoryId}");
            }
          }
        }
      }

      // 2. Check User History (Description)
      final String descriptionMatcher =
          _simplifyDescription(params.description);
      if (descriptionMatcher.isNotEmpty) {
        final historyResult = await userHistoryRepository.findRule(
            RuleType.description, descriptionMatcher);
        if (historyResult.isRight()) {
          final rule = historyResult.getOrElse(() => null);
          if (rule != null) {
            log.info(
                "[CategorizeUseCase] Found MEDIUM confidence match via Description History: CatID ${rule.assignedCategoryId}");
            final category = await _getCategoryById(rule.assignedCategoryId);
            if (category != null) {
              return Right(CategorizationResult(
                status: CategorizationStatus.needsReview,
                category: category,
                confidence: confidenceMediumDescriptionHistory,
              ));
            } else {
              log.warning(
                  "[CategorizeUseCase] Description history rule points to non-existent category ID: ${rule.assignedCategoryId}");
            }
          }
        }
      }

      // 3. Check Merchant Database (MCDB)
      if (params.merchantId != null && params.merchantId!.isNotEmpty) {
        final mcdbResult = await merchantCategoryRepository
            .getDefaultCategoryId(params.merchantId!);
        if (mcdbResult.isRight()) {
          final categoryId = mcdbResult.getOrElse(() => null);
          if (categoryId != null) {
            log.info(
                "[CategorizeUseCase] Found MEDIUM confidence match via MCDB: CatID $categoryId");
            final category = await _getCategoryById(categoryId);
            if (category != null) {
              return Right(CategorizationResult(
                status: CategorizationStatus.needsReview,
                category: category,
                confidence: confidenceMediumMerchant,
              ));
            } else {
              log.warning(
                  "[CategorizeUseCase] MCDB rule points to non-existent category ID: $categoryId");
            }
          }
        }
      }

      // 4. Check Keyword Matching
      final String? keywordCategoryId = _matchKeywords(params.description);
      if (keywordCategoryId != null) {
        log.info(
            "[CategorizeUseCase] Found MEDIUM confidence match via Keyword: CatID $keywordCategoryId");
        final category = await _getCategoryById(keywordCategoryId);
        if (category != null) {
          return Right(CategorizationResult(
            status: CategorizationStatus.needsReview,
            category: category,
            confidence: confidenceMediumKeyword,
          ));
        } else {
          log.warning(
              "[CategorizeUseCase] Keyword rule points to non-existent category ID: $keywordCategoryId");
        }
      }

      // 5. No Matches Found
      log.info(
          "[CategorizeUseCase] No rules matched. Returning Uncategorized.");
      return Right(CategorizationResult.uncategorized());
    } catch (e, s) {
      log.severe(
          "[CategorizeUseCase] Unexpected error during categorization$e$s");
      return Left(
          UnexpectedFailure("Error during categorization: ${e.toString()}"));
    }
  }

  // Uses the CORRECTED repository method signature
  Future<Category?> _getCategoryById(String? categoryId) async {
    if (categoryId == null) return null;
    // Call the method added to the CategoryRepository interface
    final result = await categoryRepository.getCategoryById(categoryId);
    return result.fold(
      (failure) {
        log.warning(
            "Failed to fetch category details for ID $categoryId: ${failure.message}");
        return null;
      },
      (category) => category, // Returns the Category? from the Right side
    );
  }

  String _simplifyDescription(String description) {
    return description.trim().toLowerCase();
  }

  String? _matchKeywords(String description) {
    final lowerDesc = description.toLowerCase();
    log.fine("[CategorizeUseCase] Keyword matching on: '$lowerDesc'");
    for (final entry in _keywordCategoryMap.entries) {
      final categoryId = entry.key; // Assumes key is category ID
      final keywords = entry.value;
      for (final keyword in keywords) {
        final regex = RegExp(r'\b' + keyword + r'\b',
            caseSensitive: false); // Added case-insensitive
        if (regex.hasMatch(lowerDesc)) {
          log.fine(
              "[CategorizeUseCase] Keyword match found: '$keyword' -> Category ID '$categoryId'");
          return categoryId;
        }
      }
    }
    log.fine("[CategorizeUseCase] No keyword match found.");
    return null;
  }
}
