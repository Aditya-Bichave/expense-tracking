import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart'; // Import type enum
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/main.dart'; // logger
import 'package:uuid/uuid.dart'; // For generating ID

class AddCustomCategoryUseCase
    implements UseCase<void, AddCustomCategoryParams> {
  final CategoryRepository repository;
  final Uuid uuid; // Inject Uuid

  AddCustomCategoryUseCase(this.repository, this.uuid);

  @override
  Future<Either<Failure, void>> call(AddCustomCategoryParams params) async {
    log.info(
        "[AddCustomCategoryUseCase] Executing for name: '${params.name}', Type: ${params.type.name}.");

    // --- Validation ---
    if (params.name.trim().isEmpty) {
      log.warning(
          "[AddCustomCategoryUseCase] Validation failed: Name cannot be empty.");
      return const Left(ValidationFailure("Category name cannot be empty."));
    }
    if (params.iconName.trim().isEmpty) {
      log.warning(
          "[AddCustomCategoryUseCase] Validation failed: Icon name cannot be empty.");
      return const Left(ValidationFailure("An icon must be selected."));
    }
    if (params.colorHex.trim().isEmpty || !params.colorHex.startsWith('#')) {
      log.warning(
          "[AddCustomCategoryUseCase] Validation failed: Invalid color hex format.");
      return const Left(ValidationFailure("A valid color must be selected."));
    }
    // --- Unique Name Check ---
    final allCategoriesResult = await repository.getAllCategories();
    if (allCategoriesResult.isLeft()) {
      log.severe(
          "[AddCustom-CategoryUseCase] Failed to get categories for validation.");
      return Left(allCategoriesResult.fold((l) => l, (r) => ServerFailure()));
    }
    final allCategories = allCategoriesResult.getOrElse(() => []);
    final trimmedName = params.name.trim();

    final isDuplicate = allCategories.any((cat) =>
        cat.name.trim().toLowerCase() == trimmedName.toLowerCase() &&
        cat.type == params.type &&
        cat.parentCategoryId == params.parentCategoryId);

    if (isDuplicate) {
      log.warning(
          "[AddCustomCategoryUseCase] Validation failed: A category with the name '$trimmedName' already exists for this type/parent.");
      return const Left(ValidationFailure(
          "A category with this name already exists in the selected category group."));
    }

    // --- Create Category Entity ---
    final newCategory = Category(
      id: uuid.v4(), // Generate unique ID
      name: params.name.trim(),
      iconName: params.iconName,
      colorHex: params.colorHex,
      type: params.type, // Use type from params
      isCustom: true, // Explicitly set as custom
      parentCategoryId: params.parentCategoryId,
    );

    log.info(
        "[AddCustomCategoryUseCase] Calling repository to add category ID: ${newCategory.id}");
    // Pass the fully constructed Category entity to the repository
    return await repository.addCustomCategory(newCategory);
  }
}

// --- Update Params Class ---
class AddCustomCategoryParams extends Equatable {
  final String name;
  final String iconName;
  final String colorHex;
  final CategoryType type; // ADDED: Required type
  final String? parentCategoryId;

  const AddCustomCategoryParams({
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.type, // ADDED
    this.parentCategoryId,
  });

  @override
  List<Object?> get props =>
      [name, iconName, colorHex, type, parentCategoryId]; // ADDED type
}
