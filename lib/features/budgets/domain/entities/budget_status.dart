import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';

enum BudgetHealth { thriving, nearingLimit, overLimit, unknown }

class BudgetWithStatus extends Equatable {
  final Budget budget;
  final double amountSpent;
  final double amountRemaining;
  final double percentageUsed;
  final BudgetHealth health;

  const BudgetWithStatus({
    required this.budget,
    required this.amountSpent,
    required this.amountRemaining,
    required this.percentageUsed,
    required this.health,
  });

  bool get isOverLimit => health == BudgetHealth.overLimit;
  bool get isNearingLimit => health == BudgetHealth.nearingLimit;

  factory BudgetWithStatus.calculate({
    required Budget budget,
    required double amountSpent,
  }) {
    final target = budget.targetAmount;
    final remaining = (target - amountSpent);
    final percentage = target > 0 ? (amountSpent / target) : 0.0;

    BudgetHealth health;

    if (percentage <= 0.75) {
      health = BudgetHealth.thriving;
    } else if (percentage <= 1.0) {
      health = BudgetHealth.nearingLimit;
    } else {
      health = BudgetHealth.overLimit;
    }

    return BudgetWithStatus(
      budget: budget,
      amountSpent: amountSpent,
      amountRemaining: remaining,
      percentageUsed: percentage,
      health: health,
    );
  }

  @override
  List<Object?> get props => [
    budget,
    amountSpent,
    amountRemaining,
    percentageUsed,
    health,
  ];
}
