part of 'add_edit_transaction_bloc.dart';

abstract class AddEditTransactionEvent extends Equatable {
  const AddEditTransactionEvent();
  @override
  List<Object?> get props => [];
}

// Initial event when opening the page (determines add/edit mode)
class InitializeTransaction extends AddEditTransactionEvent {
  final TransactionEntity? initialTransaction;
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
  final String title;
  final double amount;
  final DateTime date;
  final Category category; // Use unified Category
  final String accountId;
  final String? notes; // Nullable for income

  const SaveTransactionRequested({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.accountId,
    this.notes,
  });

  @override
  List<Object?> get props => [title, amount, date, category, accountId, notes];
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
  const CreateCustomCategoryRequested();
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

// User manually selected a category from the picker
class CategorySelected extends AddEditTransactionEvent {
  final Category selectedCategory;
  const CategorySelected(this.selectedCategory);
  @override
  List<Object?> get props => [selectedCategory];
}
