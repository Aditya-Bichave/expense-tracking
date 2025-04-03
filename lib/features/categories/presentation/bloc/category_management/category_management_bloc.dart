import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
// Import necessary Use Cases (assuming they exist now)
import 'package:expense_tracker/features/categories/domain/usecases/get_categories.dart';
import 'package:expense_tracker/features/categories/domain/usecases/add_custom_category.dart';
import 'package:expense_tracker/features/categories/domain/usecases/update_custom_category.dart';
import 'package:expense_tracker/features/categories/domain/usecases/delete_custom_category.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // For publishing events
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/main.dart'; // logger

part 'category_management_event.dart';
part 'category_management_state.dart';

class CategoryManagementBloc
    extends Bloc<CategoryManagementEvent, CategoryManagementState> {
  // Inject use cases
  final GetCategoriesUseCase _getCategoriesUseCase;
  final AddCustomCategoryUseCase _addCustomCategoryUseCase;
  final UpdateCustomCategoryUseCase _updateCustomCategoryUseCase;
  final DeleteCustomCategoryUseCase _deleteCustomCategoryUseCase;

  CategoryManagementBloc({
    required GetCategoriesUseCase getCategoriesUseCase,
    required AddCustomCategoryUseCase addCustomCategoryUseCase,
    required UpdateCustomCategoryUseCase updateCustomCategoryUseCase,
    required DeleteCustomCategoryUseCase deleteCustomCategoryUseCase,
  })  : _getCategoriesUseCase = getCategoriesUseCase,
        _addCustomCategoryUseCase = addCustomCategoryUseCase,
        _updateCustomCategoryUseCase = updateCustomCategoryUseCase,
        _deleteCustomCategoryUseCase = deleteCustomCategoryUseCase,
        super(const CategoryManagementState()) {
    on<LoadCategories>(_onLoadCategories);
    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);

    log.info("[CategoryManagementBloc] Initialized.");
  }

  Future<void> _onLoadCategories(
      LoadCategories event, Emitter<CategoryManagementState> emit) async {
    log.info("[CategoryManagementBloc] Received LoadCategories event.");
    if (state.status == CategoryManagementStatus.loaded && !event.forceReload) {
      log.info("[CategoryManagementBloc] Already loaded, skipping.");
      return;
    }
    emit(state.copyWith(
        status: CategoryManagementStatus.loading, clearError: true));

    final result = await _getCategoriesUseCase(const NoParams());

    result.fold(
      (failure) {
        log.warning("[CategoryManagementBloc] Load failed: ${failure.message}");
        emit(state.copyWith(
            status: CategoryManagementStatus.error,
            errorMessage: _mapFailureToMessage(failure)));
      },
      (categories) {
        final custom = categories.where((c) => c.isCustom).toList();
        final predefined = categories.where((c) => !c.isCustom).toList();
        log.info(
            "[CategoryManagementBloc] Load successful. Custom: ${custom.length}, Predefined: ${predefined.length}");
        emit(state.copyWith(
          status: CategoryManagementStatus.loaded,
          customCategories: custom,
          predefinedCategories: predefined,
        ));
      },
    );
  }

  Future<void> _onAddCategory(
      AddCategory event, Emitter<CategoryManagementState> emit) async {
    log.info(
        "[CategoryManagementBloc] Received AddCategory event: ${event.name}");
    // Optionally show intermediate loading state?
    // emit(state.copyWith(status: CategoryManagementStatus.loading)); // Reconsider if needed

    final params = AddCustomCategoryParams(
        name: event.name,
        iconName: event.iconName,
        colorHex: event.colorHex,
        parentCategoryId: event.parentId);
    final result = await _addCustomCategoryUseCase(params);

    result.fold((failure) {
      log.warning(
          "[CategoryManagementBloc] AddCategory failed: ${failure.message}");
      emit(state.copyWith(
          status: CategoryManagementStatus
              .error, // Or revert to loaded with error message?
          errorMessage: _mapFailureToMessage(failure)));
      // Re-emit previous loaded state if needed after showing error
      // Future.delayed(Duration(milliseconds: 100), () => add(const LoadCategories(forceReload: true))); // Or emit current custom/predefined lists
    }, (_) {
      log.info(
          "[CategoryManagementBloc] AddCategory successful. Reloading categories and publishing event.");
      // Trigger a reload to get the updated list including the new one
      add(const LoadCategories(forceReload: true));
      publishDataChangedEvent(
          type: DataChangeType.category, reason: DataChangeReason.added);
    });
  }

  Future<void> _onUpdateCategory(
      UpdateCategory event, Emitter<CategoryManagementState> emit) async {
    log.info(
        "[CategoryManagementBloc] Received UpdateCategory event: ${event.category.name} (ID: ${event.category.id})");
    // Optionally show intermediate loading state?

    final params = UpdateCustomCategoryParams(category: event.category);
    final result = await _updateCustomCategoryUseCase(params);

    result.fold((failure) {
      log.warning(
          "[CategoryManagementBloc] UpdateCategory failed: ${failure.message}");
      emit(state.copyWith(
          status: CategoryManagementStatus.error,
          errorMessage: _mapFailureToMessage(failure)));
    }, (_) {
      log.info(
          "[CategoryManagementBloc] UpdateCategory successful. Reloading categories and publishing event.");
      add(const LoadCategories(forceReload: true));
      publishDataChangedEvent(
          type: DataChangeType.category, reason: DataChangeReason.updated);
    });
  }

  Future<void> _onDeleteCategory(
      DeleteCategory event, Emitter<CategoryManagementState> emit) async {
    log.info(
        "[CategoryManagementBloc] Received DeleteCategory event: ${event.categoryId}");
    // Optionally show intermediate loading state?

    // --- IMPORTANT: Determine fallback category ID ---
    // Use the static 'uncategorized' ID or fetch it. Using static for now.
    final fallbackId = Category.uncategorized.id;
    // ---------------------------------------------

    final params = DeleteCustomCategoryParams(
        categoryId: event.categoryId, fallbackCategoryId: fallbackId);
    final result = await _deleteCustomCategoryUseCase(params);

    result.fold((failure) {
      log.warning(
          "[CategoryManagementBloc] DeleteCategory failed: ${failure.message}");
      emit(state.copyWith(
          status: CategoryManagementStatus.error,
          errorMessage: _mapFailureToMessage(failure)));
    }, (_) {
      log.info(
          "[CategoryManagementBloc] DeleteCategory successful. Reloading categories and publishing event.");
      add(const LoadCategories(forceReload: true));
      // Publish *both* category delete and potential transaction updates
      publishDataChangedEvent(
          type: DataChangeType.category, reason: DataChangeReason.deleted);
      publishDataChangedEvent(
          type: DataChangeType.expense,
          reason: DataChangeReason.updated); // Because expenses were reassigned
      publishDataChangedEvent(
          type: DataChangeType.income,
          reason: DataChangeReason.updated); // Because income was reassigned
    });
  }

  String _mapFailureToMessage(Failure failure) {
    log.warning(
        "[CategoryManagementBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}");
    switch (failure.runtimeType) {
      case ValidationFailure:
        return failure.message;
      case CacheFailure:
        return 'Database Error: ${failure.message}';
      default:
        return 'An unexpected error occurred managing categories.';
    }
  }
}
