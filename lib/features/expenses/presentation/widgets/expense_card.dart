import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart'; // To get account name

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  // Removed onDismissed as it's handled by the parent Dismissible widget
  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;

    // Get account name - needs AccountListBloc to be available
    final accountState = context.watch<AccountListBloc>().state;
    String accountName = 'Unknown Account';
    if (accountState is AccountListLoaded) {
      try {
        accountName = accountState.accounts
            .firstWhere((acc) => acc.id == expense.accountId)
            .name;
      } catch (_) {
        // Account might have been deleted, handle gracefully
        accountName = 'Deleted Account';
      }
    } else if (accountState is AccountListLoading) {
      accountName = 'Loading...';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Make card tappable
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon based on category (Example - refine this logic)
              CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Icon(
                  _getCategoryIcon(expense.category.name), // Helper for icon
                  size: 22,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              // Title, Category, Account, Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${expense.category.displayName} • $accountName',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormatter.formatDateTime(
                          expense.date), // Use consistent formatter
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Amount
              Text(
                CurrencyFormatter.format(expense.amount, currencySymbol),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to get an icon based on category name (Example implementation)
  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_bus;
      case 'utilities':
        return Icons.lightbulb_outline;
      case 'entertainment':
        return Icons.local_movies;
      case 'housing':
        return Icons.home_outlined;
      case 'health': // Example addition
        return Icons.local_hospital_outlined;
      case 'shopping': // Example addition
        return Icons.shopping_bag_outlined;
      default:
        return Icons.label_outline; // Default icon
    }
  }
}
