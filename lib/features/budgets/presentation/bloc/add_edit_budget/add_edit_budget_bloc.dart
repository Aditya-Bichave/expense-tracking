// lib/features/budgets/presentation/bloc/add_edit_budget/add_edit_budget_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/add_budget.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/update_budget.dart'; // ADDED
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart'; // Import enum
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart'; // For ValueGetter
import 'package:uuid/uuid.dart'; // For generating ID if needed

part 'add_edit_budget_event.dart';
part 'add_edit_budget_state.dart';

class AddEditBudgetBloc extends Bloc<AddEditBudgetEvent, AddEditBudgetState> {
  final AddBudgetUseCase _addBudgetUseCase;
  final UpdateBudgetUseCase _updateBudgetUseCase; // ADDED
  final CategoryRepository _categoryRepository;

  AddEditBudgetBloc({
    required AddBudgetUseCase addBudgetUseCase,
    required UpdateBudgetUseCase updateBudgetUseCase, // ADDED
    required CategoryRepository categoryRepository,
    Budget? initialBudget,
  }) : _addBudgetUseCase = addBudgetUseCase,
       _updateBudgetUseCase = updateBudgetUseCase, // ADDED
       _categoryRepository = categoryRepository,
       super(AddEditBudgetState(initialBudget: initialBudget)) {
    on<InitializeBudgetForm>(_onInitializeBudgetForm);
    on<SaveBudget>(_onSaveBudget);
    on<ClearBudgetFormMessage>(_onClearMessage);

    log.info(
      "[AddEditBudgetBloc] Initialized. Editing: ${initialBudget != null}",
    );
    // Load categories immediately
    add(InitializeBudgetForm(initialBudget: initialBudget));
  }

  Future<void> _onInitializeBudgetForm(
    InitializeBudgetForm event,
    Emitter<AddEditBudgetState> emit,
  ) async {
    // Load available expense categories for the dropdown/selector
    emit(
      state.copyWith(
        status: AddEditBudgetStatus.loading,
        initialBudgetOrNull: () => event.initialBudget,
      ),
    );
    final categoriesResult = await _categoryRepository.getSpecificCategories(
      type: CategoryType.expense,
      includeCustom: true,
    );

    categoriesResult.fold(
      (failure) => emit(
        state.copyWith(
          status: AddEditBudgetStatus.error,
          errorMessage:
              "Failed to load categories for selection: ${failure.message}",
        ),
      ),
      (categories) => emit(
        state.copyWith(
          status: AddEditBudgetStatus.initial, // Ready after loading categories
          initialBudgetOrNull: () =>
              event.initialBudget, // Reset initial budget in state
          availableCategories: categories,
        ),
      ),
    );
  }

  Future<void> _onSaveBudget(
    SaveBudget event,
    Emitter<AddEditBudgetState> emit,
  ) async {
    log.info("[AddEditBudgetBloc] SaveBudget received: ${event.name}");
    emit(state.copyWith(status: AddEditBudgetStatus.loading, clearError: true));

    final bool isEditing = state.isEditing;

    // Construct the Budget object
    final budgetData = Budget(
      id:
          state.initialBudget?.id ??
          sl<Uuid>().v4(), // Use existing ID or generate new
      name: event.name.trim(),
      type: event.type,
      targetAmount: event.targetAmount,
      period: event.period,
      startDate: event.period == BudgetPeriodType.oneTime
          ? event.startDate
          : null,
      endDate: event.period == BudgetPeriodType.oneTime ? event.endDate : null,
      categoryIds: event.type == BudgetType.categorySpecific
          ? event.categoryIds
          : null,
      notes: event.notes?.trim(),
      createdAt:
          state.initialBudget?.createdAt ??
          DateTime.now(), // Preserve original createdAt
    );

    // Call appropriate use case
    final result = isEditing
        ? await _updateBudgetUseCase(
            UpdateBudgetParams(budget: budgetData),
          ) // Use Update use case
        : await _addBudgetUseCase(
            AddBudgetParams(
              // Add params remain the same
              name: budgetData.name,
              type: budgetData.type,
              targetAmount: budgetData.targetAmount,
              period: budgetData.period,
              startDate: budgetData.startDate,
              endDate: budgetData.endDate,
              categoryIds: budgetData.categoryIds,
              notes: budgetData.notes,
            ),
          );

    result.fold(
      (failure) {
        log.warning("[AddEditBudgetBloc] Save failed: ${failure.message}");
        emit(
          state.copyWith(
            status: AddEditBudgetStatus.error,
            errorMessage: _mapFailureToMessage(failure),
          ),
        );
        // Keep loading state on error? Or revert to initial? Reverting is safer.
        emit(state.copyWith(status: AddEditBudgetStatus.initial));
      },
      (savedBudget) {
        log.info(
          "[AddEditBudgetBloc] Save successful for '${savedBudget.name}'.",
        );
        emit(state.copyWith(status: AddEditBudgetStatus.success));
        publishDataChangedEvent(
          type: DataChangeType.budget,
          reason: isEditing ? DataChangeReason.updated : DataChangeReason.added,
        );
      },
    );
  }

  void _onClearMessage(
    ClearBudgetFormMessage event,
    Emitter<AddEditBudgetState> emit,
  ) {
    // Reset status to initial when clearing message
    if (state.status == AddEditBudgetStatus.error ||
        state.status == AddEditBudgetStatus.success) {
      emit(
        state.copyWith(status: AddEditBudgetStatus.initial, clearError: true),
      );
    } else {
      // If still loading or initial, just clear error
      emit(state.copyWith(clearError: true));
    }
  }

  String _mapFailureToMessage(Failure failure) {
    log.warning(
      "[AddEditBudgetBloc] Mapping failure: ${failure.runtimeType} - ${failure.message}",
    );
    switch (failure.runtimeType) {
      case ValidationFailure:
        return failure.message;
      case CacheFailure:
        return 'Database Error: ${failure.message}';
      default:
        return 'An unexpected error occurred saving the budget.';
    }
  }
}
