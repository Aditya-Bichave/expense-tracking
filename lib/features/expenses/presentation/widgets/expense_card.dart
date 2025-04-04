// lib/features/expenses/presentation/widgets/expense_card.dart
// MODIFIED FILE (Implement interactive prompts)

import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/core/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/features/categories/domain/usecases/save_user_categorization_history.dart';

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
    final theme = Theme.of(context);
    final category = expense.category ?? Category.uncategorized;
    IconData fallbackIcon = Icons.label_outline;
    try {
      fallbackIcon = _getElementalCategoryIcon(category.name);
    } catch (_) {}
    log.info(
        "[ExpenseCard] Building icon for category '${category.name}' (IconName: ${category.iconName})");
    if (modeTheme != null) {
      String svgPath =
          modeTheme.assets.getCategoryIcon(category.iconName, defaultPath: '');
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

  // Helper to build status indicator OR action buttons
  Widget _buildStatusUI(BuildContext context) {
    final theme = Theme.of(context);
    final textStyleSmall =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final Color primaryColor = theme.colorScheme.primary;
    final Color errorColor = theme.colorScheme.error;
    final Color successColor = Colors.green.shade600;
    final Color warningColor = Colors.orange.shade800;
    final EdgeInsets buttonPadding = const EdgeInsets.symmetric(
        horizontal: 6.0, vertical: 2.0); // Padding for buttons
    final Size buttonMinSize =
        const Size(28, 28); // Minimum size for tap targets

    switch (expense.status) {
      case CategorizationStatus.needsReview:
        // --- Interactive Suggestion Prompt UI ---
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6.0, // Increased spacing
          runSpacing: 4.0,
          children: [
            Icon(Icons.help_outline_rounded, size: 16, color: warningColor),
            Text('Suggest: ${expense.category?.name ?? "?"}',
                style: textStyleSmall.copyWith(
                    color: warningColor, fontStyle: FontStyle.italic)),
            // Confirm Button (using OutlinedButton for clearer boundary)
            SizedBox(
              // Constrain button size
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
                      "[ExpenseCard] Suggestion confirmed for ${expense.id}");
                  if (expense.category != null && onUserCategorized != null) {
                    final matchData = TransactionMatchData(
                        description: expense.title,
                        merchantId: null); // TODO: merchantId
                    onUserCategorized!(expense, expense.category!);
                  }
                },
              ),
            ),
            // Change Button (using TextButton for less emphasis)
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
                      "[ExpenseCard] Change requested for suggested ${expense.id}");
                  onChangeCategoryRequest?.call(expense);
                },
              ),
            ),
          ],
        );
      // --- End Prompt ---
      case CategorizationStatus.uncategorized:
        // --- Interactive Uncategorized Button ---
        return TextButton.icon(
          icon: Icon(Icons.label_off_outlined, size: 16, color: errorColor),
          label: Text('Categorize',
              style: textStyleSmall.copyWith(color: errorColor)),
          style: TextButton.styleFrom(
            padding: buttonPadding, minimumSize: buttonMinSize,
            visualDensity: VisualDensity.compact,
            // Add a subtle border maybe?
            // side: BorderSide(color: errorColor.withOpacity(0.3))
          ),
          onPressed: () {
            log.info(
                "[ExpenseCard] Change requested for uncategorized ${expense.id}");
            onChangeCategoryRequest?.call(expense);
          },
        );
      // --- End Button ---
      case CategorizationStatus.categorized:
      default:
        // Tappable Category Name
        return InkWell(
          onTap: () {
            log.info(
                "[ExpenseCard] Change requested for categorized ${expense.id}");
            onChangeCategoryRequest?.call(expense);
          },
          child: Row(
            // Wrap in row to allow potential future edit icon next to text
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                // Allow text to wrap/ellipsis if needed
                child: Text(
                  expense.category?.name ?? Category.uncategorized.name,
                  style: textStyleSmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Optional: Add small edit icon here
              // Icon(Icons.edit, size: 12, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7))
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
                Text(expense.title,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                _buildStatusUI(context),
                const SizedBox(height: 2),
                Text('Acc: $accountName',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withOpacity(0.8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(DateFormatter.formatDateTime(expense.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withOpacity(0.8))),
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
                    CurrencyFormatter.format(expense.amount, currencySymbol)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
