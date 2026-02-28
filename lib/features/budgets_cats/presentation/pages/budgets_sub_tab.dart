// lib/features/budgets/presentation/pages/budgets_sub_tab.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/budgets/presentation/widgets/budget_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:expense_tracker/ui_bridge/bridge_card.dart';
import 'package:expense_tracker/ui_bridge/bridge_circular_progress_indicator.dart';
import 'package:expense_tracker/ui_bridge/bridge_scaffold.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_style.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class BudgetsSubTab extends StatelessWidget {
  const BudgetsSubTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;

    return BridgeScaffold(
      // Add Scaffold here
      body: BlocBuilder<BudgetListBloc, BudgetListState>(
        builder: (context, state) {
          Widget content;
          if (state.status == BudgetListStatus.loading &&
              state.budgetsWithStatus.isEmpty) {
            content = const Center(child: BridgeCircularProgressIndicator());
          } else if (state.status == BudgetListStatus.error &&
              state.budgetsWithStatus.isEmpty) {
            content = Center(
              child: Padding(
                padding: context.space.allXl,
                child: Text(
                  "Error loading budgets: ${state.errorMessage ?? 'Unknown error'}",
                  style: BridgeTextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (state.budgetsWithStatus.isEmpty &&
              state.status != BudgetListStatus.loading) {
            // Display empty state only when not loading and list is empty
            content = Center(
              child: Padding(
                padding: context.space.allXxxl,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 60,
                      color: theme.colorScheme.secondary.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No Budgets Created Yet",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Create budgets to track your spending goals.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // --- FIX: Button navigates to addBudget ---
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Budget'),
                      onPressed: () => context.pushNamed(RouteNames.addBudget),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    // --- END FIX ---
                  ],
                ),
              ),
            );
          } else {
            // Display the list of budgets
            content = ListView.builder(
              padding:
                  modeTheme?.pagePadding.copyWith(top: 8, bottom: 90) ??
                  const EdgeInsets.only(
                    top: 8.0,
                    bottom: 90.0,
                  ), // Padding for potential FAB
              itemCount: state.budgetsWithStatus.length,
              itemBuilder: (ctx, index) {
                final budgetStatus = state.budgetsWithStatus[index];
                return BudgetCard(
                      budgetStatus: budgetStatus,
                      onTap: () {
                        // Navigate to detail view
                        context.pushNamed(
                          RouteNames.budgetDetail,
                          pathParameters: {'id': budgetStatus.budget.id},
                          // Pass budgetStatus via extra if detail page needs it immediately
                          // extra: budgetStatus,
                        );
                      },
                    )
                    .animate()
                    .fadeIn(delay: (50 * index).ms, duration: 300.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOut);
              },
            );
          }
          // Add RefreshIndicator
          return RefreshIndicator(
            onRefresh: () async {
              context.read<BudgetListBloc>().add(
                const LoadBudgets(forceReload: true),
              );
              // Wait until the loading state completes
              await context.read<BudgetListBloc>().stream.firstWhere(
                (s) => s.status != BudgetListStatus.loading,
              );
            },
            child: content,
          );
        },
      ),
      // --- FIX: Add FAB to BudgetsSubTab ---
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_budget_fab',
        tooltip: 'Add Budget',
        onPressed: () => context.pushNamed(RouteNames.addBudget), // Unique tag
        child: const Icon(Icons.add), // Navigate to add budget
      ),
      // --- END FIX ---
    );
  }
}
