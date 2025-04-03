import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:hive/hive.dart'; // Needed by implementation
import 'package:expense_tracker/core/error/failure.dart'; // Needed by implementation
import 'package:expense_tracker/main.dart'; // Needed by implementation (logger)
// --- END MOVED IMPORTS ---

abstract class CategoryLocalDataSource {
  /// Fetches all custom categories stored locally.
  Future<List<CategoryModel>> getCustomCategories();

  /// Saves a new custom category locally.
  Future<void> saveCustomCategory(CategoryModel category);

  /// Updates an existing custom category locally.
  Future<void> updateCustomCategory(CategoryModel category);

  /// Deletes a custom category locally by its ID.
  Future<void> deleteCustomCategory(String id);

  /// Clears all custom categories (Optional, for data management).
  Future<void> clearAllCustomCategories();
}

class HiveCategoryLocalDataSource implements CategoryLocalDataSource {
  final Box<CategoryModel> categoryBox;

  HiveCategoryLocalDataSource(this.categoryBox);

  @override
  Future<void> deleteCustomCategory(String id) async {
    try {
      await categoryBox.delete(id);
      log.info("Deleted custom category (ID: $id) from Hive.");
    } catch (e, s) {
      log.severe("Failed to delete custom category (ID: $id) from cache$e$s");
      throw CacheFailure('Failed to delete category: ${e.toString()}');
    }
  }

  @override
  Future<List<CategoryModel>> getCustomCategories() async {
    try {
      final customCategories = categoryBox.values.toList();
      log.info(
          "Retrieved ${customCategories.length} custom categories from Hive.");
      return customCategories;
    } catch (e, s) {
      log.severe("Failed to get custom categories from cache$e$s");
      throw CacheFailure('Failed to get categories: ${e.toString()}');
    }
  }

  @override
  Future<void> saveCustomCategory(CategoryModel category) async {
    if (!category.isCustom) {
      log.warning(
          "Attempted to save a non-custom category via local source. ID: ${category.id}");
      return;
    }
    try {
      await categoryBox.put(category.id, category);
      log.info(
          "Saved custom category '${category.name}' (ID: ${category.id}) to Hive.");
    } catch (e, s) {
      log.severe(
          "Failed to save custom category '${category.name}' to cache$e$s");
      throw CacheFailure('Failed to save category: ${e.toString()}');
    }
  }

  @override
  Future<void> updateCustomCategory(CategoryModel category) async {
    if (!category.isCustom) {
      log.warning(
          "Attempted to update a non-custom category via local source. ID: ${category.id}");
      return;
    }
    if (!categoryBox.containsKey(category.id)) {
      log.warning(
          "Attempted to update non-existent custom category ID: ${category.id}");
      throw CacheFailure(
          "Category with ID ${category.id} not found for update.");
    }
    try {
      await categoryBox.put(category.id, category);
      log.info(
          "Updated custom category '${category.name}' (ID: ${category.id}) in Hive.");
    } catch (e, s) {
      log.severe(
          "Failed to update custom category '${category.name}' in cache$e$s");
      throw CacheFailure('Failed to update category: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAllCustomCategories() async {
    try {
      final count = await categoryBox.clear();
      log.info("Cleared custom categories box in Hive ($count items removed).");
    } catch (e, s) {
      log.severe("Failed to clear custom categories cache$e$s");
      throw CacheFailure('Failed to clear categories cache: ${e.toString()}');
    }
  }
}
