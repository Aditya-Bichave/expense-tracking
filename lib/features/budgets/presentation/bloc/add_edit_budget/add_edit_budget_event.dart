// lib/features/budgets/presentation/bloc/add_edit_budget/add_edit_budget_event.dart
part of 'add_edit_budget_bloc.dart';

abstract class AddEditBudgetEvent extends Equatable {
  const AddEditBudgetEvent();
  @override
  List<Object?> get props => [];
}

class InitializeBudgetForm extends AddEditBudgetEvent {
  final Budget? initialBudget;
  const InitializeBudgetForm({this.initialBudget});
  @override
  List<Object?> get props => [initialBudget];
}

class SaveBudget extends AddEditBudgetEvent {
  final String name;
  final BudgetType type;
  final double targetAmount;
  final BudgetPeriodType period;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? categoryIds;
  final String? notes;

  const SaveBudget({
    required this.name,
    required this.type,
    required this.targetAmount,
    required this.period,
    this.startDate,
    this.endDate,
    this.categoryIds,
    this.notes,
  });

  @override
  List<Object?> get props => [
    name,
    type,
    targetAmount,
    period,
    startDate,
    endDate,
    categoryIds,
    notes,
  ];
}

// Event to clear success/error message
class ClearBudgetFormMessage extends AddEditBudgetEvent {
  const ClearBudgetFormMessage();
}
