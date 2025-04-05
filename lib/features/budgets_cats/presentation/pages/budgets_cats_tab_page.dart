// lib/features/budgets_cats/presentation/pages/budgets_cats_tab_page.dart
import 'package:expense_tracker/core/di/service_locator.dart'; // To be created
import 'package:expense_tracker/features/budgets/presentation/pages/budgets_sub_tab.dart'; // ADDED
import 'package:expense_tracker/features/budgets_cats/presentation/pages/budgets_sub_tab.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/pages/categories_sub_tab.dart';
import 'package:expense_tracker/features/goals/presentation/pages/goals_sub_tab.dart'; // ADDED (Placeholder)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
          backgroundColor: Theme.of(context).colorScheme.surface,
          toolbarHeight: 0,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Budgets'), // Changed order
              Tab(text: 'Categories'),
              Tab(text: 'Goals'), // Added Goals
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
            GoalsSubTab(), // Goals Screen (Placeholder for Phase 2)
          ],
        ),
      ),
    );
  }
}

// Create placeholder GoalsSubTab
// lib/features/goals/presentation/pages/goals_sub_tab.dart

class GoalsSubTab extends StatelessWidget {
  const GoalsSubTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Goals Feature - Coming Soon!"));
  }
}
