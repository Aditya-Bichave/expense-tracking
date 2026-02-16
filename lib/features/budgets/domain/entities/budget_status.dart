// lib/features/budgets/domain/entities/budget_status.dart
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:flutter/material.dart'; // For Color

enum BudgetHealth { thriving, nearingLimit, overLimit, unknown }

// Wrapper to hold budget entity along with calculated status
class BudgetWithStatus extends Equatable {
  final Budget budget;
  final double amountSpent;
  final double amountRemaining;
  final double percentageUsed; // 0.0 to 1.0+
  final BudgetHealth health;
  final Color statusColor;

  const BudgetWithStatus({
    required this.budget,
    required this.amountSpent,
    required this.amountRemaining,
    required this.percentageUsed,
    required this.health,
    required this.statusColor,
  });

  factory BudgetWithStatus.calculate({
    required Budget budget,
    required double amountSpent,
    required Color thrivingColor, // Pass colors for flexibility
    required Color nearingLimitColor,
    required Color overLimitColor,
  }) {
    final target = budget.targetAmount;
    final remaining = (target - amountSpent).clamp(
      double.negativeInfinity,
      target,
    ); // Can't remain more than target
    final percentage = target > 0 ? (amountSpent / target) : 0.0;

    BudgetHealth health;
    Color color;

    if (percentage <= 0.75) {
      health = BudgetHealth.thriving;
      color = thrivingColor;
    } else if (percentage <= 1.0) {
      health = BudgetHealth.nearingLimit;
      color = nearingLimitColor;
    } else {
      health = BudgetHealth.overLimit;
      color = overLimitColor;
    }

    return BudgetWithStatus(
      budget: budget,
      amountSpent: amountSpent,
      amountRemaining: remaining,
      percentageUsed: percentage,
      health: health,
      statusColor: color,
    );
  }

  @override
  List<Object?> get props => [
    budget,
    amountSpent,
    amountRemaining,
    percentageUsed,
    health,
    statusColor,
  ];
}
