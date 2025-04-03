part of 'add_edit_income_bloc.dart';

abstract class AddEditIncomeEvent extends Equatable {
  const AddEditIncomeEvent();
  @override
  List<Object?> get props => [];
}

class SaveIncomeRequested extends AddEditIncomeEvent {
  final String title;
  final double amount;
  final DateTime date;
  final Category category; // CORRECTED: Use unified Category
  final String accountId;
  final String? notes;
  final String? existingIncomeId; // Null if adding

  const SaveIncomeRequested({
    required this.title,
    required this.amount,
    required this.date,
    required this.category, // Use unified Category
    required this.accountId,
    this.notes,
    this.existingIncomeId,
  });

  @override
  List<Object?> get props =>
      [title, amount, date, category, accountId, notes, existingIncomeId];
}
