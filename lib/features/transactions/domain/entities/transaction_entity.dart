import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';

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
  final bool isRecurring;
  final String? merchantId;

  // Preserve original typed entities to avoid reconstruction/casting
  final Expense? expense;
  final Income? income;

  // Public constructor for general use and testing
  const TransactionEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.date,
    this.category,
    this.accountId = '',
    this.notes,
    this.status = CategorizationStatus.categorized,
    this.confidenceScore,
    this.isRecurring = false,
    this.merchantId,
  }) : expense = null,
       income = null;

  // Private constructor used by specialized factories
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
    required this.isRecurring,
    required this.merchantId,
    this.expense,
    this.income,
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
      isRecurring: expense.isRecurring,
      merchantId: expense.merchantId,
      expense: expense,
      income: null,
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
      isRecurring: income.isRecurring,
      merchantId: income.merchantId,
      expense: null,
      income: income,
    );
  }

  TransactionEntity copyWith({
    String? id,
    TransactionType? type,
    String? title,
    double? amount,
    DateTime? date,
    Category? category,
    String? accountId,
    String? notes,
    CategorizationStatus? status,
    double? confidenceScore,
    bool? isRecurring,
    String? merchantId,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      isRecurring: isRecurring ?? this.isRecurring,
      merchantId: merchantId ?? this.merchantId,
    );
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
    isRecurring,
    merchantId,
  ];
}
