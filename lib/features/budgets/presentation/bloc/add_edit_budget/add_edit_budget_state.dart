// lib/features/budgets/presentation/bloc/add_edit_budget/add_edit_budget_state.dart
part of 'add_edit_budget_bloc.dart';

enum AddEditBudgetStatus { initial, loading, success, error }

class AddEditBudgetState extends Equatable {
  final AddEditBudgetStatus status;
  final Budget? initialBudget; // Budget being edited
  final List<Category> availableCategories; // For category picker
  final String? errorMessage;

  const AddEditBudgetState({
    this.status = AddEditBudgetStatus.initial,
    this.initialBudget,
    this.availableCategories = const [],
    this.errorMessage,
  });

  bool get isEditing => initialBudget != null;

  AddEditBudgetState copyWith({
    AddEditBudgetStatus? status,
    Budget? initialBudget,
    ValueGetter<Budget?>? initialBudgetOrNull, // Allows setting to null
    List<Category>? availableCategories,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AddEditBudgetState(
      status: status ?? this.status,
      initialBudget: initialBudgetOrNull != null
          ? initialBudgetOrNull()
          : (initialBudget ?? this.initialBudget),
      availableCategories: availableCategories ?? this.availableCategories,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    initialBudget,
    availableCategories,
    errorMessage,
  ];
}
