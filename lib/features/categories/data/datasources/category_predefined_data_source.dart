import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/features/categories/data/models/category_model.dart';

// Interface remains generic for now, implementations handle specifics
abstract class CategoryPredefinedDataSource {
  Future<List<CategoryModel>> getPredefinedCategories();
}

// --- Implementation for EXPENSE Categories ---
class AssetExpenseCategoryDataSource implements CategoryPredefinedDataSource {
  List<CategoryModel>? _cachedCategories;
  final String _assetPath =
      'assets/data/predefined_expense_categories.json'; // Updated path

  @override
  Future<List<CategoryModel>> getPredefinedCategories() async {
    // Caching logic remains the same
    if (_cachedCategories != null) {
      log.info(
        "Returning cached predefined EXPENSE categories (${_cachedCategories!.length}).",
      );
      return _cachedCategories!;
    }

    log.info("Loading predefined EXPENSE categories from asset: $_assetPath");
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      final categories = jsonList
          .map(
            (jsonItem) =>
                CategoryModel.fromJson(jsonItem as Map<String, dynamic>),
          )
          .toList();

      // Validation (no custom allowed)
      categories.removeWhere((cat) {
        if (cat.isCustom) {
          log.warning(
            "Predefined expense category loaded from asset has isCustom=true! ID: ${cat.id}. Removing.",
          );
          return true;
        }
        return false;
      });

      _cachedCategories = categories;
      log.info(
        "Successfully loaded and cached ${_cachedCategories!.length} predefined EXPENSE categories.",
      );
      return _cachedCategories!;
    } on FormatException catch (e, s) {
      log.severe(
        "Failed to parse predefined expense categories JSON from asset '$_assetPath'$e$s",
      );
      _cachedCategories = []; // Return empty on format error
      throw const CacheFailure(
        'Invalid format in predefined expense categories asset file.',
      );
    } catch (e, s) {
      log.severe(
        "Failed to load predefined expense categories from asset '$_assetPath'$e$s",
      );
      _cachedCategories = []; // Return empty on other errors
      throw CacheFailure(
        'Could not load predefined expense categories: ${e.toString()}',
      );
    }
  }
}

// --- Implementation for INCOME Categories ---
class AssetIncomeCategoryDataSource implements CategoryPredefinedDataSource {
  List<CategoryModel>? _cachedCategories;
  final String _assetPath =
      'assets/data/predefined_income_categories.json'; // Updated path

  @override
  Future<List<CategoryModel>> getPredefinedCategories() async {
    // Caching logic remains the same
    if (_cachedCategories != null) {
      log.info(
        "Returning cached predefined INCOME categories (${_cachedCategories!.length}).",
      );
      return _cachedCategories!;
    }

    log.info("Loading predefined INCOME categories from asset: $_assetPath");
    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      final categories = jsonList
          .map(
            (jsonItem) =>
                CategoryModel.fromJson(jsonItem as Map<String, dynamic>),
          )
          .toList();

      // Validation (no custom allowed)
      categories.removeWhere((cat) {
        if (cat.isCustom) {
          log.warning(
            "Predefined income category loaded from asset has isCustom=true! ID: ${cat.id}. Removing.",
          );
          return true;
        }
        return false;
      });

      _cachedCategories = categories;
      log.info(
        "Successfully loaded and cached ${_cachedCategories!.length} predefined INCOME categories.",
      );
      return _cachedCategories!;
    } on FormatException catch (e, s) {
      log.severe(
        "Failed to parse predefined income categories JSON from asset '$_assetPath'$e$s",
      );
      _cachedCategories = [];
      throw const CacheFailure(
        'Invalid format in predefined income categories asset file.',
      );
    } catch (e, s) {
      log.severe(
        "Failed to load predefined income categories from asset '$_assetPath'$e$s",
      );
      _cachedCategories = [];
      throw CacheFailure(
        'Could not load predefined income categories: ${e.toString()}',
      );
    }
  }
}
