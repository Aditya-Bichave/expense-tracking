// lib/features/expenses/presentation/widgets/expense_card.dart
// FINAL VERSION (with conceptual UI changes for categorization)
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
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
// Need TransactionMatchData for user categorization event
import 'package:expense_tracker/features/categories/domain/usecases/save_user_categorization_history.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  // Callbacks for interaction
  final Function(Expense expense)? onCardTap; // For navigating to details
  final Function(Expense expense, Category selectedCategory)?
      onUserCategorized; // When user confirms/sets category
  final Function(Expense expense)?
      onChangeCategoryRequest; // Request to open MCI

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onCardTap,
    this.onUserCategorized,
    this.onChangeCategoryRequest,
  });

  // Helper to get icon data or path based on category and theme
  Widget _buildIcon(BuildContext context, AppModeTheme? modeTheme) {
    final theme = Theme.of(context);
    final category = expense.category ?? Category.uncategorized;
    IconData fallbackIcon = Icons.label_outline;
    try {
      fallbackIcon = _getElementalCategoryIcon(category.name);
    } catch (_) {/* ignore */}

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

  // Fallback IconData mapping
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

    switch (expense.status) {
      case CategorizationStatus.needsReview:
        // --- Suggestion Prompt UI ---
        return Wrap(
          // Use Wrap for responsiveness
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4.0, // Spacing between elements
          runSpacing: 2.0, // Spacing if it wraps
          children: [
            Icon(Icons.help_outline_rounded, size: 16, color: warningColor),
            Text('Suggest: ${expense.category?.name ?? "?"}',
                style: textStyleSmall.copyWith(
                    color: warningColor, fontStyle: FontStyle.italic)),
            // Using Tooltip for accessibility on InkWell/IconButton
            Tooltip(
              message: "Confirm Category",
              child: InkWell(
                onTap: () {
                  log.info(
                      "[ExpenseCard] Suggestion confirmed for ${expense.id}");
                  if (expense.category != null && onUserCategorized != null) {
                    // TODO: Get actual merchant ID if available
                    final matchData = TransactionMatchData(
                        description: expense.title, merchantId: null);
                    onUserCategorized!(expense, expense.category!);
                  }
                },
                child: Padding(
                  // Add padding for easier tapping
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
                        "[ExpenseCard] Change requested for suggested ${expense.id}");
                    onChangeCategoryRequest?.call(expense);
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
                  "[ExpenseCard] Change requested for uncategorized ${expense.id}");
              onChangeCategoryRequest?.call(expense);
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
          expense.category?.name ?? Category.uncategorized.name,
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

    // Use AppCard tap for main action (details), InkWell inside for category changes
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
                const SizedBox(height: 4), // Increase spacing slightly
                // --- Status/Category Interaction Area ---
                InkWell(
                  // Allow tapping categorized text to trigger change request
                  onTap: (expense.status == CategorizationStatus.categorized)
                      ? () {
                          log.info(
                              "[ExpenseCard] Change requested for categorized ${expense.id}");
                          onChangeCategoryRequest?.call(expense);
                        }
                      : null, // onTap handled by nested InkWells for prompt/uncategorized
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
                Text(DateFormatter.formatDateTime(expense.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withOpacity(0.8))),
              ],
            ),
          ),
          SizedBox(
              width: modeTheme?.listItemPadding.right ??
                  8), // Reduce spacing before amount
          // Amount column for alignment
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
              // Add confidence score for debugging/info if needed
              // if (expense.confidenceScore != null)
              //    Text('Conf: ${expense.confidenceScore!.toStringAsFixed(2)}', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey))
            ],
          ),
        ],
      ),
    );
  }
}
