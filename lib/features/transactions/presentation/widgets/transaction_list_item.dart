import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart'; // For availableIcons map
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/ui_kit/components/app_list_tile.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
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
  Widget _buildIcon(BuildContext context) {
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
    final kit = context.kit;
    final isExpense = transaction.type == TransactionType.expense;
    final category = transaction.category ?? Category.uncategorized;
    final amountColor = isExpense
        ? kit.colors.error
        : kit.colors.primary; // Income as primary

    return AppListTile(
      leading: CircleAvatar(
        backgroundColor: category.displayColor.withOpacity(0.15),
        child: _buildIcon(context),
      ),
      title: Text(
        transaction.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${category.name} • ${DateFormatter.formatDate(transaction.date)}', // Show category name and formatted date
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${isExpense ? '-' : '+'} ${CurrencyFormatter.format(transaction.amount, currencySymbol)}',
        style: kit.typography.bodyLarge.copyWith(
          color: amountColor,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: kit.spacing.hMd + kit.spacing.vXs, // reproduce 16, 4
    );
  }
}
