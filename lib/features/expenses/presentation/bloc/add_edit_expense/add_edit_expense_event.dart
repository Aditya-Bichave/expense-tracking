part of 'add_edit_expense_bloc.dart';

abstract class AddEditExpenseEvent extends Equatable {
  const AddEditExpenseEvent();

  @override
  List<Object?> get props => [];
}

// Event triggered when the save button is pressed
class SaveExpenseRequested extends AddEditExpenseEvent {
  final String title;
  final double amount;
  final DateTime date;
  final Category category;
  final String? existingExpenseId; // Null if adding, non-null if editing
  final String accountId; // --- ADDED: Account ID is required ---

  const SaveExpenseRequested({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.existingExpenseId,
    required this.accountId, // --- ADDED: Made required ---
  });

  @override
  List<Object?> get props => [
        title,
        amount,
        date,
        category,
        existingExpenseId,
        accountId, // --- ADDED to props ---
      ];

  // Removed incorrect getter:
  // get accountId => null; // <-- REMOVED
}
