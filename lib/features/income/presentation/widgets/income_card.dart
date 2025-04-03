// lib/features/income/presentation/widgets/income_card.dart
// FINAL VERSION (with conceptual UI changes for categorization)
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/core/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/main.dart';
// Need TransactionMatchData for user categorization event
import 'package:expense_tracker/features/categories/domain/usecases/save_user_categorization_history.dart';

class IncomeCard extends StatelessWidget {
  final Income income;
  // Callbacks for interaction
  final Function(Income income)? onCardTap; // For navigating to details
  final Function(Income income, Category selectedCategory)?
      onUserCategorized; // When user confirms/sets category
  final Function(Income income)? onChangeCategoryRequest; // Request to open MCI

  const IncomeCard({
    super.key,
    required this.income,
    this.onCardTap,
    this.onUserCategorized,
    this.onChangeCategoryRequest,
  });

  // Helper to get icon data or path based on category and theme
  Widget _buildIcon(BuildContext context, AppModeTheme? modeTheme) {
    final theme = Theme.of(context);
    final category = income.category ?? Category.uncategorized;
    IconData fallbackIcon = Icons.attach_money;
    try {
      fallbackIcon = _getElementalIncomeCategoryIcon(category.name);
    } catch (_) {/* ignore */}

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

  // Fallback IconData mapping
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
      case 'uncategorized':
        return Icons.help_outline;
      default:
        return Icons.attach_money;
    }
  }

  // Helper to build status indicator OR action buttons
  Widget _buildStatusUI(BuildContext context) {
    final theme = Theme.of(context);
    final textStyleSmall =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final Color primaryColor = theme.colorScheme.primary;
    final Color errorColor = theme.colorScheme.error;
    final Color successColor = Colors.green.shade600;
    final Color warningColor = Colors.orange.shade800;

    switch (income.status) {
      case CategorizationStatus.needsReview:
        // --- Conceptual Suggestion Prompt UI ---
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4.0,
          runSpacing: 2.0,
          children: [
            Icon(Icons.help_outline_rounded, size: 16, color: warningColor),
            Text('Suggest: ${income.category?.name ?? "?"}',
                style: textStyleSmall.copyWith(
                    color: warningColor, fontStyle: FontStyle.italic)),
            Tooltip(
              message: "Confirm Category",
              child: InkWell(
                onTap: () {
                  log.info(
                      "[IncomeCard] Suggestion confirmed for ${income.id}");
                  if (income.category != null && onUserCategorized != null) {
                    // TODO: Get actual merchant ID if available (unlikely for income)
                    final matchData = TransactionMatchData(
                        description: income.title, merchantId: null);
                    onUserCategorized!(income, income.category!);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 2.0, vertical: 1.0),
                  child: Icon(Icons.check_circle_outline,
                      size: 20, color: successColor),
                ),
              ),
            ),
            Tooltip(
              message: "Change Category",
              child: InkWell(
                  onTap: () {
                    log.info(
                        "[IncomeCard] Change requested for suggested ${income.id}");
                    onChangeCategoryRequest?.call(income);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 2.0, vertical: 1.0),
                    child: Icon(Icons.edit_outlined,
                        size: 18, color: primaryColor),
                  )),
            ),
          ],
        );
      // --- End Prompt ---
      case CategorizationStatus.uncategorized:
        return InkWell(
            onTap: () {
              log.info(
                  "[IncomeCard] Change requested for uncategorized ${income.id}");
              onChangeCategoryRequest?.call(income);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.label_off_outlined, size: 16, color: errorColor),
                const SizedBox(width: 4),
                Text('Categorize',
                    style: textStyleSmall.copyWith(color: errorColor)),
              ],
            ));
      case CategorizationStatus.categorized:
      default:
        return Text(
          // Display category name, tappable to change
          income.category?.name ?? Category.uncategorized.name,
          style: textStyleSmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final modeTheme = context.modeTheme;
    final category = income.category ?? Category.uncategorized;

    final accountState = context.watch<AccountListBloc>().state;
    String accountName = '...';
    if (accountState is AccountListLoaded) {
      /* ... account lookup ... */
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
      onTap: () => onCardTap?.call(income), // Overall card tap
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
                // --- Status/Category Interaction Area ---
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
                // --- End Status/Category ---
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
          // Amount column
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
              // Add confidence score for debugging/info if needed
              // if (income.confidenceScore != null)
              //    Text('Conf: ${income.confidenceScore!.toStringAsFixed(2)}', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey))
            ],
          ),
        ],
      ),
    );
  }
}
