part of 'add_edit_transaction_bloc.dart';

abstract class AddEditTransactionEvent extends Equatable {
  const AddEditTransactionEvent();
  @override
  List<Object?> get props => [];
}

// Initial event when opening the page (determines add/edit mode)
class InitializeTransaction extends AddEditTransactionEvent {
  final Transaction? initialTransaction;
  const InitializeTransaction({this.initialTransaction});
  @override
  List<Object?> get props => [initialTransaction];
}

// User toggles between Expense and Income
class TransactionTypeChanged extends AddEditTransactionEvent {
  final TransactionType newType;
  const TransactionTypeChanged(this.newType);
  @override
  List<Object?> get props => [newType];
}

// User saves the form
class SaveTransactionRequested extends AddEditTransactionEvent {
  final String? title;
  final double amount;
  final DateTime date;
  final Category? category; // Use unified Category
  final String? fromAccountId;
  final String? toAccountId;
  final String? notes; // Nullable for income

  const SaveTransactionRequested({
    this.title,
    required this.amount,
    required this.date,
    this.category,
    this.fromAccountId,
    this.toAccountId,
    this.notes,
  });

  @override
  List<Object?> get props => [title, amount, date, category, fromAccountId, toAccountId, notes];
}

// User confirmed a category suggestion
class AcceptCategorySuggestion extends AddEditTransactionEvent {
  final Category suggestedCategory;
  const AcceptCategorySuggestion(this.suggestedCategory);
  @override
  List<Object?> get props => [suggestedCategory];
}

// User rejected a suggestion / Wants to pick manually
class RejectCategorySuggestion extends AddEditTransactionEvent {
  const RejectCategorySuggestion();
}

// User confirmed they want to create a category (after rejecting suggestion)
class CreateCustomCategoryRequested extends AddEditTransactionEvent {
  final String title;
  final double amount;
  final DateTime date;
  final String accountId;
  final String? notes;

  const CreateCustomCategoryRequested({
    required this.title,
    required this.amount,
    required this.date,
    required this.accountId,
    this.notes,
  });

  @override
  List<Object?> get props => [title, amount, date, accountId, notes];
}

// A new category was created (passed back from AddCategory screen)
class CategoryCreated extends AddEditTransactionEvent {
  final Category newCategory;
  const CategoryCreated(this.newCategory);
  @override
  List<Object?> get props => [newCategory];
}

// Event to clear specific error/message states if needed
class ClearMessages extends AddEditTransactionEvent {
  const ClearMessages();
}
