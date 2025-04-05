// lib/features/goals/presentation/pages/goals_sub_tab.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/goal_card.dart'; // Create this next
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:expense_tracker/router.dart'; // Import AppRouter for route names

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
                        textAlign: TextAlign.center)));
          } else if (state.goals.isEmpty) {
            content = Center(
                child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.savings_outlined,
                              size: 60,
                              color:
                                  theme.colorScheme.secondary.withOpacity(0.7)),
                          const SizedBox(height: 16),
                          Text("No Savings Goals Yet",
                              style: theme.textTheme.headlineSmall),
                          const SizedBox(height: 8),
                          Text(
                            "Tap the '+' button to create your first savings goal.",
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ])));
          } else {
            // Display the list of goals
            content = ListView.builder(
              padding: modeTheme?.pagePadding.copyWith(top: 8, bottom: 90) ??
                  const EdgeInsets.only(top: 8.0, bottom: 90.0),
              itemCount: state.goals.length,
              itemBuilder: (ctx, index) {
                final goal = state.goals[index];
                return GoalCard(
                  // Create this widget next
                  goal: goal,
                  onTap: () {
                    // Navigate to detail view (Phase 3)
                    // Use AppRouter constants
                    context.pushNamed(RouteNames.goalDetail,
                        pathParameters: {'id': goal.id}, extra: goal);
                    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Detail view coming soon for ${goal.name}")));
                  },
                )
                    .animate()
                    .fadeIn(delay: (50 * index).ms)
                    .slideY(begin: 0.2, curve: Curves.easeOut);
              },
            );
          }
          // Add RefreshIndicator
          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<GoalListBloc>()
                  .add(const LoadGoals(forceReload: true));
              await context
                  .read<GoalListBloc>()
                  .stream
                  .firstWhere((s) => s.status != GoalListStatus.loading);
            },
            child: content,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_goal_fab', // Unique tag
        child: const Icon(Icons.add),
        tooltip: 'Create New Goal',
        onPressed: () =>
            context.pushNamed(RouteNames.addGoal), // Use AppRouter constant
      ),
    );
  }
}
