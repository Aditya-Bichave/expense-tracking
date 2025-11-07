// lib/features/dashboard/presentation/widgets/dashboard_header.dart
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/income_expense_summary_card.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/net_worth_card.dart';
import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final FinancialOverview overview;

  const DashboardHeader({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    // This widget combines the top cards
    return Column(
      children: [
        NetWorthCard(overview: overview),
        const SizedBox(height: 8), // Consistent spacing
        IncomeExpenseSummaryCard(overview: overview),
      ],
    );
  }
}
