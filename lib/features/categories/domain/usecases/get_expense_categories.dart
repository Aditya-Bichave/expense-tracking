import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart'; // Import type
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/main.dart';

class GetExpenseCategoriesUseCase implements UseCase<List<Category>, NoParams> {
  final CategoryRepository repository;
  GetExpenseCategoriesUseCase(this.repository);

  // Helper to determine if a category is for expenses (can be complex later)
  bool isExpenseCategory(Category category) =>
      category.type == CategoryType.expense;

  @override
  Future<Either<Failure, List<Category>>> call(NoParams params) async {
    log.info("[GetExpenseCategoriesUseCase] Executing.");
    // Use the specific repository method
    return await repository.getSpecificCategories(
      type: CategoryType.expense,
      includeCustom: true,
    );
  }
}
