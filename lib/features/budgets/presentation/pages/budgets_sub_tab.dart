// lib/features/budgets/presentation/pages/budgets_sub_tab.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/budgets/presentation/widgets/budget_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BudgetsSubTab extends StatelessWidget {
  const BudgetsSubTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;

    return Scaffold(
      body: BlocBuilder<BudgetListBloc, BudgetListState>(
        builder: (context, state) {
          Widget content;
          if (state.status == BudgetListStatus.loading &&
              state.budgetsWithStatus.isEmpty) {
            content = const Center(child: CircularProgressIndicator());
          } else if (state.status == BudgetListStatus.error &&
              state.budgetsWithStatus.isEmpty) {
            content = Center(
                child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                        "Error loading budgets: ${state.errorMessage ?? 'Unknown error'}",
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center)));
          } else if (state.budgetsWithStatus.isEmpty &&
              state.status != BudgetListStatus.loading) {
            content = Center(
                child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pie_chart_outline_rounded,
                              size: 60,
                              color:
                                  theme.colorScheme.secondary.withOpacity(0.7)),
                          const SizedBox(height: 16),
                          Text("No Budgets Created Yet",
                              style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.secondary)),
                          const SizedBox(height: 8),
                          Text(
                            "Create budgets to track your spending goals.",
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // --- FIX: Added back Empty State Button ---
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Budget'),
                            onPressed: () =>
                                context.pushNamed(RouteNames.addBudget),
                            style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12)),
                          )
                          // --- END FIX ---
                        ])));
          } else {
            content = ListView.builder(
              padding: modeTheme?.pagePadding.copyWith(top: 8, bottom: 90) ??
                  const EdgeInsets.only(top: 8.0, bottom: 90.0),
              itemCount: state.budgetsWithStatus.length,
              itemBuilder: (ctx, index) {
                final budgetStatus = state.budgetsWithStatus[index];
                return BudgetCard(
                  budgetStatus: budgetStatus,
                  onTap: () => context.pushNamed(RouteNames.budgetDetail,
                      pathParameters: {'id': budgetStatus.budget.id}),
                ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.2);
              },
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<BudgetListBloc>()
                  .add(const LoadBudgets(forceReload: true));
              await context
                  .read<BudgetListBloc>()
                  .stream
                  .firstWhere((s) => s.status != BudgetListStatus.loading);
            },
            child: content,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_budget_fab_sub',
        child: const Icon(Icons.add),
        tooltip: 'Add Budget',
        onPressed: () => context.pushNamed(RouteNames.addBudget),
      ),
    );
  }
}
