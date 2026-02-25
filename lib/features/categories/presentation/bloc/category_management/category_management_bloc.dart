// lib/features/categories/presentation/bloc/category_management/category_management_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart'; // Import type
// Import necessary Use Cases
import 'package:expense_tracker/features/categories/domain/usecases/get_categories.dart';
import 'package:expense_tracker/features/categories/domain/usecases/add_custom_category.dart';
import 'package:expense_tracker/features/categories/domain/usecases/update_custom_category.dart';
import 'package:expense_tracker/features/categories/domain/usecases/delete_custom_category.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/main.dart'; // logger

part 'category_management_event.dart';
part 'category_management_state.dart';

class CategoryManagementBloc
    extends Bloc<CategoryManagementEvent, CategoryManagementState> {
  final GetCategoriesUseCase _getCategoriesUseCase;
  final AddCustomCategoryUseCase _addCustomCategoryUseCase;
  final UpdateCustomCategoryUseCase _updateCustomCategoryUseCase;
  final DeleteCustomCategoryUseCase _deleteCustomCategoryUseCase;

  CategoryManagementBloc({
    required GetCategoriesUseCase getCategoriesUseCase,
    required AddCustomCategoryUseCase addCustomCategoryUseCase,
    required UpdateCustomCategoryUseCase updateCustomCategoryUseCase,
    required DeleteCustomCategoryUseCase deleteCustomCategoryUseCase,
  }) : _getCategoriesUseCase = getCategoriesUseCase,
       _addCustomCategoryUseCase = addCustomCategoryUseCase,
       _updateCustomCategoryUseCase = updateCustomCategoryUseCase,
       _deleteCustomCategoryUseCase = deleteCustomCategoryUseCase,
       super(const CategoryManagementState()) {
    on<LoadCategories>(_onLoadCategories);
    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
    on<ClearCategoryMessages>(_onClearCategoryMessages);

    log.info("[CategoryManagementBloc] Initialized.");
  }

  // --- Event Handlers ---

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoryManagementState> emit,
  ) async {
    log.info(
      "[CategoryManagementBloc] Received LoadCategories event. ForceReload: ${event.forceReload}",
    );
    if (state.status == CategoryManagementStatus.loaded && !event.forceReload) {
      log.info(
        "[CategoryManagementBloc] Categories already loaded and not forced, skipping reload.",
      );
      return;
    }
    emit(
      state.copyWith(
        status: CategoryManagementStatus.loading,
        clearError: true,
      ),
    );

    final result = await _getCategoriesUseCase(const NoParams());

    result.fold(
      (failure) {
        log.warning("[CategoryManagementBloc] Load failed: ${failure.message}");
        emit(
          state.copyWith(
            status: CategoryManagementStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ),
        );
      },
      (allCategories) {
        final customExpense = allCategories
            .where((c) => c.isCustom && c.type == CategoryType.expense)
            .toList();
        final customIncome = allCategories
            .where((c) => c.isCustom && c.type == CategoryType.income)
            .toList();
        final predefinedExpense = allCategories
            .where((c) => !c.isCustom && c.type == CategoryType.expense)
            .toList();
        final predefinedIncome = allCategories
            .where((c) => !c.isCustom && c.type == CategoryType.income)
            .toList();

        customExpense.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        customIncome.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        predefinedExpense.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        predefinedIncome.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

        log.info(
          "[CategoryManagementBloc] Load successful. CustomExp: ${customExpense.length}, CustomInc: ${customIncome.length}, PredefExp: ${predefinedExpense.length}, PredefInc: ${predefinedIncome.length}",
        );
        emit(
          state.copyWith(
            status: CategoryManagementStatus.loaded,
            customExpenseCategories: customExpense,
            customIncomeCategories: customIncome,
            predefinedExpenseCategories: predefinedExpense,
            predefinedIncomeCategories: predefinedIncome,
            clearError: true,
          ),
        );
      },
    );
  }

  Future<void> _onAddCategory(
    AddCategory event,
    Emitter<CategoryManagementState> emit,
  ) async {
    log.info(
      "[CategoryManagementBloc] Received AddCategory event: ${event.name}, Type: ${event.type.name}",
    );
    emit(
      state.copyWith(
        status: CategoryManagementStatus.loading,
        clearError: true,
      ),
    );

    final params = AddCustomCategoryParams(
      name: event.name,
      iconName: event.iconName,
      colorHex: event.colorHex,
      type: event.type,
      parentCategoryId: event.parentId,
    );

    final result = await _addCustomCategoryUseCase(params);

    result.fold(
      (failure) {
        log.warning(
          "[CategoryManagementBloc] AddCategory failed: ${failure.message}",
        );
        emit(
          state.copyWith(
            status: CategoryManagementStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ),
        );
        // Revert status back to loaded after showing error
        emit(
          state.copyWith(
            status: CategoryManagementStatus.loaded,
            clearError: true,
          ),
        ); // Keep lists as they are
      },
      (_) {
        log.info(
          "[CategoryManagementBloc] AddCategory successful. Reloading categories and publishing event.",
        );
        add(const LoadCategories(forceReload: true)); // Reload list
        publishDataChangedEvent(
          type: DataChangeType.category,
          reason: DataChangeReason.added,
        );
      },
    );
  }

  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<CategoryManagementState> emit,
  ) async {
    log.info(
      "[CategoryManagementBloc] Received UpdateCategory event: ${event.category.name} (ID: ${event.category.id})",
    );
    emit(
      state.copyWith(
        status: CategoryManagementStatus.loading,
        clearError: true,
      ),
    );

    final params = UpdateCustomCategoryParams(category: event.category);
    final result = await _updateCustomCategoryUseCase(params);

    result.fold(
      (failure) {
        log.warning(
          "[CategoryManagementBloc] UpdateCategory failed: ${failure.message}",
        );
        emit(
          state.copyWith(
            status: CategoryManagementStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ),
        );
        emit(
          state.copyWith(
            status: CategoryManagementStatus.loaded,
            clearError: true,
          ),
        ); // Keep lists
      },
      (_) {
        log.info(
          "[CategoryManagementBloc] UpdateCategory successful. Reloading categories and publishing event.",
        );
        add(const LoadCategories(forceReload: true));
        publishDataChangedEvent(
          type: DataChangeType.category,
          reason: DataChangeReason.updated,
        );
      },
    );
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<CategoryManagementState> emit,
  ) async {
    log.info(
      "[CategoryManagementBloc] Received DeleteCategory event: ${event.categoryId}",
    );
    emit(
      state.copyWith(
        status: CategoryManagementStatus.loading,
        clearError: true,
      ),
    );

    final fallbackId = Category.uncategorized.id;

    final params = DeleteCustomCategoryParams(
      categoryId: event.categoryId,
      fallbackCategoryId: fallbackId,
    );
    final result = await _deleteCustomCategoryUseCase(params);

    result.fold(
      (failure) {
        log.warning(
          "[CategoryManagementBloc] DeleteCategory failed: ${failure.message}",
        );
        emit(
          state.copyWith(
            status: CategoryManagementStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ),
        );
        emit(
          state.copyWith(
            status: CategoryManagementStatus.loaded,
            clearError: true,
          ),
        ); // Keep lists
      },
      (_) {
        log.info(
          "[CategoryManagementBloc] DeleteCategory successful. Reloading categories and publishing events.",
        );
        add(const LoadCategories(forceReload: true));
        publishDataChangedEvent(
          type: DataChangeType.category,
          reason: DataChangeReason.deleted,
        );
        // Trigger updates for transactions too, as they might have been reassigned
        publishDataChangedEvent(
          type: DataChangeType.expense,
          reason: DataChangeReason.updated,
        );
        publishDataChangedEvent(
          type: DataChangeType.income,
          reason: DataChangeReason.updated,
        );
      },
    );
  }

  void _onClearCategoryMessages(
    ClearCategoryMessages event,
    Emitter<CategoryManagementState> emit,
  ) {
    emit(state.copyWith(clearError: true)); // Clears errorMessage
  }

  String _mapFailureToMessage(Failure failure) {
    log.warning(
      "[CategoryManagementBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}",
    );
    switch (failure.runtimeType) {
      case ValidationFailure _:
        return failure.message;
      case CacheFailure _:
        return 'Database Error: ${failure.message}';
      default:
        return 'An unexpected error occurred managing categories.';
    }
  }
}
