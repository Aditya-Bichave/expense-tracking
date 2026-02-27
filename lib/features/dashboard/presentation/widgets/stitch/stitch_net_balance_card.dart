// lib/features/dashboard/presentation/widgets/stitch/stitch_net_balance_card.dart
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'dart:ui';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart'; // Import AppCard (though we might use Container for custom style)
import 'package:expense_tracker/ui_bridge/bridge_text.dart';

class StitchNetBalanceCard extends StatelessWidget {
  final FinancialOverview overview;

  const StitchNetBalanceCard({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final kit = context.kit;

    double totalBudget = 0;
    double totalSpent = 0;
    for (var b in overview.activeBudgetsSummary) {
      totalBudget += b.budget.targetAmount;
      totalSpent += b.amountSpent;
    }
    double progress = totalBudget > 0
        ? (totalSpent / totalBudget).clamp(0.0, 1.0)
        : 0.0;

    // Heavily customized card, keeping structure but using tokens
    return Container(
      // Fixed: Removed .horizontal accessor on double
      margin: kit.spacing.vSm.copyWith(
        left: kit.spacing.lg,
        right: kit.spacing.lg,
      ),
      height: 220,
      decoration: BoxDecoration(
        color: kit.colors.surface,
        borderRadius: kit.radii.card, // Using card radius from token
        border: Border.all(color: kit.colors.primary.withOpacity(0.1)),
        boxShadow: kit
            .shadows
            .lg, // Using large shadow token if available, or approximated
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: kit.colors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Padding(
            padding: kit.spacing.allXl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BridgeText(
                  'NET BALANCE',
                  style: kit.typography.overline.copyWith(
                    color: kit.colors.textSecondary,
                  ),
                ),
                kit.spacing.gapXs,
                BridgeText(
                  CurrencyFormatter.format(
                    overview.overallBalance,
                    currencySymbol,
                  ),
                  style: kit.typography.display.copyWith(
                    color: kit.colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
                kit.spacing.gapXl,
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BridgeText(
                            'MONTHLY INCOME',
                            style: kit.typography.overline.copyWith(
                              color: kit.colors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                          kit.spacing.gapXs,
                          BridgeText(
                            '+${CurrencyFormatter.format(overview.totalIncome, currencySymbol)}',
                            style: kit.typography.title.copyWith(
                              color: kit.colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: kit.colors.borderSubtle.withOpacity(0.2),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: kit.spacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BridgeText(
                              'MONTHLY SPEND',
                              style: kit.typography.overline.copyWith(
                                color: kit.colors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                            kit.spacing.gapXs,
                            BridgeText(
                              '-${CurrencyFormatter.format(overview.totalExpenses, currencySymbol)}',
                              style: kit.typography.title.copyWith(
                                color: kit.colors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    BridgeText(
                      'Budget Progress',
                      style: kit.typography.bodySmall.copyWith(
                        color: kit.colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        text: '${(progress * 100).toInt()}%',
                        style: kit.typography.bodySmall.copyWith(
                          color: kit.colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text:
                                ' (${CurrencyFormatter.format(totalSpent, currencySymbol)} / ${CurrencyFormatter.format(totalBudget, currencySymbol)})',
                            style: TextStyle(
                              color: kit.colors.textSecondary,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                kit.spacing.gapSm,
                ClipRRect(
                  borderRadius: kit.radii.small,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: kit.colors.surfaceContainer,
                    color: kit.colors.primary,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
