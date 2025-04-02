import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';

class IncomeCard extends StatelessWidget {
  final Income income;
  // Remove categoryName and accountName, get them from the income object
  // final String categoryName;
  // final String accountName;
  final VoidCallback? onTap;
  // Removed onEdit/onDelete, handled by parent Dismissible
  // final VoidCallback? onEdit;
  // final VoidCallback? onDelete;

  const IncomeCard({
    super.key,
    required this.income,
    // Removed required categoryName/accountName
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;

    // Account Name - Fetching handled in IncomeListPage's BlocBuilder now
    // If needed here directly, would require passing AccountListBloc state or name lookup

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Make whole card tappable
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon for Income
              CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Icon(Icons.arrow_upward,
                    color: Colors.green.shade800, size: 22),
              ),
              const SizedBox(width: 16),
              // Title, Category, Date, Notes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(income.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      // Show category name from income object
                      income.category.name,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      // Show date
                      DateFormatter.formatDateTime(income.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.8)),
                    ),
                    // Display notes if available
                    if (income.notes != null && income.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.notes,
                                size: 14,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                income.notes!,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontStyle: FontStyle.italic),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Amount
              Text(
                CurrencyFormatter.format(income.amount, currencySymbol),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700, // Income color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
