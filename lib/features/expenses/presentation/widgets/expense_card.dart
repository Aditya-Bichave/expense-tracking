// lib/features/expenses/presentation/widgets/expense_card.dart
// MODIFIED FILE (Implement interactive prompts)

import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/categorization_status_widget.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final Function(Expense expense)? onCardTap;
  final Function(Expense expense, Category selectedCategory)? onUserCategorized;
  final Function(Expense expense)? onChangeCategoryRequest;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onCardTap,
    this.onUserCategorized,
    this.onChangeCategoryRequest,
  });

  Widget _buildIcon(BuildContext context, AppModeTheme? modeTheme) {
    /* ... Same as before ... */
    Theme.of(context);
    final category = expense.category ?? Category.uncategorized;
    IconData fallbackIcon = Icons.label_outline;
    try {
      fallbackIcon = _getElementalCategoryIcon(category.name);
    } catch (_) {}
    log.info(
      "[ExpenseCard] Building icon for category '${category.name}' (IconName: ${category.iconName})",
    );
    if (modeTheme != null) {
      String svgPath = modeTheme.assets.getCategoryIcon(
        category.iconName,
        defaultPath: '',
      );
      if (svgPath.isNotEmpty) {
        log.info("[ExpenseCard] Using SVG: $svgPath");
        return SvgPicture.asset(
          svgPath,
          width: 22,
          height: 22,
          colorFilter: ColorFilter.mode(category.displayColor, BlendMode.srcIn),
        );
      }
    }
    log.info("[ExpenseCard] Falling back to IconData: $fallbackIcon");
    return Icon(fallbackIcon, size: 22, color: category.displayColor);
  }

  IconData _getElementalCategoryIcon(String categoryName) {
    /* ... Same as before ... */
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
      case 'groceries':
        return Icons.shopping_cart_outlined;
      case 'subscriptions':
        return Icons.subscriptions_outlined;
      case 'medical':
        return Icons.medical_services_outlined;
      case 'uncategorized':
        return Icons.help_outline;
      default:
        return Icons.label_outline;
    }
  }

  // Removed _buildStatusUI, replaced by CategorizationStatusWidget

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final modeTheme = context.modeTheme;
    final category = expense.category ?? Category.uncategorized;
    final accountState = context.watch<AccountListBloc>().state;
    String accountName = '...';
    if (accountState is AccountListLoaded) {
      try {
        accountName = accountState.items
            .firstWhere((acc) => acc.id == expense.accountId)
            .name;
      } catch (_) {
        accountName = 'Deleted';
      }
    } else if (accountState is AccountListError) {
      accountName = 'Error';
    }
    return AppCard(
      onTap: () => onCardTap?.call(expense),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: category.displayColor.withOpacity(0.15),
            child: _buildIcon(context, modeTheme),
          ),
          SizedBox(width: modeTheme?.listItemPadding.left ?? 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                CategorizationStatusWidget(
                  transaction: Transaction.fromExpense(expense),
                  onUserCategorized: onUserCategorized == null
                      ? null
                      : (tx, cat) => onUserCategorized!(expense, cat),
                  onChangeCategoryRequest: onChangeCategoryRequest == null
                      ? null
                      : (_) => onChangeCategoryRequest!(expense),
                ),
                const SizedBox(height: 2),
                Text(
                  'Acc: $accountName',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormatter.formatDateTime(expense.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: modeTheme?.listItemPadding.right ?? 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: modeTheme?.fastDuration ??
                    const Duration(milliseconds: 150),
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: modeTheme?.expenseGlowColor ?? theme.colorScheme.error,
                ),
                child: Text(
                  CurrencyFormatter.format(expense.amount, currencySymbol),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
