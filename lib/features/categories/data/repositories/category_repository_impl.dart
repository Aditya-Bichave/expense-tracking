import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_local_data_source.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_predefined_data_source.dart'; // Keep abstract import
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/main.dart'; // logger
import 'package:expense_tracker/core/di/service_locator.dart'; // Import sl

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource localDataSource;
  // Inject specific predefined sources via DI (using named instances)
  final CategoryPredefinedDataSource expensePredefinedDataSource;
  final CategoryPredefinedDataSource incomePredefinedDataSource;

  // Cache for combined lists to avoid redundant fetching
  List<Category>? _cachedAllCategories;
  List<Category>? _cachedExpenseCategories;
  List<Category>? _cachedIncomeCategories;

  CategoryRepositoryImpl({
    required this.localDataSource,
    required this.expensePredefinedDataSource, // Inject specific instance
    required this.incomePredefinedDataSource, // Inject specific instance
  });

  // Helper to clear all caches
  void _invalidateCaches() {
    _cachedAllCategories = null;
    _cachedExpenseCategories = null;
    _cachedIncomeCategories = null;
  }

  // Helper to convert models and sort
  List<Category> _processAndSort(List<CategoryModel> models) {
    final entities = models.map((model) => model.toEntity()).toList();
    entities
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return entities;
  }

  @override
  Future<Either<Failure, List<Category>>> getAllCategories() async {
    log.info("[CategoryRepo] getAllCategories called.");
    if (_cachedAllCategories != null) {
      log.info(
          "[CategoryRepo] Returning cached ALL categories (${_cachedAllCategories!.length}).");
      return Right(_cachedAllCategories!);
    }
    try {
      log.info(
          "[CategoryRepo] Fetching all predefined (expense/income) and custom categories...");
      final results = await Future.wait([
        expensePredefinedDataSource.getPredefinedCategories(),
        incomePredefinedDataSource.getPredefinedCategories(),
        localDataSource.getCustomCategories(),
      ]);
      final predefinedExpense = results[0];
      final predefinedIncome = results[1];
      final custom = results[2];
      log.info(
          "[CategoryRepo] Fetched ${predefinedExpense.length} exp, ${predefinedIncome.length} inc, ${custom.length} custom.");

      // Combine, ensuring no duplicates from predefined lists if any overlap (unlikely with separate files)
      final allModels = {...predefinedExpense, ...predefinedIncome, ...custom}
          .toList(); // Use set first to remove duplicates by chance
      _cachedAllCategories = _processAndSort(allModels);
      log.info(
          "[CategoryRepo] Combined and cached ${_cachedAllCategories!.length} total categories.");
      return Right(_cachedAllCategories!);
    } on CacheFailure catch (e) {
      log.warning(
          "[CategoryRepo] CacheFailure during getAllCategories: ${e.message}");
      _invalidateCaches();
      return Left(e);
    } catch (e, s) {
      log.severe("[CategoryRepo] Unexpected error in getAllCategories$e$s");
      _invalidateCaches();
      return Left(
          CacheFailure("Failed to load all categories: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getExpenseCategories() async {
    log.info("[CategoryRepo] getExpenseCategories called.");
    if (_cachedExpenseCategories != null) {
      log.info(
          "[CategoryRepo] Returning cached EXPENSE categories (${_cachedExpenseCategories!.length}).");
      return Right(_cachedExpenseCategories!);
    }
    try {
      log.info(
          "[CategoryRepo] Fetching predefined expense and custom categories...");
      final results = await Future.wait([
        expensePredefinedDataSource.getPredefinedCategories(),
        localDataSource.getCustomCategories(),
      ]);
      final allModels = [...results[0], ...results[1]];
      _cachedExpenseCategories = _processAndSort(allModels);
      log.info(
          "[CategoryRepo] Combined and cached ${_cachedExpenseCategories!.length} expense-relevant categories.");
      return Right(_cachedExpenseCategories!);
    } on CacheFailure catch (e) {
      log.warning(
          "[CategoryRepo] CacheFailure during getExpenseCategories: ${e.message}");
      _cachedExpenseCategories = null;
      return Left(e);
    } catch (e, s) {
      log.severe("[CategoryRepo] Unexpected error in getExpenseCategories$e$s");
      _cachedExpenseCategories = null;
      return Left(
          CacheFailure("Failed to load expense categories: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getIncomeCategories() async {
    log.info("[CategoryRepo] getIncomeCategories called.");
    if (_cachedIncomeCategories != null) {
      log.info(
          "[CategoryRepo] Returning cached INCOME categories (${_cachedIncomeCategories!.length}).");
      return Right(_cachedIncomeCategories!);
    }
    try {
      log.info(
          "[CategoryRepo] Fetching predefined income and custom categories...");
      final results = await Future.wait([
        incomePredefinedDataSource.getPredefinedCategories(),
        localDataSource.getCustomCategories(),
      ]);
      final allModels = [...results[0], ...results[1]];
      _cachedIncomeCategories = _processAndSort(allModels);
      log.info(
          "[CategoryRepo] Combined and cached ${_cachedIncomeCategories!.length} income-relevant categories.");
      return Right(_cachedIncomeCategories!);
    } on CacheFailure catch (e) {
      log.warning(
          "[CategoryRepo] CacheFailure during getIncomeCategories: ${e.message}");
      _cachedIncomeCategories = null;
      return Left(e);
    } catch (e, s) {
      log.severe("[CategoryRepo] Unexpected error in getIncomeCategories$e$s");
      _cachedIncomeCategories = null;
      return Left(
          CacheFailure("Failed to load income categories: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getCustomCategories() async {
    log.info("[CategoryRepo] getCustomCategories called.");
    try {
      final customModels = await localDataSource.getCustomCategories();
      final customEntities = _processAndSort(customModels); // Use helper
      log.info(
          "[CategoryRepo] Fetched ${customEntities.length} custom categories.");
      return Right(customEntities);
    } on CacheFailure catch (e) {
      log.warning(
          "[CategoryRepo] CacheFailure during getCustomCategories: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe("[CategoryRepo] Unexpected error in getCustomCategories$e$s");
      return Left(
          CacheFailure("Failed to load custom categories: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, Category?>> getCategoryById(String categoryId) async {
    log.fine("[CategoryRepo] getCategoryById called for ID: $categoryId");
    // Use getAllCategories which leverages cache
    final allCategoriesResult = await getAllCategories();
    return allCategoriesResult.fold((failure) => Left(failure), (categories) {
      try {
        final category = categories.firstWhere((cat) => cat.id == categoryId);
        log.fine("[CategoryRepo] Found category by ID: ${category.name}");
        return Right(category);
      } catch (e) {
        log.warning("[CategoryRepo] Category with ID '$categoryId' not found.");
        return const Right(null);
      }
    });
  }

  @override
  Future<Either<Failure, void>> addCustomCategory(Category category) async {
    log.info("[CategoryRepo] addCustomCategory called for '${category.name}'.");
    if (!category.isCustom) {
      log.warning("[CategoryRepo] Attempted to add a non-custom category.");
      return const Left(
          ValidationFailure("Only custom categories can be added."));
    }
    try {
      _invalidateCaches(); // Invalidate all caches
      final model = CategoryModel.fromEntity(category);
      await localDataSource.saveCustomCategory(model);
      log.info(
          "[CategoryRepo] Custom category '${category.name}' added successfully.");
      return const Right(null);
    } on CacheFailure catch (e) {
      log.warning(
          "[CategoryRepo] CacheFailure during addCustomCategory: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe("[CategoryRepo] Unexpected error in addCustomCategory$e$s");
      return Left(CacheFailure("Failed to add category: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, void>> updateCategory(Category category) async {
    log.info(
        "[CategoryRepo] updateCategory called for '${category.name}' (ID: ${category.id}). Custom: ${category.isCustom}");
    try {
      _invalidateCaches(); // Invalidate all caches
      final model = CategoryModel.fromEntity(category);
      if (!category.isCustom) {
        log.info(
            "[CategoryRepo] Updating predefined category personalization NOT YET IMPLEMENTED. Ignoring.");
        return const Right(null);
      } else {
        await localDataSource.updateCustomCategory(model);
        log.info(
            "[CategoryRepo] Custom category '${category.name}' updated successfully.");
        return const Right(null);
      }
    } on CacheFailure catch (e) {
      log.warning(
          "[CategoryRepo] CacheFailure during updateCategory: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe("[CategoryRepo] Unexpected error in updateCategory$e$s");
      return Left(CacheFailure("Failed to update category: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomCategory(
      String categoryId, String fallbackCategoryId) async {
    log.info(
        "[CategoryRepo] deleteCustomCategory called for ID: $categoryId. Fallback: $fallbackCategoryId");
    // Transaction reassignment happens in UseCase/Bloc
    try {
      _invalidateCaches(); // Invalidate all caches
      await localDataSource.deleteCustomCategory(categoryId);
      log.info(
          "[CategoryRepo] Custom category (ID: $categoryId) deleted successfully from local source.");
      return const Right(null);
    } on CacheFailure catch (e) {
      log.warning(
          "[CategoryRepo] CacheFailure during deleteCustomCategory: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe("[CategoryRepo] Unexpected error in deleteCustomCategory$e$s");
      return Left(CacheFailure("Failed to delete category: ${e.toString()}"));
    }
  }
}
