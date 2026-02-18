import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/recent_transactions_section.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/stitch/stitch_goals_list.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/stitch/stitch_header.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/stitch/stitch_net_balance_card.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/stitch/stitch_quick_actions.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';

class StitchDashboardBody extends StatelessWidget {
  final FinancialOverview overview;
  final Function(BuildContext, TransactionEntity) navigateToDetailOrEdit;
  final Future<void> Function() onRefresh;

  const StitchDashboardBody({
    super.key,
    required this.overview,
    required this.navigateToDetailOrEdit,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.background.withOpacity(0.9),
            pinned: true,
            automaticallyImplyLeading: false,
            toolbarHeight: 90,
            title: const StitchHeader(),
            titleSpacing: 0,
            elevation: 0,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                StitchNetBalanceCard(overview: overview),
                const StitchQuickActions(),
                const SizedBox(height: 16),
                StitchGoalsList(goals: overview.activeGoalsSummary),
                const SizedBox(height: 16),
                RecentTransactionsSection(
                  navigateToDetailOrEdit: navigateToDetailOrEdit,
                ),
                const SizedBox(height: 80), // Bottom padding
              ],
            ),
          ),
        ],
      ),
    );
  }
}
