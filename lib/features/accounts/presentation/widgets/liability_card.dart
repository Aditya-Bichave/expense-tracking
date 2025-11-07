import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/accounts/domain/entities/liability.dart';
import 'package:expense_tracker/features/accounts/domain/entities/liability_enums.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class LiabilityCard extends StatelessWidget {
  final Liability liability;
  final VoidCallback onTap;

  const LiabilityCard({
    super.key,
    required this.liability,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;

    final isCreditCard = liability.type == LiabilityType.creditCard;
    final creditLimit = liability.creditLimit ?? 0;
    final utilization =
        creditLimit > 0 ? liability.currentBalance / creditLimit : 0.0;

    Color progressBarColor;
    if (utilization > 0.7) {
      progressBarColor = Colors.red;
    } else if (utilization > 0.3) {
      progressBarColor = Colors.orange;
    } else {
      progressBarColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(liability.name, style: theme.textTheme.titleLarge),
                  Text(
                    CurrencyFormatter.format(
                        liability.currentBalance, currencySymbol),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                liability.type.toString().split('.').last,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (isCreditCard && creditLimit > 0) ...[
                const SizedBox(height: 16),
                LinearPercentIndicator(
                  lineHeight: 8.0,
                  percent: utilization.clamp(0.0, 1.0),
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  progressColor: progressBarColor,
                  barRadius: const Radius.circular(4),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Credit Utilization',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${(utilization * 100).toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
