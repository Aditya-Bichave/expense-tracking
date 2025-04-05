import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart'; // Import type
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/main.dart';

class GetIncomeCategoriesUseCase implements UseCase<List<Category>, NoParams> {
  final CategoryRepository repository;
  GetIncomeCategoriesUseCase(this.repository);

  // Helper to determine if a category is for income (can be complex later)
  bool isIncomeCategory(Category category) =>
      category.type == CategoryType.income;

  @override
  Future<Either<Failure, List<Category>>> call(NoParams params) async {
    log.info("[GetIncomeCategoriesUseCase] Executing.");
    // Use the specific repository method
    return await repository.getSpecificCategories(
        type: CategoryType.income, includeCustom: true);
  }
}
