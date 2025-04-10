// lib/features/goals/presentation/widgets/goal_card.dart
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
  });

  String _getPacingInfo(BuildContext context, ThemeData theme) {
    if (goal.targetDate == null || goal.isAchieved || goal.targetAmount <= 0) {
      return '';
    }
    final now = DateTime.now();
    final targetDate = goal.targetDate!;
    if (targetDate.isBefore(now)) {
      return goal.totalSaved >= goal.targetAmount ? '' : 'Target date passed!';
    }
    final daysRemaining = targetDate.difference(now).inDays;
    final amountNeeded =
        (goal.targetAmount - goal.totalSaved).clamp(0.0, double.infinity);
    if (daysRemaining <= 0 || amountNeeded <= 0) return '';
    const daysPerMonthApprox = 30.44;
    final monthsRemaining = daysRemaining / daysPerMonthApprox;
    final currencySymbol = context.read<SettingsBloc>().state.currencySymbol;
    final neededPerMonth =
        monthsRemaining > 0 ? amountNeeded / monthsRemaining : double.infinity;
    final neededPerDay = amountNeeded / daysRemaining;

    String pacingText;
    if (neededPerDay.isInfinite || neededPerMonth.isInfinite) return '';

    if (neededPerMonth > 10) {
      // Arbitrary threshold to switch display unit
      pacingText =
          '≈ ${CurrencyFormatter.format(neededPerMonth, currencySymbol)} / month';
    } else {
      pacingText =
          '≈ ${CurrencyFormatter.format(neededPerDay, currencySymbol)} / day';
    }
    return pacingText;
  }

  // Helper for Progress Indicator based on UI Mode (REMOVED AETHER TBD)
  Widget _buildProgressIndicator(
      BuildContext context, AppModeTheme? modeTheme, UIMode uiMode) {
    final theme = Theme.of(context);
    final progress = goal.percentageComplete;
    final color =
        goal.isAchieved ? Colors.green.shade600 : theme.colorScheme.primary;
    final backgroundColor =
        theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);
    final bool isQuantum = uiMode == UIMode.quantum;
    // final bool isAether = uiMode == UIMode.aether; // No Aether specific impl

    // Aether specific asset check (Removed - fallback to default)

    // Elemental or Quantum (Quantum might just show text)
    final double radius = isQuantum ? 35.0 : 45.0;
    final double lineWidth = isQuantum ? 6.0 : 10.0;
    final TextStyle centerTextStyle =
        (isQuantum ? theme.textTheme.labelSmall : theme.textTheme.titleSmall)
                ?.copyWith(fontWeight: FontWeight.bold, color: color) ??
            TextStyle(color: color);

    return CircularPercentIndicator(
      radius: radius,
      lineWidth: lineWidth,
      animation: !isQuantum, // Disable animation for Quantum
      animationDuration: isQuantum ? 0 : 800,
      percent: progress,
      center: Text(
        "${(progress * 100).toStringAsFixed(0)}%",
        style: centerTextStyle,
      ),
      circularStrokeCap: CircularStrokeCap.round,
      progressColor: color,
      backgroundColor: backgroundColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currency = settings.currencySymbol;
    final uiMode = settings.uiMode;
    final modeTheme = context.modeTheme;
    final String pacingInfo = _getPacingInfo(context, theme);

    final cardMargin = modeTheme?.cardOuterPadding ??
        const EdgeInsets.symmetric(horizontal: 12, vertical: 5);
    final cardPadding =
        modeTheme?.cardInnerPadding ?? const EdgeInsets.all(12.0);
    final progressColor =
        goal.isAchieved ? Colors.green.shade600 : theme.colorScheme.primary;

    return AppCard(
      onTap: onTap,
      margin: cardMargin,
      padding: cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header: Icon & Name & Status ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                  backgroundColor: progressColor.withOpacity(0.1),
                  child: Icon(goal.displayIconData,
                      color: progressColor, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(goal.name, style: theme.textTheme.titleMedium)),
              if (goal.isAchieved || goal.isArchived)
                Chip(
                  label: Text(goal.status.displayName,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: goal.isAchieved
                              ? Colors.green.shade800
                              : theme.colorScheme.onSurfaceVariant)),
                  backgroundColor: goal.isAchieved
                      ? Colors.green.shade100.withOpacity(0.6)
                      : theme.colorScheme.surfaceContainerHighest,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                )
            ],
          ),
          const SizedBox(height: 16),

          // --- Progress Section ---
          Row(
            children: [
              Expanded(
                flex: 3, // Give more space to text
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saved', style: theme.textTheme.labelMedium),
                    Text(CurrencyFormatter.format(goal.totalSaved, currency),
                        style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600, color: progressColor)),
                    const SizedBox(height: 4),
                    Text('Target', style: theme.textTheme.labelSmall),
                    Text(CurrencyFormatter.format(goal.targetAmount, currency),
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2, // Give less space to the indicator
                child: _buildProgressIndicator(context, modeTheme, uiMode),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // --- Pacing Info Display ---
          if (pacingInfo.isNotEmpty && !goal.isAchieved && !goal.isArchived)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.run_circle_outlined,
                      size: 14,
                      color:
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text(pacingInfo,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          const SizedBox(height: 8),

          // --- Footer: Remaining & Target Date ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal.isAchieved
                    ? 'Achieved!'
                    : 'Remaining: ${CurrencyFormatter.format(goal.amountRemaining, currency)}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: goal.isAchieved
                        ? Colors.green
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w500),
              ),
              if (goal.targetDate != null)
                Text(
                  'Target: ${DateFormatter.formatDate(goal.targetDate!)}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
