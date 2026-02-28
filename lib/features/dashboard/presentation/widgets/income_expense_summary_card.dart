// lib/features/dashboard/presentation/widgets/income_expense_summary_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_bridge/bridge_text.dart';
import 'package:expense_tracker/ui_bridge/bridge_card.dart';

class IncomeExpenseSummaryCard extends StatelessWidget {
  final FinancialOverview overview;

  const IncomeExpenseSummaryCard({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final kit = context.kit;

    return AppCard(
      elevation: 2,
      margin: kit.spacing.vSm, // Add vertical margin
      padding: kit.spacing.allLg, // Increase vertical padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryColumn(
            context: context,
            title: 'Income', // Simpler title
            amount: overview.totalIncome,
            color: kit.colors.success, // Consistent green
            icon: Icons.arrow_circle_up_outlined, // Different icon
            currencySymbol: currencySymbol,
            kit: kit,
          ),
          // Vertical divider for separation
          Container(
            height: 50, // Adjust height as needed
            width: 1,
            color: kit.colors.borderSubtle,
          ),
          _buildSummaryColumn(
            context: context,
            title: 'Expenses', // Simpler title
            amount: overview.totalExpenses,
            color: kit.colors.error, // Use theme error color
            icon: Icons.arrow_circle_down_outlined, // Different icon
            currencySymbol: currencySymbol,
            kit: kit,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryColumn({
    required BuildContext context,
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required String? currencySymbol,
    required AppKitTheme kit,
  }) {
    return Expanded(
      // Allow columns to expand equally
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Center align content
        children: [
          Row(
            // Keep icon and title together
            mainAxisSize:
                MainAxisSize.min, // Prevent row from taking full width
            children: [
              Icon(icon, color: color, size: 20), // Slightly larger icon
              kit.spacing.wXs,
              BridgeText(
                title,
                style: kit.typography.title.copyWith(
                  color: kit.colors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          kit.spacing.hgapXs,
          BridgeText(
            CurrencyFormatter.format(amount, currencySymbol),
            style: kit.typography.headline.copyWith(
              // Use headline for amount
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis, // Prevent overflow
          ),
        ],
      ),
    );
  }
}
