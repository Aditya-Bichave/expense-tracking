// lib/features/goals/domain/entities/goal.dart
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart'; // Use same icons for now
import 'package:flutter/material.dart'; // For IconData
import 'package:expense_tracker/core/utils/logger.dart';

class Goal extends Equatable {
  final String id;
  final String name;
  final double targetAmount;
  final DateTime? targetDate;
  final String? iconName;
  final String? description;
  final GoalStatus status;
  final double
  totalSaved; // This will be read from cache in Hive implementation
  final DateTime createdAt;
  final DateTime? achievedAt;

  const Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.targetDate,
    this.iconName,
    this.description,
    required this.status,
    required this.totalSaved,
    required this.createdAt,
    this.achievedAt,
  });

  double get percentageComplete =>
      targetAmount > 0 ? (totalSaved / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get amountRemaining =>
      (targetAmount - totalSaved).clamp(0.0, targetAmount);
  bool get isAchieved => status == GoalStatus.achieved;
  bool get isArchived => status == GoalStatus.archived;

  // Helper to get icon
  IconData get displayIconData =>
      availableIcons[iconName] ?? Icons.savings_outlined; // Fallback

  @override
  List<Object?> get props => [
    id,
    name,
    targetAmount,
    targetDate,
    iconName,
    description,
    status,
    totalSaved,
    createdAt,
    achievedAt,
  ];

  Goal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    DateTime? targetDate,
    ValueGetter<DateTime?>? targetDateOrNull,
    String? iconName,
    ValueGetter<String?>? iconNameOrNull,
    String? description,
    ValueGetter<String?>? descriptionOrNull,
    GoalStatus? status,
    double? totalSaved, // Allow direct update for repo logic
    DateTime? createdAt,
    DateTime? achievedAt,
    ValueGetter<DateTime?>? achievedAtOrNull,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDateOrNull != null
          ? targetDateOrNull()
          : (targetDate ?? this.targetDate),
      iconName: iconNameOrNull != null
          ? iconNameOrNull()
          : (iconName ?? this.iconName),
      description: descriptionOrNull != null
          ? descriptionOrNull()
          : (description ?? this.description),
      status: status ?? this.status,
      totalSaved: totalSaved ?? this.totalSaved,
      createdAt: createdAt ?? this.createdAt,
      achievedAt: achievedAtOrNull != null
          ? achievedAtOrNull()
          : (achievedAt ?? this.achievedAt),
    );
  }
}
