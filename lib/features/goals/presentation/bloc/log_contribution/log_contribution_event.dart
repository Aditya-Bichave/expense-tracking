// lib/features/goals/presentation/bloc/log_contribution/log_contribution_event.dart
part of 'log_contribution_bloc.dart';

abstract class LogContributionEvent extends Equatable {
  const LogContributionEvent();
  @override
  List<Object?> get props => [];
}

class InitializeContribution extends LogContributionEvent {
  final String goalId;
  final GoalContribution? initialContribution;
  const InitializeContribution(
      {required this.goalId, this.initialContribution});
  @override
  List<Object?> get props => [goalId, initialContribution];
}

class SaveContribution extends LogContributionEvent {
  final double amount;
  final DateTime date;
  final String? note;

  const SaveContribution({required this.amount, required this.date, this.note});
  @override
  List<Object?> get props => [amount, date, note];
}

// --- ADDED Delete Event ---
class DeleteContribution extends LogContributionEvent {
  // ID is implicit from the state when editing
  const DeleteContribution();
}
// --- END Delete Event ---

class ClearContributionMessage extends LogContributionEvent {
  const ClearContributionMessage();
}
