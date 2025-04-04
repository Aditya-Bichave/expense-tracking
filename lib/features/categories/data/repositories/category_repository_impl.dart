import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_local_data_source.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_predefined_data_source.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart'; // Import enum
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/di/service_locator.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource localDataSource;
  final CategoryPredefinedDataSource expensePredefinedDataSource;
  final CategoryPredefinedDataSource incomePredefinedDataSource;

  // Caching (consider invalidating more granularly if performance requires)
  List<Category>? _cachedAllCategories;
  // Cache specific types if fetched often
  Map<CategoryType, List<Category>> _cachedSpecificCategories = {};
  List<Category>? _cachedCustomCategories;

  CategoryRepositoryImpl({
    required this.localDataSource,
    required this.expensePredefinedDataSource,
    required this.incomePredefinedDataSource,
  });

  void _invalidateCaches() {
    _cachedAllCategories = null;
    _cachedSpecificCategories.clear();
    _cachedCustomCategories = null;
    log.fine("[CategoryRepo] Caches invalidated.");
  }

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
      final predefinedExpense = results[0];
      final predefinedIncome = results[1];
      final custom = results[2];
      log.fine(
          "[CategoryRepo] Fetched ${predefinedExpense.length} exp, ${predefinedIncome.length} inc, ${custom.length} custom.");

      // Combine, removing potential duplicates (less likely now with type field)
      final allModels =
          {...predefinedExpense, ...predefinedIncome, ...custom}.toList();
      _cachedAllCategories = _processAndSort(allModels);
      log.fine(
          "[CategoryRepo] Combined and cached ${_cachedAllCategories!.length} total categories.");
      return Right(_cachedAllCategories!);
    } catch (e) {
      // Catch generic Exception as datasources might throw various things
      log.warning(
          "[CategoryRepo] Error during getAllCategories: ${e.toString()}");
      _invalidateCaches();
      return Left(
          CacheFailure("Failed to load all categories: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getSpecificCategories(
      {CategoryType? type, bool includeCustom = true}) async {
    final cacheKey = type ??
        CategoryType
            .expense; // Use a default key if type is null, though shouldn't happen often
    log.fine(
        "[CategoryRepo] getSpecificCategories called. Type: ${type?.name ?? 'All (if custom only)'}, IncludeCustom: $includeCustom");

    // Check cache if fetching a specific type WITH custom cats (common case)
    if (type != null &&
        includeCustom &&
        _cachedSpecificCategories.containsKey(cacheKey)) {
      log.fine(
          "[CategoryRepo] Returning cached specific categories for ${type.name} (${_cachedSpecificCategories[cacheKey]!.length}).");
      return Right(_cachedSpecificCategories[cacheKey]!);
    }

    try {
      List<CategoryModel> predefinedModels = [];
      List<CategoryModel> customModels = [];

      // Fetch predefined based on type
      if (type == CategoryType.expense) {
        predefinedModels =
            await expensePredefinedDataSource.getPredefinedCategories();
      } else if (type == CategoryType.income) {
        predefinedModels =
            await incomePredefinedDataSource.getPredefinedCategories();
      }
      // If type is null, we likely only want custom (or handle 'transfer' later)

      // Fetch custom if requested
      if (includeCustom) {
        customModels = await localDataSource.getCustomCategories();
        // Filter custom by type if needed
        if (type != null) {
          customModels =
              customModels.where((m) => m.typeIndex == type.index).toList();
        }
      }

      log.fine(
          "[CategoryRepo] Fetched ${predefinedModels.length} predefined, ${customModels.length} custom for type ${type?.name}.");

      // Combine and process
      final allModels = {...predefinedModels, ...customModels}.toList();
      final finalCategories = _processAndSort(allModels);

      // Cache if specific type + custom was requested
      if (type != null && includeCustom) {
        _cachedSpecificCategories[cacheKey] = finalCategories;
        log.fine("[CategoryRepo] Cached specific categories for ${type.name}.");
      }

      return Right(finalCategories);
    } catch (e) {
      log.warning(
          "[CategoryRepo] Error during getSpecificCategories (type: ${type?.name}): ${e.toString()}");
      _cachedSpecificCategories
          .remove(cacheKey); // Clear specific cache on error
      return Left(
          CacheFailure("Failed to load specific categories: ${e.toString()}"));
    }
  }

  // Implement old methods using the new one for compatibility if needed, or remove them
  // Future<Either<Failure, List<Category>>> getExpenseCategories() async {
  //    return getSpecificCategories(type: CategoryType.expense, includeCustom: true);
  // }
  // Future<Either<Failure, List<Category>>> getIncomeCategories() async {
  //    return getSpecificCategories(type: CategoryType.income, includeCustom: true);
  // }

  @override
  Future<Either<Failure, List<Category>>> getCustomCategories(
      {CategoryType? type}) async {
    log.fine(
        "[CategoryRepo] getCustomCategories called. Type filter: ${type?.name ?? 'None'}");
    // Use specific fetch method for custom only
    final result = await getSpecificCategories(type: type, includeCustom: true);
    return result.fold(
        (l) => Left(l),
        (r) => Right(r
            .where((cat) => cat.isCustom)
            .toList()) // Filter for custom client-side
        );
    // OR, potentially more efficient:
    // try {
    //   var customModels = await localDataSource.getCustomCategories();
    //   if (type != null) {
    //     customModels = customModels.where((m) => m.typeIndex == type.index).toList();
    //   }
    //   final customEntities = _processAndSort(customModels);
    //   return Right(customEntities);
    // } catch (e) { ... }
  }

  @override
  Future<Either<Failure, Category?>> getCategoryById(String categoryId) async {
    log.fine("[CategoryRepo] getCategoryById called for ID: $categoryId");
    final allCategoriesResult =
        await getAllCategories(); // Use cached if possible
    return allCategoriesResult.fold((failure) => Left(failure), (categories) {
      try {
        // Use firstWhereOrNull from collection package for safety
        final category = categories.firstWhere((cat) => cat.id == categoryId);
        log.fine("[CategoryRepo] Found category by ID: ${category.name}");
        return Right(category);
      } catch (e) {
        // firstWhere throws if not found
        log.warning("[CategoryRepo] Category with ID '$categoryId' not found.");
        return const Right(null); // Return Right(null) if not found
      }
    });
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
      _invalidateCaches(); // Invalidate relevant caches
      final model = CategoryModel.fromEntity(category);
      await localDataSource.saveCustomCategory(model);
      log.info(
          "[CategoryRepo] Custom category '${category.name}' added successfully.");
      return const Right(null);
    } catch (e) {
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
      _invalidateCaches();
      final model = CategoryModel.fromEntity(category);
      if (!category.isCustom) {
        log.warning(
            "[CategoryRepo] Updating predefined category personalization NOT YET IMPLEMENTED. Ignoring update.");
        // TODO: Implement saving personalization for predefined categories if needed
        return const Right(null);
      } else {
        await localDataSource.updateCustomCategory(model);
        log.info(
            "[CategoryRepo] Custom category '${category.name}' updated successfully.");
        return const Right(null);
      }
    } catch (e) {
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
    // Transaction reassignment is handled in the UseCase/Bloc level
    try {
      _invalidateCaches();
      await localDataSource.deleteCustomCategory(categoryId);
      log.info(
          "[CategoryRepo] Custom category (ID: $categoryId) deleted successfully from local source.");
      return const Right(null);
    } catch (e) {
      log.warning(
          "[CategoryRepo] Error during deleteCustomCategory: ${e.toString()}");
      return Left(CacheFailure("Failed to delete category: ${e.toString()}"));
    }
  }
}
