import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:expense_tracker/core/widgets/app_card.dart'; // Import AppCard

class IncomeCard extends StatelessWidget {
  final Income income;
  final VoidCallback? onTap;

  const IncomeCard({
    super.key,
    required this.income,
    this.onTap,
  });

  // _buildIcon and _getElementalIncomeCategoryIcon helpers remain the same as previous refactor...
  Widget _buildIcon(BuildContext context, AppModeTheme? modeTheme) {
    final theme = Theme.of(context);
    IconData defaultIconData =
        _getElementalIncomeCategoryIcon(income.category.name);
    String? svgPath;
    String categoryKey = income.category.name.toLowerCase();
    final Color incomeColor = Colors.green.shade800; // Define income color

    if (modeTheme != null) {
      svgPath = modeTheme.assets.getCategoryIcon(categoryKey, defaultPath: '');
      if (svgPath.isEmpty) svgPath = null;
    }

    if (svgPath != null) {
      return SvgPicture.asset(
        svgPath,
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(incomeColor, BlendMode.srcIn),
      );
    } else {
      return Icon(defaultIconData, size: 22, color: incomeColor);
    }
  }

  IconData _getElementalIncomeCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'salary':
        return Icons.work_outline;
      case 'bonus':
        return Icons.card_giftcard_outlined;
      case 'freelance':
        return Icons.computer_outlined;
      case 'gift':
        return Icons.cake_outlined;
      case 'interest':
        return Icons.account_balance_outlined;
      default:
        return Icons.attach_money;
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
            .firstWhere((acc) => acc.id == income.accountId)
            .name;
      } catch (_) {
        accountName = 'Deleted';
      }
    } else if (accountState is AccountListError) {
      accountName = 'Error';
    }

    // Define colors for income (could be theme-based later)
    final Color incomeIconBgColor = Colors.green.shade100;
    final Color incomeAmountColor =
        modeTheme?.incomeGlowColor ?? Colors.green.shade700;

    // Use AppCard as the base
    return AppCard(
      onTap: onTap,
      // Let AppCard handle margin, padding etc. based on theme
      child: Row(
        // Define the specific content for IncomeCard
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: incomeIconBgColor,
            foregroundColor:
                Colors.green.shade800, // Specific color for income icon
            child: _buildIcon(context, modeTheme),
          ),
          SizedBox(
              width: modeTheme?.listItemPadding.left ?? 16), // Themed spacing
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
                  '${income.category.name} • $accountName', // Display simple category name
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormatter.formatDateTime(income.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.8)),
                ),
                if (income.notes != null && income.notes!.isNotEmpty)
                  Padding(
                    /* ... Notes UI ... */
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
          SizedBox(
              width: modeTheme?.listItemPadding.right ?? 16), // Themed spacing
          // Animated Amount Color
          AnimatedDefaultTextStyle(
            duration:
                modeTheme?.fastDuration ?? const Duration(milliseconds: 150),
            style: theme.textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
              color: incomeAmountColor, // Use derived income color
            ),
            child:
                Text(CurrencyFormatter.format(income.amount, currencySymbol)),
          )
        ],
      ),
    );
  }
}
