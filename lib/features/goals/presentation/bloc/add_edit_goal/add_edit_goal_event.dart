// lib/features/goals/presentation/bloc/add_edit_goal/add_edit_goal_event.dart
part of 'add_edit_goal_bloc.dart';

abstract class AddEditGoalEvent extends Equatable {
  const AddEditGoalEvent();
  @override
  List<Object?> get props => [];
}

class InitializeGoalForm extends AddEditGoalEvent {
  final Goal? initialGoal;
  const InitializeGoalForm({this.initialGoal});
  @override
  List<Object?> get props => [initialGoal];
}

class SaveGoal extends AddEditGoalEvent {
  final String name;
  final double targetAmount;
  final DateTime? targetDate;
  final String? iconName;
  final String? description;

  const SaveGoal({
    required this.name,
    required this.targetAmount,
    this.targetDate,
    this.iconName,
    this.description,
  });
  @override
  List<Object?> get props =>
      [name, targetAmount, targetDate, iconName, description];
}

class ClearGoalFormMessage extends AddEditGoalEvent {
  const ClearGoalFormMessage();
}
