// lib/features/budgets/presentation/bloc/budget_list/budget_list_event.dart
part of 'budget_list_bloc.dart';

abstract class BudgetListEvent extends Equatable {
  const BudgetListEvent();
  @override
  List<Object> get props => [];
}

class LoadBudgets extends BudgetListEvent {
  final bool forceReload;
  const LoadBudgets({this.forceReload = false});
  @override
  List<Object> get props => [forceReload];
}

class _BudgetsDataChanged extends BudgetListEvent {
  const _BudgetsDataChanged();
}

// --- ADDED Delete Event ---
class DeleteBudget extends BudgetListEvent {
  final String budgetId;
  const DeleteBudget({required this.budgetId});
  @override
  List<Object> get props => [budgetId];
}

// --- ADDED: Reset State Event ---
class ResetState extends BudgetListEvent {
  const ResetState();
}

// --- END ADDED ---
