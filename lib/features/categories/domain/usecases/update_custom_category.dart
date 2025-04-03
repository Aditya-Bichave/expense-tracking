import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/main.dart'; // logger

class UpdateCustomCategoryUseCase
    implements UseCase<void, UpdateCustomCategoryParams> {
  final CategoryRepository repository;

  UpdateCustomCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateCustomCategoryParams params) async {
    final category = params.category;
    log.info(
        "[UpdateCustomCategoryUseCase] Executing for category ID: ${category.id}, Name: '${category.name}'.");

    // Validation (similar to Add, but allow existing name if ID matches)
    if (category.name.trim().isEmpty) {
      log.warning(
          "[UpdateCustomCategoryUseCase] Validation failed: Name cannot be empty.");
      return const Left(ValidationFailure("Category name cannot be empty."));
    }
    if (category.iconName.trim().isEmpty) {
      log.warning(
          "[UpdateCustomCategoryUseCase] Validation failed: Icon name cannot be empty.");
      return const Left(ValidationFailure("An icon must be selected."));
    }
    if (category.colorHex.trim().isEmpty ||
        !category.colorHex.startsWith('#')) {
      log.warning(
          "[UpdateCustomCategoryUseCase] Validation failed: Invalid color hex format.");
      return const Left(ValidationFailure("A valid color must be selected."));
    }

    // TODO: Add check for unique category name (excluding itself)

    // The repository handles distinguishing between updating custom vs predefined personalization
    log.info(
        "[UpdateCustomCategoryUseCase] Calling repository to update category ID: ${category.id}");
    return await repository.updateCategory(category);
  }
}

class UpdateCustomCategoryParams extends Equatable {
  final Category category; // Pass the full updated category object

  const UpdateCustomCategoryParams({required this.category});

  @override
  List<Object?> get props => [category];
}
