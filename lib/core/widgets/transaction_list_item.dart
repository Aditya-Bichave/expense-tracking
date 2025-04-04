import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart'; // For availableIcons map
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';

// Common widget to display either an Expense or Income in a ListTile format
class TransactionListItem extends StatelessWidget {
  final TransactionEntity transaction; // Use the unified entity
  final String currencySymbol;
  final VoidCallback onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.currencySymbol,
    required this.onTap,
  });

  // Helper to get icon based on category or type
  Widget _buildIcon(BuildContext context, ThemeData theme) {
    final category = transaction.category ??
        Category.uncategorized; // Use uncategorized as fallback
    final isExpense = transaction.type == TransactionType.expense;
    final fallbackIconData =
        isExpense ? Icons.arrow_downward : Icons.arrow_upward;
    final color = isExpense
        ? theme.colorScheme.error
        : (theme.colorScheme.tertiary); // Use theme colors

    // Attempt to get icon from category definition
    final IconData displayIconData =
        availableIcons[category.iconName] ?? fallbackIconData;
    final Color displayColor = category.displayColor; // Color from category hex

    return Icon(
      displayIconData,
      color: displayColor,
      size: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = transaction.type == TransactionType.expense;
    final category = transaction.category ?? Category.uncategorized;
    final amountColor = isExpense
        ? theme.colorScheme.error
        : (theme.colorScheme.primary); // Income as primary

    return ListTile(
      leading: CircleAvatar(
        // Use category color with opacity for background
        backgroundColor: category.displayColor.withOpacity(0.15),
        child: _buildIcon(context, theme),
      ),
      title: Text(
        transaction.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Text(
          // Show category name and formatted date
          '${category.name} • ${DateFormatter.formatDate(transaction.date)}',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      trailing: Text(
        // Format amount with sign based on type
        '${isExpense ? '-' : '+'} ${CurrencyFormatter.format(transaction.amount, currencySymbol)}',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: amountColor,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5, // Adjust spacing if needed
        ),
      ),
      onTap: onTap,
      dense: true, // Make list items slightly more compact
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0, vertical: 4.0), // Adjust padding
    );
  }
}
