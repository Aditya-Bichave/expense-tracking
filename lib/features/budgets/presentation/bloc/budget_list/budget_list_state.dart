// lib/features/budgets/presentation/bloc/budget_list/budget_list_state.dart
part of 'budget_list_bloc.dart';

enum BudgetListStatus { initial, loading, success, error }

class BudgetListState extends Equatable {
  final BudgetListStatus status;
  // Use the wrapper class to hold calculated status
  final List<BudgetWithStatus> budgetsWithStatus;
  final String? errorMessage;

  const BudgetListState({
    this.status = BudgetListStatus.initial,
    this.budgetsWithStatus = const [],
    this.errorMessage,
  });

  BudgetListState copyWith({
    BudgetListStatus? status,
    List<BudgetWithStatus>? budgetsWithStatus,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BudgetListState(
      status: status ?? this.status,
      budgetsWithStatus: budgetsWithStatus ?? this.budgetsWithStatus,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, budgetsWithStatus, errorMessage];
}
