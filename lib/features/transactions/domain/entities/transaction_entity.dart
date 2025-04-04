import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/core/utils/enums.dart';

enum TransactionType { expense, income }

// Wrapper class to represent either an Expense or Income uniformly
class TransactionEntity extends Equatable {
  final String id;
  final TransactionType type;
  final String title;
  final double amount; // Always positive in entity, sign determined by type
  final DateTime date;
  final Category? category;
  final String accountId;
  final String? notes; // Nullable for expenses
  final CategorizationStatus status;
  final double? confidenceScore;

  // Private constructor
  const TransactionEntity._({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.accountId,
    required this.notes,
    required this.status,
    required this.confidenceScore,
  });

  // Factory constructor from Expense
  factory TransactionEntity.fromExpense(Expense expense) {
    return TransactionEntity._(
      id: expense.id,
      type: TransactionType.expense,
      title: expense.title,
      amount: expense.amount, // Expense amount is inherently positive cost
      date: expense.date,
      category: expense.category,
      accountId: expense.accountId,
      notes: null, // Expenses don't have notes in current model
      status: expense.status,
      confidenceScore: expense.confidenceScore,
    );
  }

  // Factory constructor from Income
  factory TransactionEntity.fromIncome(Income income) {
    return TransactionEntity._(
      id: income.id,
      type: TransactionType.income,
      title: income.title,
      amount: income.amount, // Income amount is positive gain
      date: income.date,
      category: income.category,
      accountId: income.accountId,
      notes: income.notes,
      status: income.status,
      confidenceScore: income.confidenceScore,
    );
  }

  // Helper to get original Expense/Income if needed (use with caution)
  dynamic get originalEntity {
    if (type == TransactionType.expense) {
      // Reconstruct Expense - assumes category is already hydrated
      return Expense(
          id: id,
          title: title,
          amount: amount,
          date: date,
          category: category,
          accountId: accountId,
          status: status,
          confidenceScore: confidenceScore);
    } else {
      // Reconstruct Income
      return Income(
          id: id,
          title: title,
          amount: amount,
          date: date,
          category: category,
          accountId: accountId,
          notes: notes,
          status: status,
          confidenceScore: confidenceScore);
    }
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        amount,
        date,
        category,
        accountId,
        notes,
        status,
        confidenceScore,
      ];
}
