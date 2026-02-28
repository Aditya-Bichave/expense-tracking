// lib/features/goals/presentation/pages/goals_sub_tab.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/goal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:expense_tracker/ui_bridge/bridge_card.dart';
import 'package:expense_tracker/ui_bridge/bridge_circular_progress_indicator.dart';
import 'package:expense_tracker/ui_bridge/bridge_scaffold.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_style.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class GoalsSubTab extends StatelessWidget {
  const GoalsSubTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;

    return BridgeScaffold(
      body: BlocBuilder<GoalListBloc, GoalListState>(
        builder: (context, state) {
          Widget content;
          if (state.status == GoalListStatus.loading && state.goals.isEmpty) {
            content = const Center(child: BridgeCircularProgressIndicator());
          } else if (state.status == GoalListStatus.error &&
              state.goals.isEmpty) {
            content = Center(
              child: Padding(
                padding: const context.space.allXl,
                child: Text(
                  "Error loading goals: ${state.errorMessage ?? 'Unknown error'}",
                  style: BridgeTextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (state.goals.isEmpty &&
              state.status != GoalListStatus.loading) {
            content = Center(
              child: Padding(
                padding: const context.space.allXxxl,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      size: 60,
                      color: theme.colorScheme.secondary.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No Savings Goals Yet",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tap the '+' button below to create your first savings goal.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // --- FIX: Added back Empty State Button ---
                    ElevatedButton.icon(
                      key: const ValueKey('button_addFirst'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Goal'),
                      onPressed: () => context.pushNamed(RouteNames.addGoal),
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
            content = ListView.builder(
              padding:
                  modeTheme?.pagePadding.copyWith(top: 8, bottom: 90) ??
                  const EdgeInsets.only(top: 8.0, bottom: 90.0),
              itemCount: state.goals.length,
              itemBuilder: (ctx, index) {
                final goal = state.goals[index];
                return GoalCard(
                  goal: goal,
                  onTap: () => context.pushNamed(
                    RouteNames.goalDetail,
                    pathParameters: {'id': goal.id},
                    extra: goal,
                  ),
                ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.2);
              },
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<GoalListBloc>().add(
                const LoadGoals(forceReload: true),
              );
              try {
                await context
                    .read<GoalListBloc>()
                    .stream
                    .firstWhere((s) => s.status != GoalListStatus.loading)
                    .timeout(const Duration(seconds: 3));
              } catch (_) {}
            },
            child: content,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('fab_goals_add'),
        heroTag: 'add_goal_fab_sub',
        tooltip: 'Create New Goal',
        onPressed: () => context.pushNamed(RouteNames.addGoal),
        child: const Icon(Icons.add),
      ),
    );
  }
}
