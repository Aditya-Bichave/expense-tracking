import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense_payer.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense_split.dart';
import 'package:flutter/material.dart';

class Expense extends Equatable {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final Category? category;
  final String accountId;
  final CategorizationStatus status;
  final double? confidenceScore;
  final String? merchantId;
  final bool isRecurring;

  // New Fields for Split Brain / Group Expenses
  final String? groupId;
  final String? createdBy;
  final String currency;
  final String? notes;
  final List<ExpensePayer> payers;
  final List<ExpenseSplit> splits;

  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.category,
    required this.accountId,
    this.status = CategorizationStatus.uncategorized,
    this.confidenceScore,
    this.merchantId,
    this.isRecurring = false,

    // Defaults for backward compatibility
    this.groupId,
    this.createdBy,
    this.currency = 'USD', // Default currency
    this.notes,
    this.payers = const [],
    this.splits = const [],
  });

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    Category? category,
    ValueGetter<Category?>? categoryOrNull,
    String? accountId,
    CategorizationStatus? status,
    double? confidenceScore,
    ValueGetter<double?>? confidenceScoreOrNull,
    String? merchantId,
    ValueGetter<String?>? merchantIdOrNull,
    bool? isRecurring,

    String? groupId,
    ValueGetter<String?>? groupIdOrNull,
    String? createdBy,
    String? currency,
    String? notes,
    ValueGetter<String?>? notesOrNull,
    List<ExpensePayer>? payers,
    List<ExpenseSplit>? splits,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: categoryOrNull != null
          ? categoryOrNull()
          : (category ?? this.category),
      accountId: accountId ?? this.accountId,
      status: status ?? this.status,
      confidenceScore: confidenceScoreOrNull != null
          ? confidenceScoreOrNull()
          : (confidenceScore ?? this.confidenceScore),
      merchantId: merchantIdOrNull != null
          ? merchantIdOrNull()
          : (merchantId ?? this.merchantId),
      isRecurring: isRecurring ?? this.isRecurring,

      groupId: groupIdOrNull != null
          ? groupIdOrNull()
          : (groupId ?? this.groupId),
      createdBy: createdBy ?? this.createdBy,
      currency: currency ?? this.currency,
      notes: notesOrNull != null ? notesOrNull() : (notes ?? this.notes),
      payers: payers ?? this.payers,
      splits: splits ?? this.splits,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    date,
    category,
    accountId,
    status,
    confidenceScore,
    merchantId,
    isRecurring,
    groupId,
    createdBy,
    currency,
    notes,
    payers,
    splits,
  ];
}
