// lib/features/budgets_cats/presentation/pages/budgets_cats_tab_page.dart
import 'package:expense_tracker/features/budgets/presentation/pages/budgets_sub_tab.dart'; // Import the actual BudgetsSubTab
import 'package:expense_tracker/features/budgets_cats/presentation/pages/budgets_sub_tab.dart';
import 'package:expense_tracker/features/categories/presentation/pages/categories_sub_tab.dart';
import 'package:expense_tracker/features/goals/presentation/pages/goals_sub_tab.dart'; // Import the implemented GoalsSubTab
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// Bloc imports are assumed to be global via main.dart MultiBlocProvider

class BudgetsAndCatsTabPage extends StatelessWidget {
  const BudgetsAndCatsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine initial index based on extra data if provided (e.g., from GoalSummaryWidget)
    int initialIndex = 0;
    final extraData = GoRouterState.of(context).extra;
    if (extraData is Map && extraData.containsKey('initialTabIndex')) {
      final index = extraData['initialTabIndex'];
      if (index is int && index >= 0 && index < 3) {
        initialIndex = index;
      }
    }

    return DefaultTabController(
      length: 3, // Budgets, Categories, Goals
      initialIndex: initialIndex, // Set initial tab index
      child: Scaffold(
        // Use a nested AppBar for the tabs
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          toolbarHeight: 0,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Budgets'), // Order: Budgets, Categories, Goals
              Tab(text: 'Categories'),
              Tab(text: 'Goals'),
            ],
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        body: const TabBarView(
          children: [
            BudgetsSubTab(), // Budgets Screen (Implemented)
            CategoriesSubTab(), // Categories Screen (Existing)
            GoalsSubTab(), // Goals Screen (Now Implemented)
          ],
        ),
      ),
    );
  }
}
