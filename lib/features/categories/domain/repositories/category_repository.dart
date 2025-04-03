import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';

abstract class CategoryRepository {
  /// Fetches ALL categories (predefined expense, predefined income, custom).
  Future<Either<Failure, List<Category>>> getAllCategories();

  /// Fetches predefined EXPENSE categories AND custom categories.
  Future<Either<Failure, List<Category>>> getExpenseCategories();

  /// Fetches predefined INCOME categories AND custom categories.
  Future<Either<Failure, List<Category>>> getIncomeCategories();

  /// Fetches only custom categories.
  Future<Either<Failure, List<Category>>> getCustomCategories();

  /// Fetches a single category by its ID (searches all types).
  Future<Either<Failure, Category?>> getCategoryById(String categoryId);

  /// Adds a new custom category.
  Future<Either<Failure, void>> addCustomCategory(Category category);

  /// Updates an existing custom category.
  /// (Updating predefined personalization might need separate handling)
  Future<Either<Failure, void>> updateCategory(Category category);

  /// Deletes a custom category.
  Future<Either<Failure, void>> deleteCustomCategory(
      String categoryId, String fallbackCategoryId);
}
