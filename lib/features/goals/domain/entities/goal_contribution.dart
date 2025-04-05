// lib/features/goals/domain/entities/goal_contribution.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class GoalContribution extends Equatable {
  final String id;
  final String goalId;
  final double amount;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  const GoalContribution({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.note,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, goalId, amount, date, note, createdAt];

  GoalContribution copyWith({
    String? id,
    String? goalId,
    double? amount,
    DateTime? date,
    String? note,
    ValueGetter<String?>? noteOrNull,
    DateTime? createdAt,
  }) {
    return GoalContribution(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: noteOrNull != null ? noteOrNull() : (note ?? this.note),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
