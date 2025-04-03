import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
  });

  // Helper to select the correct icon based on UI mode
  Widget _buildIcon(BuildContext context, AppModeTheme? modeTheme) {
    final theme = Theme.of(context);
    // Default Elemental Icon
    IconData defaultIconData = _getElementalCategoryIcon(expense.category.name);
    String? svgPath;
    String categoryKey =
        expense.category.name.toLowerCase(); // Use lowercase for map keys

    if (modeTheme != null) {
      svgPath =
          modeTheme.assets.getCategoryIcon(categoryKey, // Use normalized key
              defaultPath: '' // Fallback handled below
              );
      if (svgPath.isEmpty) svgPath = null;
    }

    if (svgPath != null) {
      return SvgPicture.asset(
        svgPath,
        width: 22, height: 22, // Consistent size
        colorFilter: ColorFilter.mode(
            theme.colorScheme.onSecondaryContainer, BlendMode.srcIn),
      );
    } else {
      return Icon(defaultIconData,
          size: 22, color: theme.colorScheme.onSecondaryContainer);
    }
  }

  // Helper function to get an Elemental icon based on category name
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
    final modeTheme = context.modeTheme; // Get custom theme extension

    final accountState = context.watch<AccountListBloc>().state;
    String accountName = '...'; // Loading/Unknown state
    if (accountState is AccountListLoaded) {
      try {
        accountName = accountState.accounts
            .firstWhere((acc) => acc.id == expense.accountId)
            .name;
      } catch (_) {
        accountName = 'Deleted';
      }
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: theme.listTileTheme.contentPadding ??
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: _buildIcon(context, modeTheme), // Use helper
              ),
              SizedBox(width: theme.listTileTheme.horizontalTitleGap ?? 16),
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
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                CurrencyFormatter.format(expense.amount, currencySymbol),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: modeTheme?.expenseGlowColor ??
                      theme.colorScheme.error, // Use glow or default error
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
