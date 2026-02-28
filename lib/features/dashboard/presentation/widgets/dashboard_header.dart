// lib/features/dashboard/presentation/widgets/dashboard_header.dart
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/income_expense_summary_card.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/overall_balance_card.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_bridge/bridge_card.dart';

class DashboardHeader extends StatelessWidget {
  final FinancialOverview overview;

  const DashboardHeader({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    // This widget combines the top cards
    return Column(
      children: [
        OverallBalanceBridgeCard(overview: overview),
        kit.spacing.gapSm, // Consistent spacing
        IncomeExpenseSummaryBridgeCard(overview: overview),
      ],
    );
  }
}
