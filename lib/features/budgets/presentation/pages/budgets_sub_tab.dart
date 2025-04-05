// lib/features/budgets_cats/presentation/pages/budgets_cats_tab_page.dart
// REMOVED incorrect import/class definition from the bottom

import 'package:expense_tracker/features/budgets/presentation/pages/budgets_sub_tab.dart'; // Correct import
import 'package:expense_tracker/features/budgets_cats/presentation/pages/budgets_sub_tab.dart';
import 'package:expense_tracker/features/categories/presentation/pages/categories_sub_tab.dart';
import 'package:expense_tracker/features/goals/presentation/pages/goals_sub_tab.dart'; // Correct import for the placeholder
import 'package:flutter/material.dart';
// Removed Bloc imports as they are assumed global now based on main.dart setup

class BudgetsAndCatsTabPage extends StatelessWidget {
  const BudgetsAndCatsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming CategoryManagementBloc & BudgetListBloc are provided globally
    return _buildTabs(context);
  }

  Widget _buildTabs(BuildContext context) {
    return DefaultTabController(
      length: 3, // Budgets, Categories, Goals
      child: Scaffold(
        // Use a nested AppBar for the tabs
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context)
              .colorScheme
              .surface, // Or surfaceContainerLowest
          toolbarHeight: 0, // Hide the default AppBar height if needed
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Budgets'),
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
            BudgetsSubTab(), // Budgets Screen
            CategoriesSubTab(), // Categories Screen
            GoalsSubTab(), // Goals Screen (Placeholder)
          ],
        ),
      ),
    );
  }
}
// NO other class definitions or imports below this line in this file.
