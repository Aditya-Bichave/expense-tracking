// lib/features/budgets/presentation/widgets/budget_card.dart
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart'; // Add dependency

class BudgetCard extends StatelessWidget {
  final BudgetWithStatus budgetStatus;
  final VoidCallback? onTap;

  const BudgetCard({
    super.key,
    required this.budgetStatus,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currency = settings.currencySymbol;
    final budget = budgetStatus.budget;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header ---
          Row(
            children: [
              // TODO: Add category icons if budget.type == categorySpecific
              Expanded(
                child: Text(budget.name,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(
                budget.period == BudgetPeriodType.recurringMonthly
                    ? 'Monthly'
                    : 'One-Time',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              )
            ],
          ),
          const SizedBox(height: 12),

          // --- Progress Bar & Amounts ---
          LinearPercentIndicator(
            // Add dependency: percent_indicator
            // key: ValueKey(budgetStatus.percentageUsed), // Optional key for animation
            animation: true,
            animationDuration: 600,
            lineHeight: 18.0,
            percent: budgetStatus.percentageUsed
                .clamp(0.0, 1.0), // Clamp visual max to 100%
            center: Text(
              "${(budgetStatus.percentageUsed * 100).toStringAsFixed(0)}%",
              style: TextStyle(
                  color: budgetStatus.statusColor.computeLuminance() > 0.5
                      ? Colors.black87
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11),
            ),
            barRadius: const Radius.circular(9),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            progressColor: budgetStatus.statusColor, // Use calculated color
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${CurrencyFormatter.format(budgetStatus.amountSpent, currency)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: budgetStatus.statusColor),
              ),
              Text(
                'Target: ${CurrencyFormatter.format(budget.targetAmount, currency)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          // Show remaining amount or overspent amount
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                budgetStatus.amountRemaining >= 0
                    ? '${CurrencyFormatter.format(budgetStatus.amountRemaining, currency)} left'
                    : '${CurrencyFormatter.format(budgetStatus.amountRemaining.abs(), currency)} over',
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: budgetStatus.amountRemaining >= 0
                        ? theme.colorScheme.primary
                        : budgetStatus.statusColor // Use status color if over
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
