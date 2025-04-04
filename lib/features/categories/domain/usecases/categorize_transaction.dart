// lib/features/categories/domain/usecases/categorize_transaction.dart
// MODIFIED FILE (Load Keywords from Asset)
import 'dart:convert'; // For jsonDecode
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/user_history_rule.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/user_history_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/merchant_category_repository.dart';
import 'package:expense_tracker/core/utils/enums.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/services.dart' show rootBundle; // For loading assets

// Input parameters remain the same
class CategorizeTransactionParams extends Equatable {
  final String? merchantId;
  final String description;
  const CategorizeTransactionParams(
      {this.merchantId, required this.description});
  @override
  List<Object?> get props => [merchantId, description];
}

// Output structure remains the same
class CategorizationResult extends Equatable {
  final CategorizationStatus status;
  final Category? category;
  final double? confidence;
  const CategorizationResult(
      {required this.status, this.category, this.confidence});
  factory CategorizationResult.uncategorized() {
    return const CategorizationResult(
        status: CategorizationStatus.uncategorized);
  }
  @override
  List<Object?> get props => [status, category, confidence];
}

class CategorizeTransactionUseCase
    implements UseCase<CategorizationResult, CategorizeTransactionParams> {
  final UserHistoryRepository userHistoryRepository;
  final MerchantCategoryRepository merchantCategoryRepository;
  final CategoryRepository categoryRepository;

  // Keyword data - now loaded async
  static Map<String, List<String>>?
      _keywordCategoryMap; // Cache loaded keywords
  static bool _keywordsLoading = false;
  static const String _keywordAssetPath = 'assets/data/category_keywords.json';

  CategorizeTransactionUseCase({
    required this.userHistoryRepository,
    required this.merchantCategoryRepository,
    required this.categoryRepository,
  });

  static const double confidenceHigh = 0.9;
  static const double confidenceMediumMerchant = 0.7;
  static const double confidenceMediumKeyword = 0.6;
  static const double confidenceMediumDescriptionHistory = 0.75;

  // --- Load Keywords Helper ---
  Future<Either<Failure, Map<String, List<String>>>> _loadKeywords() async {
    if (_keywordCategoryMap != null) return Right(_keywordCategoryMap!);
    if (_keywordsLoading) {
      await Future.delayed(
          const Duration(milliseconds: 100)); // Wait if already loading
      return _loadKeywords(); // Retry
    }
    _keywordsLoading = true;
    log.info(
        "[CategorizeUseCase] Loading keywords from asset: $_keywordAssetPath");
    try {
      final jsonString = await rootBundle.loadString(_keywordAssetPath);
      final Map<String, dynamic> jsonMap =
          jsonDecode(jsonString) as Map<String, dynamic>;
      // Convert dynamic list to List<String>
      _keywordCategoryMap = jsonMap.map((key, value) {
        final List<String> keywords = (value as List<dynamic>)
            .map((e) => e.toString().toLowerCase())
            .toList();
        return MapEntry(key, keywords); // Assuming key is category ID
      });
      log.info(
          "[CategorizeUseCase] Loaded and cached ${_keywordCategoryMap!.length} keyword categories.");
      return Right(_keywordCategoryMap!);
    } catch (e, s) {
      log.severe(
          "[CategorizeUseCase] Failed to load keywords from asset '$_keywordAssetPath'$e$s");
      _keywordCategoryMap = {}; // Cache empty map on error
      return Left(
          CacheFailure("Could not load category keywords: ${e.toString()}"));
    } finally {
      _keywordsLoading = false;
    }
  }
  // --- End Load Keywords ---

  @override
  Future<Either<Failure, CategorizationResult>> call(
      CategorizeTransactionParams params) async {
    log.info(
        "[CategorizeUseCase] Executing for Merchant: '${params.merchantId}', Desc: '${params.description}'");

    try {
      // --- Ensure Keywords are Loaded ---
      final keywordsEither = await _loadKeywords();
      if (keywordsEither.isLeft()) {
        // Propagate failure if keywords couldn't load
        return keywordsEither.fold((l) => Left(l),
            (_) => const Left(UnexpectedFailure("Keyword loading failed")));
      }
      final keywordMap = keywordsEither
          .getOrElse(() => {}); // Should not be empty if load succeeded
      // --- End Keyword Loading ---

      // --- Rule Cascade ---

      // 1. Check User History (Merchant)
      if (params.merchantId != null && params.merchantId!.isNotEmpty) {
        /* ... Merchant History check ... */
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
        /* ... Description History check ... */
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
        /* ... MCDB check ... */
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

      // 4. Check Keyword Matching (Use loaded map)
      final String? keywordCategoryId =
          _matchKeywords(params.description, keywordMap); // Pass loaded map
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

  Future<Category?> _getCategoryById(String? categoryId) async {
    /* ... same as before ... */
    if (categoryId == null) return null;
    final result = await categoryRepository.getCategoryById(categoryId);
    return result.fold(
      (failure) {
        log.warning(
            "Failed to fetch category details for ID $categoryId: ${failure.message}");
        return null;
      },
      (category) => category,
    );
  }

  String _simplifyDescription(String description) {
    /* ... same as before ... */
    return description.trim().toLowerCase();
  }

  // --- Updated Keyword Matching Implementation ---
  String? _matchKeywords(
      String description, Map<String, List<String>> keywordMap) {
    final lowerDesc = description.toLowerCase();
    log.fine("[CategorizeUseCase] Keyword matching on: '$lowerDesc'");
    for (final entry in keywordMap.entries) {
      final categoryId = entry.key;
      final keywords = entry.value; // Already lowercase from loading
      for (final keyword in keywords) {
        final regex = RegExp(r'\b' +
            keyword +
            r'\b'); // caseSensitive defaults to true, but keywords are lower
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
  // --- End Keyword Matching ---
}
