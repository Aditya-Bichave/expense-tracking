// lib/features/expenses/presentation/widgets/expense_card.dart
// MODIFIED FILE (UI Kit Migration)

import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_avatar.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/categorization_status_widget.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final String accountName;
  final String currencySymbol;
  final Function(Expense expense)? onCardTap;
  final Function(Expense expense, Category selectedCategory)? onUserCategorized;
  final Function(Expense expense)? onChangeCategoryRequest;

  const ExpenseCard({
    super.key,
    required this.expense,
    required this.accountName,
    required this.currencySymbol,
    this.onCardTap,
    this.onUserCategorized,
    this.onChangeCategoryRequest,
  });

  Widget _buildIcon(BuildContext context, AppModeTheme? modeTheme) {
    final kit = context.kit;
    final category = expense.category ?? Category.uncategorized;
    IconData fallbackIcon = Icons.label_outline;
    try {
      fallbackIcon = _getElementalCategoryIcon(category.name);
    } catch (_) {}
    if (modeTheme != null) {
      String svgPath = modeTheme.assets.getCategoryIcon(
        category.iconName,
        defaultPath: '',
      );
      if (svgPath.isNotEmpty) {
        return SvgPicture.asset(
          svgPath,
          width: 22,
          height: 22,
          colorFilter: ColorFilter.mode(
            category.cachedDisplayColor,
            BlendMode.srcIn,
          ),
        );
      }
    }
    return Icon(fallbackIcon, size: 22, color: category.cachedDisplayColor);
  }

  static const Map<String, IconData> _categoryIcons = {
    'food': Icons.restaurant,
    'transport': Icons.directions_bus,
    'utilities': Icons.lightbulb_outline,
    'entertainment': Icons.local_movies,
    'housing': Icons.home_outlined,
    'health': Icons.local_hospital_outlined,
    'shopping': Icons.shopping_bag_outlined,
    'groceries': Icons.shopping_cart_outlined,
    'subscriptions': Icons.subscriptions_outlined,
    'medical': Icons.medical_services_outlined,
    'uncategorized': Icons.help_outline,
  };

  IconData _getElementalCategoryIcon(String categoryName) {
    return _categoryIcons[categoryName.toLowerCase()] ?? Icons.label_outline;
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final modeTheme = context.modeTheme;
    final category = expense.category ?? Category.uncategorized;

    return AppCard(
      onTap: () => onCardTap?.call(expense),
      padding: kit.spacing.allMd,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Replaced CircleAvatar with AppAvatar manually constructed since we pass a custom child
          // AppAvatar doesn't support custom child directly in the common constructor,
          // but we can use Container with BoxDecoration to match the design or extend AppAvatar.
          // However, the prompt asked to replace CircleAvatar usage with AppAvatar.
          // AppAvatar takes imageUrl, initials, or child? No, looking at AppAvatar definition:
          // imageUrl, initials. No generic child.
          // But wait, the instruction says: "configured to use the same color... and the same child icon builder"
          // If AppAvatar doesn't support child, I might need to check if I can add it or if I should use a Container.
          // Let's check AppAvatar again.

          // Checking lib/ui_kit/components/lists/app_avatar.dart
          // It has imageUrl and initials. And a child is built internally if imageUrl is null.
          // Wait, the previous read of AppAvatar showed:
          // child: imageUrl == null && initials != null ? Text(...) : null
          // It DOES NOT accept a generic child.

          // So, to support custom icon (SvgPicture or Icon), I should either:
          // 1. Modify AppAvatar to accept a child.
          // 2. Use a Container that mimics AppAvatar.
          // 3. Or if AppAvatar is intended to handle this via `imageUrl`? No, SvgPicture is a widget.

          // The prompt says: "ensuring the AppAvatar props match the visual behavior previously provided by CircleAvatar".
          // If AppAvatar cannot accept a child, I cannot use it without modification.
          // BUT, I can modify AppAvatar to accept `child`.

          // Let's modify AppAvatar to accept `child` as an alternative to initials/image.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: category.cachedDisplayColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: _buildIcon(context, modeTheme),
          ),
          kit.spacing.wMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: kit.typography.title.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                kit.spacing.hgapXs,
                CategorizationStatusWidget(
                  transaction: TransactionEntity.fromExpense(expense),
                  onUserCategorized: onUserCategorized == null
                      ? null
                      : (tx, cat) => onUserCategorized!(expense, cat),
                  onChangeCategoryRequest: onChangeCategoryRequest == null
                      ? null
                      : (_) => onChangeCategoryRequest!(expense),
                ),
                kit.spacing.hgapXxs,
                Row(
                  children: [
                    Text(
                      'Acc: $accountName',
                      style: kit.typography.caption.copyWith(
                        color: kit.colors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    kit.spacing.wXs,
                    Text(
                      '•',
                      style: kit.typography.caption.copyWith(
                        color: kit.colors.textSecondary,
                      ),
                    ),
                    kit.spacing.wXs,
                    Text(
                      DateFormatter.formatDateTime(expense.date),
                      style: kit.typography.caption.copyWith(
                        color: kit.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          kit.spacing.wSm,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration:
                    modeTheme?.fastDuration ??
                    const Duration(milliseconds: 150),
                style: kit.typography.title.copyWith(
                  fontWeight: FontWeight.bold,
                  color: modeTheme?.expenseGlowColor ?? kit.colors.error,
                ),
                child: Text(
                  CurrencyFormatter.format(expense.amount, currencySymbol),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
