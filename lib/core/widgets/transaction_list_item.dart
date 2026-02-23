import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart'; // For availableIcons map
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
// logger

// Common widget to display either an Expense or Income in a ListTile format
class TransactionListItem extends StatelessWidget {
  final TransactionEntity transaction; // Use the unified entity
  final String currencySymbol;
  final VoidCallback onTap;
  // final VoidCallback? onLongPress; // Optional: Add onLongPress if needed directly here

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.currencySymbol,
    required this.onTap,
    // this.onLongPress, // Uncomment if adding
  });

  // Helper to get icon based on category or type
  Widget _buildIcon(BuildContext context, ThemeData theme) {
    final category =
        transaction.category ??
        Category.uncategorized; // Use uncategorized as fallback
    final isExpense = transaction.type == TransactionType.expense;
    final fallbackIconData = isExpense
        ? Icons.arrow_downward
        : Icons.arrow_upward;

    // Attempt to get icon from category definition using the availableIcons map
    final IconData displayIconData =
        availableIcons[category.iconName] ?? fallbackIconData;
    final Color displayColor = category.displayColor; // Color from category hex

    return Icon(
      displayIconData,
      color: displayColor,
      size: 20, // Consistent icon size
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = transaction.type == TransactionType.expense;
    final category = transaction.category ?? Category.uncategorized;
    final amountColor = isExpense
        ? theme.colorScheme.error
        : theme.colorScheme.primary; // Income as primary

    final formattedAmount = CurrencyFormatter.format(
      transaction.amount,
      currencySymbol,
    );

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: category.displayColor.withOpacity(0.15),
        child: _buildIcon(context, theme),
      ),
      title: Row(
        children: [
          if (transaction.isRecurring)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8.0),
              child: SvgPicture.asset(
                'assets/elemental/icons/common/ic_recurring.svg',
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(
                  theme.colorScheme.onSurfaceVariant,
                  BlendMode.srcIn,
                ),
              ),
            ),
          Expanded(
            child: Text(
              transaction.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
      subtitle: Text(
        '${category.name} • ${DateFormatter.formatDate(transaction.date)}', // Show category name and formatted date
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Semantics(
        label: '${isExpense ? 'Expense' : 'Income'} of $formattedAmount',
        excludeSemantics: true,
        child: Text(
          '${isExpense ? '-' : '+'} $formattedAmount',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: amountColor,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
      onTap: onTap, // Use the passed onTap callback
      // onLongPress: onLongPress, // Uncomment if adding long press
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ),
    );
  }
}
