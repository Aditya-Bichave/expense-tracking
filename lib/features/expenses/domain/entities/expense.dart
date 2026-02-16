import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart'; // Use the new Category entity
import 'package:flutter/material.dart'; // Import CategorizationStatus

class Expense extends Equatable {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final Category?
  category; // CHANGED: Now holds the full Category object, nullable initially
  final String accountId;
  final CategorizationStatus status; // ADDED
  final double? confidenceScore; // ADDED

  final bool isRecurring;

  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.category, // Make category nullable
    required this.accountId,
    this.status =
        CategorizationStatus.uncategorized, // ADDED: Default to uncategorized
    this.confidenceScore, // ADDED
    this.isRecurring = false,
  });

  // Optional: CopyWith method for easier updates
  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    Category? category, // Allow updating category object
    ValueGetter<Category?>? categoryOrNull, // Allow setting to null explicitly
    String? accountId,
    CategorizationStatus? status,
    double? confidenceScore,
    ValueGetter<double?>? confidenceScoreOrNull, // Allow setting to null
    bool? isRecurring,
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
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    date,
    category, // Updated
    accountId,
    status, // Added
    confidenceScore, // Added
    isRecurring,
  ];
}
