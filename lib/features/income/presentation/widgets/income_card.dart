// lib/features/income/presentation/widgets/income_card.dart
// MODIFIED FILE (Implement interactive prompts)

import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/core/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/features/categories/domain/usecases/save_user_categorization_history.dart';

class IncomeCard extends StatelessWidget {
  final Income income;
  final Function(Income income)? onCardTap;
  final Function(Income income, Category selectedCategory)? onUserCategorized;
  final Function(Income income)? onChangeCategoryRequest;

  const IncomeCard({
    super.key,
    required this.income,
    this.onCardTap,
    this.onUserCategorized,
    this.onChangeCategoryRequest,
  });

  Widget _buildIcon(BuildContext context, AppModeTheme? modeTheme) {
    /* ... Same as before ... */
    final theme = Theme.of(context);
    final category = income.category ?? Category.uncategorized;
    IconData fallbackIcon = Icons.attach_money;
    try {
      fallbackIcon = _getElementalIncomeCategoryIcon(category.name);
    } catch (_) {}
    log.info(
        "[IncomeCard] Building icon for category '${category.name}' (IconName: ${category.iconName})");
    if (modeTheme != null) {
      String svgPath =
          modeTheme.assets.getCategoryIcon(category.iconName, defaultPath: '');
      if (svgPath.isNotEmpty) {
        log.info("[IncomeCard] Using SVG: $svgPath");
        return SvgPicture.asset(
          svgPath,
          width: 22,
          height: 22,
          colorFilter: ColorFilter.mode(category.displayColor, BlendMode.srcIn),
        );
      }
    }
    log.info("[IncomeCard] Falling back to IconData: $fallbackIcon");
    return Icon(fallbackIcon, size: 22, color: category.displayColor);
  }

  IconData _getElementalIncomeCategoryIcon(String categoryName) {
    /* ... Same as before ... */
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
      case 'uncategorized':
        return Icons.help_outline;
      default:
        return Icons.attach_money;
    }
  }

  // Helper to build status indicator OR action buttons (Similar to ExpenseCard)
  Widget _buildStatusUI(BuildContext context) {
    final theme = Theme.of(context);
    final textStyleSmall =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final Color primaryColor = theme.colorScheme.primary;
    final Color errorColor = theme.colorScheme.error;
    final Color successColor = Colors.green.shade600;
    final Color warningColor = Colors.orange.shade800;
    final EdgeInsets buttonPadding =
        const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0);
    final Size buttonMinSize = const Size(28, 28);

    switch (income.status) {
      case CategorizationStatus.needsReview:
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6.0,
          runSpacing: 4.0,
          children: [
            Icon(Icons.help_outline_rounded, size: 16, color: warningColor),
            Text('Suggest: ${income.category?.name ?? "?"}',
                style: textStyleSmall.copyWith(
                    color: warningColor, fontStyle: FontStyle.italic)),
            SizedBox(
              height: 28,
              child: OutlinedButton.icon(
                icon: Icon(Icons.check, size: 16, color: successColor),
                label: Text("Confirm",
                    style: textStyleSmall.copyWith(color: successColor)),
                style: OutlinedButton.styleFrom(
                  padding: buttonPadding,
                  minimumSize: buttonMinSize,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: successColor.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  log.info(
                      "[IncomeCard] Suggestion confirmed for ${income.id}");
                  if (income.category != null && onUserCategorized != null) {
                    final matchData = TransactionMatchData(
                        description: income.title, merchantId: null);
                    onUserCategorized!(income, income.category!);
                  }
                },
              ),
            ),
            SizedBox(
              height: 28,
              child: TextButton.icon(
                icon: Icon(Icons.edit_outlined, size: 16, color: primaryColor),
                label: Text("Change",
                    style: textStyleSmall.copyWith(color: primaryColor)),
                style: TextButton.styleFrom(
                  padding: buttonPadding,
                  minimumSize: buttonMinSize,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  log.info(
                      "[IncomeCard] Change requested for suggested ${income.id}");
                  onChangeCategoryRequest?.call(income);
                },
              ),
            ),
          ],
        );
      case CategorizationStatus.uncategorized:
        return TextButton.icon(
          icon: Icon(Icons.label_off_outlined, size: 16, color: errorColor),
          label: Text('Categorize',
              style: textStyleSmall.copyWith(color: errorColor)),
          style: TextButton.styleFrom(
            padding: buttonPadding,
            minimumSize: buttonMinSize,
            visualDensity: VisualDensity.compact,
          ),
          onPressed: () {
            log.info(
                "[IncomeCard] Change requested for uncategorized ${income.id}");
            onChangeCategoryRequest?.call(income);
          },
        );
      case CategorizationStatus.categorized:
      default:
        return InkWell(
          onTap: () {
            log.info(
                "[IncomeCard] Change requested for categorized ${income.id}");
            onChangeCategoryRequest?.call(income);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  income.category?.name ?? Category.uncategorized.name,
                  style: textStyleSmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Rest of build method remains the same, calling _buildStatusUI) ...
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final modeTheme = context.modeTheme;
    final category = income.category ?? Category.uncategorized;
    final accountState = context.watch<AccountListBloc>().state;
    String accountName = '...';
    if (accountState is AccountListLoaded) {
      try {
        accountName = accountState.items
            .firstWhere((acc) => acc.id == income.accountId)
            .name;
      } catch (_) {
        accountName = 'Deleted';
      }
    } else if (accountState is AccountListError) {
      accountName = 'Error';
    }
    final Color incomeAmountColor =
        modeTheme?.incomeGlowColor ?? Colors.green.shade700;
    return AppCard(
      onTap: () => onCardTap?.call(income),
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
                Text(income.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                InkWell(
                  onTap: (income.status == CategorizationStatus.categorized)
                      ? () {
                          log.info(
                              "[IncomeCard] Change requested for categorized ${income.id}");
                          onChangeCategoryRequest?.call(income);
                        }
                      : null,
                  child: _buildStatusUI(context),
                ),
                const SizedBox(height: 2),
                Text('Acc: $accountName',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withOpacity(0.8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(DateFormatter.formatDateTime(income.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withOpacity(0.8))),
                if (income.notes != null && income.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Icon(Icons.notes_outlined,
                            size: 14,
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(income.notes!,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontStyle: FontStyle.italic),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                      ],
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
                    fontWeight: FontWeight.bold, color: incomeAmountColor),
                child: Text(
                    CurrencyFormatter.format(income.amount, currencySymbol)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
