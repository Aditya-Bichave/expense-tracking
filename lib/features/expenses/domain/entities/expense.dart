import 'package:equatable/equatable.dart';
import 'category.dart'; // Assuming ExpenseCategory is defined here

class Expense extends Equatable {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final Category category;
  final String accountId;

  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.accountId,
  });

  @override
  List<Object?> get props => [id, title, amount, date, category, accountId];
}
