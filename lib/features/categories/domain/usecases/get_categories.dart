// lib/features/categories/domain/usecases/get_categories.dart
// CORRECTED FILE

import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/main.dart'; // logger

class GetCategoriesUseCase implements UseCase<List<Category>, NoParams> {
  final CategoryRepository repository;

  GetCategoriesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(NoParams params) async {
    log.info("[GetCategoriesUseCase] Executing.");
    // FIX: Call the correct repository method 'getAllCategories'
    final result = await repository.getAllCategories();
    result.fold(
      (failure) =>
          log.warning("[GetCategoriesUseCase] Failed: ${failure.message}"),
      (categories) => log.info(
          "[GetCategoriesUseCase] Succeeded with ${categories.length} categories."),
    );
    return result;
  }
}
