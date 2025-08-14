// ignore_for_file: unused_import

import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_local_data_source.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_predefined_data_source.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart'; // Import enum
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // Keep for potential future use
import 'package:collection/collection.dart'; // Import for firstWhereOrNull

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource localDataSource;
  final CategoryPredefinedDataSource expensePredefinedDataSource;
  final CategoryPredefinedDataSource incomePredefinedDataSource;

  List<Category>? _cachedAllCategories;
  final Map<CategoryType, List<Category>> _cachedSpecificCategories = {};

  CategoryRepositoryImpl({
    required this.localDataSource,
    required this.expensePredefinedDataSource,
    required this.incomePredefinedDataSource,
  });

  // --- Make Invalidation Public ---
  @override // Implement method from interface if added there
  void invalidateCache() {
    _cachedAllCategories = null;
    _cachedSpecificCategories.clear();
    log.info("[CategoryRepo] Cache invalidated explicitly.");
  }
  // --- End ---

  List<Category> _processAndSort(List<CategoryModel> models) {
    final entities = models.map((model) => model.toEntity()).toList();
    entities
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return entities;
  }

  @override
  Future<Either<Failure, List<Category>>> getAllCategories() async {
    log.fine("[CategoryRepo] getAllCategories called.");
    if (_cachedAllCategories != null) {
      log.fine(
          "[CategoryRepo] Returning cached ALL categories (${_cachedAllCategories!.length}).");
      return Right(_cachedAllCategories!);
    }
    try {
      log.fine(
          "[CategoryRepo] Fetching all predefined and custom categories...");
      final results = await Future.wait([
        expensePredefinedDataSource.getPredefinedCategories(),
        incomePredefinedDataSource.getPredefinedCategories(),
        localDataSource.getCustomCategories(),
      ]);
      // Error handling if any future fails - return Left immediately
      // ignore: unused_local_variable
      for (var result in results) {}

      final predefinedExpense = results[0]; // Cast after check
      final predefinedIncome = results[1];
      final custom = results[2];

      log.fine(
          "[CategoryRepo] Fetched ${predefinedExpense.length} exp, ${predefinedIncome.length} inc, ${custom.length} custom.");

      final allModelsMap = <String, CategoryModel>{};
      // Add predefined first, then custom (custom potentially overrides predefined ID if collision, though unlikely)
      for (var model in predefinedExpense) {
        allModelsMap[model.id] = model;
      }
      for (var model in predefinedIncome) {
        allModelsMap[model.id] = model;
      }
      for (var model in custom) {
        allModelsMap[model.id] = model;
      }

      _cachedAllCategories = _processAndSort(allModelsMap.values.toList());
      log.fine(
          "[CategoryRepo] Combined and cached ${_cachedAllCategories!.length} total categories.");
      return Right(_cachedAllCategories!);
    } catch (e, s) {
      log.severe("[CategoryRepo] Error during getAllCategories: $e\n$s");
      invalidateCache(); // Use public method
      return Left(
          CacheFailure("Failed to load all categories: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getSpecificCategories(
      {CategoryType? type, bool includeCustom = true}) async {
    // --- Use getAllCategories as the source of truth to simplify caching ---
    log.fine(
        "[CategoryRepo] getSpecificCategories called. Type: ${type?.name ?? 'All Custom'}, IncludeCustom: $includeCustom");
    final allResult = await getAllCategories(); // This uses the main cache

    return allResult.fold((failure) => Left(failure), (allCategories) {
      final filtered = allCategories.where((cat) {
        bool typeMatch = (type == null) || (cat.type == type);
        bool customMatch = includeCustom || !cat.isCustom;
        return typeMatch && customMatch;
      }).toList();
      log.fine(
          "[CategoryRepo] Filtered specific categories. Count: ${filtered.length}");
      return Right(filtered);
    });
    // --- End Simplification ---
  }

  @override
  Future<Either<Failure, List<Category>>> getCustomCategories(
      {CategoryType? type}) async {
    log.fine(
        "[CategoryRepo] getCustomCategories called. Type filter: ${type?.name ?? 'None'}");
    // --- Use getAllCategories as the source of truth ---
    final allResult = await getAllCategories();
    return allResult.fold((failure) => Left(failure), (allCategories) {
      final filtered = allCategories.where((cat) {
        bool customMatch = cat.isCustom;
        bool typeMatch = (type == null) || (cat.type == type);
        return customMatch && typeMatch;
      }).toList();
      log.fine(
          "[CategoryRepo] Filtered custom categories. Count: ${filtered.length}");
      return Right(filtered);
    });
    // --- End Use ---
  }

  @override
  Future<Either<Failure, Category>> getCategoryById(String categoryId) async {
    log.fine("[CategoryRepo] getCategoryById called for ID: $categoryId");
    final allCategoriesResult = await getAllCategories();
    return allCategoriesResult.fold(
      (failure) => Left(failure),
      (categories) {
        // Use firstWhereOrNull from collection package for safety
        final category =
            categories.firstWhereOrNull((cat) => cat.id == categoryId);
        if (category != null) {
          log.fine("[CategoryRepo] Found category by ID: ${category.name}");
          return Right(category);
        } else {
          log.warning(
              "[CategoryRepo] Category with ID '$categoryId' not found.");
          return Left(
              NotFoundFailure("Category with ID '$categoryId' not found"));
        }
      },
    );
  }

  @override
  Future<Either<Failure, void>> addCustomCategory(Category category) async {
    log.info(
        "[CategoryRepo] addCustomCategory called for '${category.name}', Type: ${category.type.name}.");
    if (!category.isCustom) {
      log.warning("[CategoryRepo] Attempted to add a non-custom category.");
      return const Left(
          ValidationFailure("Only custom categories can be added."));
    }
    try {
      final model = CategoryModel.fromEntity(category);
      await localDataSource.saveCustomCategory(model);
      invalidateCache(); // Invalidate cache after successful add
      log.info(
          "[CategoryRepo] Custom category '${category.name}' added successfully.");
      return const Right(null);
    } catch (e) {
      invalidateCache(); // Also invalidate on error? Maybe not.
      log.warning(
          "[CategoryRepo] Error during addCustomCategory: ${e.toString()}");
      return Left(CacheFailure("Failed to add category: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, void>> updateCategory(Category category) async {
    log.info(
        "[CategoryRepo] updateCategory called for '${category.name}' (ID: ${category.id}), Type: ${category.type.name}. Custom: ${category.isCustom}");
    try {
      final model = CategoryModel.fromEntity(category);
      if (!category.isCustom) {
        log.warning(
            "[CategoryRepo] Updating predefined category personalization NOT YET IMPLEMENTED. Ignoring update.");
        // TODO: Implement saving personalization
        return const Right(null);
      } else {
        await localDataSource.updateCustomCategory(model);
        invalidateCache(); // Invalidate cache after successful update
        log.info(
            "[CategoryRepo] Custom category '${category.name}' updated successfully.");
        return const Right(null);
      }
    } catch (e) {
      invalidateCache(); // Invalidate on error?
      log.warning(
          "[CategoryRepo] Error during updateCategory: ${e.toString()}");
      return Left(CacheFailure("Failed to update category: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomCategory(
      String categoryId, String fallbackCategoryId) async {
    log.info(
        "[CategoryRepo] deleteCustomCategory called for ID: $categoryId. Fallback: $fallbackCategoryId");
    // Transaction reassignment is handled in UseCase/Bloc
    try {
      await localDataSource.deleteCustomCategory(categoryId);
      invalidateCache(); // Invalidate cache after successful delete
      log.info(
          "[CategoryRepo] Custom category (ID: $categoryId) deleted successfully from local source.");
      return const Right(null);
    } catch (e) {
      invalidateCache(); // Invalidate on error?
      log.warning(
          "[CategoryRepo] Error during deleteCustomCategory: ${e.toString()}");
      return Left(CacheFailure("Failed to delete category: ${e.toString()}"));
    }
  }
}
