import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    // Default Elemental Icon
    IconData defaultIconData =
        _getElementalIncomeCategoryIcon(income.category.name);
    String? svgPath;
    String categoryKey = income.category.name.toLowerCase();

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
        width: 22, height: 22,
        colorFilter: ColorFilter.mode(
            Colors.green.shade800, BlendMode.srcIn), // Use income color
      );
    } else {
      return Icon(defaultIconData,
          size: 22, color: Colors.green.shade800); // Use income color
    }
  }

  // Helper function to get an Elemental icon based on income category name
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
        accountName = accountState.accounts
            .firstWhere((acc) => acc.id == income.accountId)
            .name;
      } catch (_) {
        accountName = 'Deleted';
      }
    }

    final Color incomeColor = Colors.green.shade700; // Define base income color
    final Color incomeIconBgColor = Colors.green.shade100;

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
                backgroundColor: incomeIconBgColor, // Specific income icon BG
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
                  color: modeTheme?.incomeGlowColor ??
                      incomeColor, // Use glow or default income color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
