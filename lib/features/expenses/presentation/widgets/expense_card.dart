import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart'; // To get account name
import 'package:expense_tracker/core/theme/app_theme.dart'; // For aether icons maybe

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
  });

  // --- Placeholder for Aether Icons ---
  IconData _getAetherExpenseIcon(String categoryName, String themeId) {
    // TODO: Implement logic to return specific Aether icons based on themeId and category
    // Example:
    // if (themeId == AppTheme.aetherGardenThemeId) {
    //    if (categoryName.toLowerCase() == 'food') return Icons.spa; // Placeholder leaf
    // }
    return _getElementalCategoryIcon(
        categoryName); // Fallback to default elemental icon
  }

  // Helper function to get an icon based on category name (Example implementation)
  IconData _getElementalCategoryIcon(String categoryName) {
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
      case 'health':
        return Icons.local_hospital_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.label_outline; // Default icon
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final uiMode = settingsState.uiMode;

    // Determine styles based on UI mode
    final bool isQuantum = uiMode == UIMode.quantum;
    final bool isAether = uiMode == UIMode.aether;
    final EdgeInsets cardPadding = isQuantum
        ? const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0)
        : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
    final double iconSize = isQuantum ? 18 : 22; // Smaller icon for Quantum
    final double spacing = isQuantum ? 10.0 : 16.0;
    final TextStyle? titleStyle = isQuantum
        ? theme.textTheme.bodyMedium
            ?.copyWith(fontWeight: FontWeight.w500) // Less emphasis on title
        : theme.textTheme.titleMedium;
    final TextStyle? amountStyle = isQuantum
        ? theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500, color: theme.colorScheme.error)
        : theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.error, fontWeight: FontWeight.bold);
    final IconData displayIcon = isAether
        ? _getAetherExpenseIcon(
            expense.category.name, settingsState.selectedThemeIdentifier)
        : _getElementalCategoryIcon(expense.category.name);

    // Get account name - needs AccountListBloc to be available
    final accountState = context.watch<AccountListBloc>().state;
    String accountName = '...'; // Placeholder while loading/error
    if (accountState is AccountListLoaded) {
      try {
        accountName = accountState.accounts
            .firstWhere((acc) => acc.id == expense.accountId)
            .name;
      } catch (_) {
        accountName = 'Deleted'; // Handle deleted account
      }
    }

    return Card(
      // Card theme handles margin, elevation, shape
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: cardPadding, // Apply conditional padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon based on category
              CircleAvatar(
                backgroundColor: isAether
                    ? theme.colorScheme.tertiaryContainer
                    : theme.colorScheme.secondaryContainer,
                child: Icon(
                  displayIcon,
                  size: iconSize,
                  color: isAether
                      ? theme.colorScheme.onTertiaryContainer
                      : theme.colorScheme.onSecondaryContainer,
                ),
              ),
              SizedBox(width: spacing),
              // Title, Category, Account, Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.title,
                        style: titleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: isQuantum ? 0 : 2), // Less space Quantum
                    Text(
                      '${expense.category.displayName} ${isQuantum ? "" : "• $accountName"}', // Hide account name in Quantum card
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isQuantum ? 0 : 2),
                    Text(
                      // Show only date in Quantum for brevity
                      isQuantum
                          ? DateFormatter.formatDate(expense.date)
                          : DateFormatter.formatDateTime(expense.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing),
              // Amount
              Text(
                CurrencyFormatter.format(expense.amount, currencySymbol),
                style: amountStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
