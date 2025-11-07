import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';

enum TransactionType { expense, income, transfer }

class Transaction extends Equatable {
  final String id;
  final TransactionType type;
  final double amount;
  final DateTime date;
  final String? fromAccountId;
  final String? toAccountId;
  final String title;
  final Category? category;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    this.fromAccountId,
    this.toAccountId,
    required this.title,
    this.category,
  });

  factory Transaction.fromExpense(Expense expense) {
    return Transaction(
      id: expense.id,
      type: TransactionType.expense,
      amount: expense.amount,
      date: expense.date,
      fromAccountId: expense.accountId,
      title: expense.title,
      category: expense.category,
    );
  }

  factory Transaction.fromIncome(Income income) {
    return Transaction(
      id: income.id,
      type: TransactionType.income,
      amount: income.amount,
      date: income.date,
      fromAccountId: income.accountId,
      title: income.title,
      category: income.category,
    );
  }

  @override
  List<Object?> get props => [id, type, amount, date, fromAccountId, toAccountId, title, category];

  Expense toExpense() {
    return Expense(
      id: id,
      title: title,
      amount: amount,
      date: date,
      category: category,
      accountId: fromAccountId!,
    );
  }

  Income toIncome() {
    return Income(
      id: id,
      title: title,
      amount: amount,
      date: date,
      category: category,
      accountId: fromAccountId!,
    );
  }

  Transaction copyWith({
    String? id,
    TransactionType? type,
    double? amount,
    DateTime? date,
    String? fromAccountId,
    String? toAccountId,
    String? title,
    Category? category,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      title: title ?? this.title,
      category: category ?? this.category,
    );
  }
}
