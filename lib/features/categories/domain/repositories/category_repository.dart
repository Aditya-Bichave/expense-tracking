import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart'; // Import type

abstract class CategoryRepository {
  // Keep getAllCategories as is (useful for some scenarios)
  Future<Either<Failure, List<Category>>> getAllCategories();

  // Refactor expense/income getters to be more specific or use a single typed getter
  Future<Either<Failure, List<Category>>> getSpecificCategories(
      {CategoryType? type, bool includeCustom = true});
  // OR keep separate methods if preferred, but implement them using the typed fetch
  // Future<Either<Failure, List<Category>>> getExpenseCategories();
  // Future<Either<Failure, List<Category>>> getIncomeCategories();

  Future<Either<Failure, List<Category>>> getCustomCategories(
      {CategoryType? type}); // Allow filtering custom by type

  Future<Either<Failure, Category?>> getCategoryById(String categoryId);
  Future<Either<Failure, void>> addCustomCategory(
      Category category); // Category now includes type
  Future<Either<Failure, void>> updateCategory(
      Category category); // Category now includes type
  Future<Either<Failure, void>> deleteCustomCategory(
      String categoryId, String fallbackCategoryId);
}
