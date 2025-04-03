import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:expense_tracker/core/widgets/app_card.dart'; // Import AppCard

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
  });

  Widget _buildIcon(BuildContext context, AppModeTheme? modeTheme) {
    final theme = Theme.of(context);
    IconData defaultIconData = _getElementalCategoryIcon(expense.category.name);
    String? svgPath;
    // Use lowercase category name as the key, consistent with AssetKeys
    String categoryKey = expense.category.name.toLowerCase();

    if (modeTheme != null) {
      svgPath = modeTheme.assets.getCategoryIcon(categoryKey, defaultPath: '');
      if (svgPath.isEmpty) svgPath = null;
    }

    if (svgPath != null) {
      return SvgPicture.asset(
        svgPath,
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(
            theme.colorScheme.onSecondaryContainer, BlendMode.srcIn),
      );
    } else {
      return Icon(defaultIconData,
          size: 22, color: theme.colorScheme.onSecondaryContainer);
    }
  }

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
      case 'groceries':
        return Icons.shopping_cart_outlined;
      case 'subscription':
        return Icons.subscriptions_outlined;
      case 'medical':
        return Icons.medical_services_outlined;
      default:
        return Icons.label_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final modeTheme = context.modeTheme;

    final accountState = context.watch<AccountListBloc>().state;
    String accountName = '...';
    if (accountState is AccountListLoaded) {
      try {
        accountName = accountState.items // Use items from base state
            .firstWhere((acc) => acc.id == expense.accountId)
            .name;
      } catch (_) {
        accountName = 'Deleted';
      }
    } else if (accountState is AccountListError) {
      accountName = 'Error';
    }

    // Use AppCard as the base
    return AppCard(
      onTap: onTap,
      // Let AppCard handle margin, padding etc. based on theme
      child: Row(
        // Define the specific content for ExpenseCard
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            // Use theme colors directly
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            child: _buildIcon(context, modeTheme),
          ),
          // Use themed spacing if AppListTile is not used
          SizedBox(width: modeTheme?.listItemPadding.left ?? 16),
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
                  DateFormatter.formatDateTime(expense.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          // Use themed spacing
          SizedBox(width: modeTheme?.listItemPadding.right ?? 16),
          // Animated Balance Color
          AnimatedDefaultTextStyle(
            duration:
                modeTheme?.fastDuration ?? const Duration(milliseconds: 150),
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: modeTheme?.expenseGlowColor ?? theme.colorScheme.error,
            ),
            child:
                Text(CurrencyFormatter.format(expense.amount, currencySymbol)),
          )
        ],
      ),
    );
  }
}
