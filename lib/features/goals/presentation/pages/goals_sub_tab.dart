// lib/features/goals/presentation/pages/goals_sub_tab.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/goal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GoalsSubTab extends StatelessWidget {
  const GoalsSubTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;

    return Scaffold(
      body: BlocBuilder<GoalListBloc, GoalListState>(
        builder: (context, state) {
          Widget content;
          if (state.status == GoalListStatus.loading && state.goals.isEmpty) {
            content = const Center(child: CircularProgressIndicator());
          } else if (state.status == GoalListStatus.error &&
              state.goals.isEmpty) {
            content = Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Error loading goals: ${state.errorMessage ?? 'Unknown error'}",
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (state.goals.isEmpty &&
              state.status != GoalListStatus.loading) {
            content = Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
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
              await context.read<GoalListBloc>().stream.firstWhere(
                (s) => s.status != GoalListStatus.loading,
              );
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
