import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/add_expense/domain/models/add_expense_enums.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';

sealed class AddExpenseWizardEvent extends Equatable {
  const AddExpenseWizardEvent();
  @override
  List<Object?> get props => [];
}

class WizardStarted extends AddExpenseWizardEvent {
  const WizardStarted();
}

class AmountChanged extends AddExpenseWizardEvent {
  final double amount;
  const AmountChanged(this.amount);
  @override
  List<Object?> get props => [amount];
}

class DescriptionChanged extends AddExpenseWizardEvent {
  final String description;
  const DescriptionChanged(this.description);
  @override
  List<Object?> get props => [description];
}

class CategorySelected extends AddExpenseWizardEvent {
  final Category category;
  const CategorySelected(this.category);
  @override
  List<Object?> get props => [category];
}

class GroupSelected extends AddExpenseWizardEvent {
  final GroupEntity? group;
  const GroupSelected(this.group);
  @override
  List<Object?> get props => [group];
}

class DateChanged extends AddExpenseWizardEvent {
  final DateTime date;
  const DateChanged(this.date);
  @override
  List<Object?> get props => [date];
}

class NotesChanged extends AddExpenseWizardEvent {
  final String notes;
  const NotesChanged(this.notes);
  @override
  List<Object?> get props => [notes];
}

class ReceiptSelected extends AddExpenseWizardEvent {
  final String localPath;
  const ReceiptSelected(this.localPath);
  @override
  List<Object?> get props => [localPath];
}

class SplitModeChanged extends AddExpenseWizardEvent {
  final SplitMode mode;
  const SplitModeChanged(this.mode);
  @override
  List<Object?> get props => [mode];
}

class SplitValueChanged extends AddExpenseWizardEvent {
  final String userId;
  final double value;
  const SplitValueChanged(this.userId, this.value);
  @override
  List<Object?> get props => [userId, value];
}

class SinglePayerSelected extends AddExpenseWizardEvent {
  final String userId;
  const SinglePayerSelected(this.userId);
  @override
  List<Object?> get props => [userId];
}

class PayerChanged extends AddExpenseWizardEvent {
  final String userId;
  final double amount;
  const PayerChanged(this.userId, this.amount);
  @override
  List<Object?> get props => [userId, amount];
}

class SubmitExpense extends AddExpenseWizardEvent {
  const SubmitExpense();
}
