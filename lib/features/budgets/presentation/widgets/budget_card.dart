// lib/features/budgets/presentation/widgets/budget_card.dart
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart'; // For TransactionType
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull

class BudgetCard extends StatelessWidget {
  final BudgetWithStatus budgetStatus;
  final VoidCallback? onTap;

  const BudgetCard({
    super.key,
    required this.budgetStatus,
    this.onTap,
  });

  // Helper to get category icons for display
  List<Widget> _getCategoryIconWidgets(BuildContext context, Budget budget) {
    if (budget.type != BudgetType.categorySpecific ||
        budget.categoryIds == null ||
        budget.categoryIds!.isEmpty) {
      return [];
    }
    final categoryState = context.read<CategoryManagementBloc>().state;
    final modeTheme = context.modeTheme;
    List<Widget> iconWidgets = [];

    if (categoryState.status == CategoryManagementStatus.loaded) {
      final allCategories = [
        ...categoryState.allExpenseCategories,
        ...categoryState
            .allIncomeCategories // Include income just in case for lookup, though budget uses expense
      ];
      int count = 0;
      for (String id in budget.categoryIds!) {
        if (count >= 3) break; // Limit to 3 icons
        final category = allCategories.firstWhereOrNull((c) => c.id == id);
        // Use the uncategorized helper method with the correct type
        if (category != null && category.id != Category.uncategorized.id) {
          final iconColor = category.displayColor;
          Widget iconWidget;
          IconData fallbackIcon =
              availableIcons[category.iconName] ?? Icons.label;

          if (modeTheme != null) {
            String svgPath = modeTheme.assets
                .getCategoryIcon(category.iconName, defaultPath: '');
            if (svgPath.isNotEmpty) {
              iconWidget = SvgPicture.asset(
                svgPath,
                width: 14,
                height: 14,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              );
            } else {
              iconWidget = Icon(fallbackIcon, size: 14, color: iconColor);
            }
          } else {
            iconWidget = Icon(fallbackIcon, size: 14, color: iconColor);
          }

          iconWidgets.add(Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Tooltip(message: category.name, child: iconWidget),
          ));
          count++;
        }
      }
      if (budget.categoryIds!.length > 3) {
        iconWidgets.add(Text('+${budget.categoryIds!.length - 3}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)));
      }
    }
    return iconWidgets;
  }

  // Helper for Progress Bar based on UI Mode
  Widget _buildProgressBar(
      BuildContext context, AppModeTheme? modeTheme, UIMode uiMode) {
    final theme = Theme.of(context);
    final percentage = budgetStatus.percentageUsed.clamp(0.0, 1.0);
    final color = budgetStatus.statusColor;
    final bool isQuantum = uiMode == UIMode.quantum;

    if (isQuantum) {
      // Quantum: Minimalist bar, no text inside
      return LinearPercentIndicator(
        padding: EdgeInsets.zero,
        lineHeight: 6.0,
        percent: percentage,
        barRadius: const Radius.circular(3),
        backgroundColor:
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        progressColor: color,
        animation: false,
      );
    } else {
      // Elemental / Aether (Default Style)
      return LinearPercentIndicator(
        animation: true,
        animationDuration: 600,
        lineHeight: 16.0,
        percent: percentage,
        center: Text(
          "${(budgetStatus.percentageUsed * 100).toStringAsFixed(0)}%",
          style: TextStyle(
              color: color.computeLuminance() > 0.5
                  ? Colors.black87
                  : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10),
        ),
        barRadius: const Radius.circular(8),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        progressColor: color,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currency = settings.currencySymbol;
    final uiMode = settings.uiMode;
    final modeTheme = context.modeTheme;
    final budget = budgetStatus.budget;
    final categoryIcons = _getCategoryIconWidgets(context, budget);

    final cardMargin = modeTheme?.cardOuterPadding ??
        const EdgeInsets.symmetric(horizontal: 12, vertical: 5);
    final cardPadding =
        modeTheme?.cardInnerPadding ?? const EdgeInsets.all(12.0);

    return AppCard(
      onTap: onTap,
      margin: cardMargin,
      padding: cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name and Period
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(budget.name,
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis),
                    if (categoryIcons.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(children: categoryIcons),
                      )
                    else if (budget.type == BudgetType.overall)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('Overall Spending',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: theme.colorScheme.secondary)),
                      )
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                budget.period == BudgetPeriodType.recurringMonthly
                    ? 'Monthly'
                    : 'One-Time',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              )
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar & Amounts
          _buildProgressBar(context, modeTheme, uiMode),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${CurrencyFormatter.format(budgetStatus.amountSpent, currency)}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: budgetStatus.statusColor),
              ),
              Text(
                'Target: ${CurrencyFormatter.format(budget.targetAmount, currency)}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                budgetStatus.amountRemaining >= 0
                    ? '${CurrencyFormatter.format(budgetStatus.amountRemaining, currency)} left'
                    : '${CurrencyFormatter.format(budgetStatus.amountRemaining.abs(), currency)} over',
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: budgetStatus.amountRemaining >= 0
                        ? theme.colorScheme.primary
                        : budgetStatus.statusColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
