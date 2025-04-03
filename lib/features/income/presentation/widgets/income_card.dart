import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart'; // Import
import 'package:expense_tracker/core/theme/app_theme.dart'; // For aether icons maybe

class IncomeCard extends StatelessWidget {
  final Income income;
  final VoidCallback? onTap;

  const IncomeCard({
    super.key,
    required this.income,
    this.onTap,
  });

  // --- Placeholder for Aether Icons ---
  IconData _getAetherIncomeIcon(String categoryName, String themeId) {
    // TODO: Implement logic to return specific Aether icons based on themeId and category
    // Example:
    // if (themeId == AppTheme.aetherGardenThemeId) {
    //    if (categoryName.toLowerCase() == 'salary') return Icons.water_drop; // Placeholder raindrop
    // }
    return Icons.arrow_upward; // Fallback to default elemental icon
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
    final double iconSize = isQuantum ? 18 : 22;
    final double spacing = isQuantum ? 10.0 : 16.0;
    final TextStyle? titleStyle = isQuantum
        ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)
        : theme.textTheme.titleMedium;
    final TextStyle? amountStyle = isQuantum
        ? theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500, color: Colors.green.shade700)
        : theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold, color: Colors.green.shade700);
    final IconData displayIcon = isAether
        ? _getAetherIncomeIcon(
            income.category.name, settingsState.selectedThemeIdentifier)
        : Icons.arrow_upward;

    // Account Name - Fetching handled in IncomeListPage's BlocBuilder now
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

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon for Income
              CircleAvatar(
                backgroundColor: isAether
                    ? theme.colorScheme.tertiaryContainer
                    : Colors.green.shade100,
                child: Icon(displayIcon,
                    color: isAether
                        ? theme.colorScheme.onTertiaryContainer
                        : Colors.green.shade800,
                    size: iconSize),
              ),
              SizedBox(width: spacing),
              // Title, Category, Date, Notes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(income.title,
                        style: titleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: isQuantum ? 0 : 2),
                    Text(
                      // Show category and account name (conditionally)
                      '${income.category.name} ${isQuantum ? "" : "• $accountName"}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isQuantum ? 0 : 2),
                    Text(
                      // Show date
                      isQuantum
                          ? DateFormatter.formatDate(income.date)
                          : DateFormatter.formatDateTime(income.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.8)),
                    ),
                    // Display notes if available (maybe hide in Quantum?)
                    if (!isQuantum &&
                        income.notes != null &&
                        income.notes!.isNotEmpty)
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
              SizedBox(width: spacing),
              // Amount
              Text(
                CurrencyFormatter.format(income.amount, currencySymbol),
                style: amountStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
