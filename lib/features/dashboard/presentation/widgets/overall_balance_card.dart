// lib/features/dashboard/presentation/widgets/overall_balance_card.dart
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_bridge/bridge_text.dart';

class OverallBalanceCard extends StatelessWidget {
  final FinancialOverview overview;

  const OverallBalanceCard({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final kit = context.kit;

    // Determine color based on balance
    final balanceColor = overview.overallBalance >= 0
        ? kit
              .colors
              .primary // Use primary color for positive balance
        : kit.colors.error; // Use error color for negative balance

    return AppCard(
      elevation: 2,
      margin: kit.spacing.vSm, // Add vertical margin
      color: kit.colors.surfaceContainer, // Use a distinct surface color
      padding: kit.spacing.allLg, // Increase vertical padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BridgeText(
            'Overall Balance',
            style: kit.typography.title.copyWith(
              color: kit.colors.textSecondary,
            ),
          ),
          kit.spacing.gapSm,
          BridgeText(
            CurrencyFormatter.format(overview.overallBalance, currencySymbol),
            style: kit.typography.display.copyWith(
              // Make balance stand out
              fontWeight: FontWeight.bold,
              color: balanceColor,
              fontSize:
                  32, // Manually keeping size closer to headlineMedium for now, or use displaySmall
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Optionally add Net Flow below
          kit.spacing.gapSm,
          Row(
            children: [
              BridgeText(
                'Net Flow (Period): ',
                style: kit.typography.bodySmall.copyWith(
                  color: kit.colors.textSecondary,
                ),
              ),
              BridgeText(
                CurrencyFormatter.format(overview.netFlow, currencySymbol),
                style: kit.typography.bodySmall.copyWith(
                  color: overview.netFlow >= 0
                      ? kit.colors.success
                      : kit.colors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
