// lib/features/goals/presentation/widgets/goal_card.dart
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart'; // Import DateFormatter
import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart'; // Import status
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;
  // Add callbacks for menu actions later if needed
  // final VoidCallback? onEdit;
  // final VoidCallback? onArchive;
  // final VoidCallback? onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    // this.onEdit,
    // this.onArchive,
    // this.onDelete,
  });

  // --- Helper for Pacing Info ---
  // <<< ADD BuildContext parameter >>>
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

    if (daysRemaining <= 0 || amountNeeded <= 0) {
      return '';
    }

    final daysPerMonthApprox = 30.44;
    final monthsRemaining = daysRemaining / daysPerMonthApprox;
    // <<< Use context to get SettingsBloc >>>
    final currencySymbol = context.read<SettingsBloc>().state.currencySymbol;
    final neededPerMonth =
        monthsRemaining > 0 ? amountNeeded / monthsRemaining : double.infinity;
    final neededPerDay = amountNeeded / daysRemaining;

    String pacingText;
    if (neededPerMonth > 10) {
      pacingText =
          '≈ ${CurrencyFormatter.format(neededPerMonth, currencySymbol)} / month';
    } else {
      pacingText =
          '≈ ${CurrencyFormatter.format(neededPerDay, currencySymbol)} / day';
    }
    return pacingText;
  }
  // --- End Pacing Helper ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currency = settings.currencySymbol;
    final modeTheme = context.modeTheme;

    final double progress = goal.percentageComplete;
    final Color progressColor =
        goal.isAchieved ? Colors.green.shade600 : theme.colorScheme.primary;
    final Color backgroundColor =
        theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);
    final String pacingInfo = _getPacingInfo(context, theme);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header: Icon & Name & Status ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: progressColor.withOpacity(0.1),
                radius: 20,
                child:
                    Icon(goal.displayIconData, color: progressColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(goal.name,
                    style: theme.textTheme.titleMedium, // Adjusted size
                    overflow: TextOverflow.ellipsis),
              ),
              if (goal.isAchieved)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Chip(
                    avatar: Icon(Icons.check_circle_outline_rounded,
                        color: Colors.green.shade800, size: 16),
                    label: Text('Achieved!'),
                    labelStyle: theme.textTheme.labelSmall
                        ?.copyWith(color: Colors.green.shade900),
                    backgroundColor: Colors.green.shade100,
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                  ),
                )
              else if (goal.isArchived)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Chip(
                    avatar: Icon(Icons.archive_outlined,
                        color: theme.disabledColor, size: 16),
                    label: Text('Archived'),
                    labelStyle: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.disabledColor),
                    backgroundColor: theme.disabledColor.withOpacity(0.1),
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                  ),
                ),
              // TODO: Add ellipsis menu later for edit/archive
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
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center vertically
                  children: [
                    // Use RichText for better formatting flexibility
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurface),
                        children: <TextSpan>[
                          TextSpan(text: 'Saved: '),
                          TextSpan(
                            text: CurrencyFormatter.format(
                                goal.totalSaved, currency),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                        children: <TextSpan>[
                          TextSpan(text: 'Target: '),
                          TextSpan(
                            text: CurrencyFormatter.format(
                                goal.targetAmount, currency),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Pacing Info (if applicable)
                    if (pacingInfo.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.schedule_outlined,
                                size: 14, color: theme.colorScheme.secondary),
                            const SizedBox(width: 4),
                            Expanded(
                              // Allow pacing text to wrap or ellipsis
                              child: Text(
                                pacingInfo,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.secondary),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2, // Give space to the indicator
                child: CircularPercentIndicator(
                  radius: 45.0,
                  lineWidth: 10.0,
                  animation: true,
                  percent: progress,
                  center: Text(
                    "${(progress * 100).toStringAsFixed(0)}%",
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold, color: progressColor),
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: progressColor,
                  backgroundColor: backgroundColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // --- Footer: Remaining & Target Date ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Show remaining only if not achieved
              if (!goal.isAchieved)
                Text(
                  '${CurrencyFormatter.format(goal.amountRemaining, currency)} to go',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                )
              else
                const SizedBox(), // Placeholder to keep alignment
              if (goal.targetDate != null)
                Row(
                  // Add icon to target date
                  children: [
                    Icon(Icons.flag_circle_outlined,
                        size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      DateFormatter.formatDate(goal.targetDate!),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
