import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/categorization_status_widget.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_avatar.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IncomeCard extends StatelessWidget {
  final Income income;
  final String accountName;
  final String currencySymbol;
  final Function(Income income)? onCardTap;
  final Function(Income income, Category selectedCategory)? onUserCategorized;
  final Function(Income income)? onChangeCategoryRequest;

  const IncomeCard({
    super.key,
    required this.income,
    required this.accountName,
    required this.currencySymbol,
    this.onCardTap,
    this.onUserCategorized,
    this.onChangeCategoryRequest,
  });

  Widget _buildIcon(BuildContext context, AppModeTheme? modeTheme) {
    /* ... Same as before ... */
    Theme.of(context);
    final category = income.category ?? Category.uncategorized;
    IconData fallbackIcon = Icons.attach_money;
    try {
      fallbackIcon = _getElementalIncomeCategoryIcon(category.name);
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
          colorFilter: ColorFilter.mode(category.displayColor, BlendMode.srcIn),
        );
      }
    }
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

  // Removed _buildStatusUI, replaced by CategorizationStatusWidget

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;
    final category = income.category ?? Category.uncategorized;

    final Color incomeAmountColor =
        modeTheme?.incomeGlowColor ?? Colors.green.shade700;
    return AppCard(
      onTap: () => onCardTap?.call(income),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppAvatar(
            backgroundColor: category.displayColor.withOpacity(0.15),
            child: _buildIcon(context, modeTheme),
          ),
          SizedBox(width: context.kit.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  income.title,
                  style: context.kit.typography.headline.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                CategorizationStatusWidget(
                  transaction: TransactionEntity.fromIncome(income),
                  onUserCategorized: onUserCategorized == null
                      ? null
                      : (tx, cat) => onUserCategorized!(income, cat),
                  onChangeCategoryRequest: onChangeCategoryRequest == null
                      ? null
                      : (_) => onChangeCategoryRequest!(income),
                ),
                const SizedBox(height: 2),
                Text(
                  'Acc: $accountName',
                  style: context.kit.typography.caption.copyWith(
                    color: context.kit.colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormatter.formatDateTime(income.date),
                  style: context.kit.typography.caption.copyWith(
                    color: context.kit.colors.textSecondary,
                  ),
                ),
                if (income.notes != null && income.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notes_outlined,
                          size: 14,
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            income.notes!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
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
          SizedBox(width: modeTheme?.listItemPadding.right ?? 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration:
                    modeTheme?.fastDuration ??
                    const Duration(milliseconds: 150),
                style: context.kit.typography.headline.copyWith(
                  fontWeight: FontWeight.bold,
                  color: incomeAmountColor,
                ),
                child: Text(
                  CurrencyFormatter.format(income.amount, currencySymbol),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
