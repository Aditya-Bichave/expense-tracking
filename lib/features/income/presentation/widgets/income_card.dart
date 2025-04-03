// lib/features/income/presentation/widgets/income_card.dart
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:expense_tracker/core/assets/app_assets.dart'; // Import asset catalog

class IncomeCard extends StatelessWidget {
  final Income income;
  final VoidCallback? onTap;

  const IncomeCard({
    super.key,
    required this.income,
    this.onTap,
  });

  // Helper to select the correct icon based on UI mode
  Widget _buildIcon(BuildContext context, AppModeTheme? modeTheme) {
    final theme = Theme.of(context);
    IconData defaultIconData =
        _getElementalIncomeCategoryIcon(income.category.name);
    String? svgPath;
    String categoryKey = income.category.name.toLowerCase();

    // Define income color (could also come from theme eventually)
    final Color incomeColor = Colors.green.shade800; // Example income color

    if (modeTheme != null) {
      // Attempt to get path from theme extension's asset map
      svgPath = modeTheme.assets.getCategoryIcon(categoryKey, defaultPath: '');
      if (svgPath.isEmpty) svgPath = null;
    }

    if (svgPath != null) {
      // log.debug("Using SVG path for $categoryKey: $svgPath");
      return SvgPicture.asset(
        svgPath, // Path comes from theme config
        width: 22,
        height: 22,
        colorFilter:
            ColorFilter.mode(incomeColor, BlendMode.srcIn), // Use income color
      );
    } else {
      // Fallback to Material Icon
      // log.debug("Using default Material Icon for $categoryKey");
      return Icon(defaultIconData,
          size: 22, color: incomeColor); // Use income color
    }
  }

  // Helper function to get a fallback Material icon based on income category name
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
        return Icons.attach_money; // Generic fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final modeTheme = context.modeTheme;

    // Watch AccountListBloc to get the account name
    final accountState = context.watch<AccountListBloc>().state;
    String accountName = '...';
    if (accountState is AccountListLoaded) {
      try {
        accountName = accountState.accounts
            .firstWhere((acc) => acc.id == income.accountId)
            .name;
      } catch (_) {
        accountName = 'Deleted';
      }
    } else if (accountState is AccountListError) {
      accountName = 'Error';
    }

    // Define colors for income (could be part of theme extension later)
    final Color incomeColor = Colors.green.shade700;
    final Color incomeIconBgColor = Colors.green.shade100;
    final Color incomeAmountColor = modeTheme?.incomeGlowColor ?? incomeColor;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: theme.cardTheme.margin,
      shape: theme.cardTheme.shape,
      elevation: theme.cardTheme.elevation,
      color: theme.cardTheme.color,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: theme.listTileTheme.contentPadding ??
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor:
                    incomeIconBgColor, // Use specific income icon BG
                foregroundColor: incomeColor, // Ensure contrast if needed
                child: _buildIcon(context, modeTheme),
              ),
              SizedBox(width: theme.listTileTheme.horizontalTitleGap ?? 16),
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
                      '${income.category.name} • $accountName',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      // Date moved below category/account line
                      DateFormatter.formatDateTime(income.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.8)),
                    ),
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
              Text(
                CurrencyFormatter.format(income.amount, currencySymbol),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color:
                      incomeAmountColor, // Use theme glow or default income color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
