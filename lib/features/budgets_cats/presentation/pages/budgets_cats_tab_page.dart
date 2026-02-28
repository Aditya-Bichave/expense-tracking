// lib/features/budgets_cats/presentation/pages/budgets_cats_tab_page.dart
// ignore_for_file: unused_import

import 'package:expense_tracker/features/budgets/presentation/pages/budgets_sub_tab.dart';
import 'package:expense_tracker/features/budgets_cats/presentation/pages/budgets_sub_tab.dart'
    hide BudgetsSubTab;
import 'package:expense_tracker/features/goals/presentation/pages/goals_sub_tab.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Import GoRouterState
import 'package:expense_tracker/ui_bridge/bridge_scaffold.dart';

// Bloc imports are assumed to be global via main.dart MultiBlocProvider

class BudgetsAndCatsTabPage extends StatelessWidget {
  // Keep original class name
  const BudgetsAndCatsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine initial index based on extra data if provided
    int initialIndex = 0;
    final extraData = GoRouterState.of(context).extra;
    if (extraData is Map && extraData.containsKey('initialTabIndex')) {
      final index = extraData['initialTabIndex'];
      // Adjust index based on removed Categories tab (0=Budgets, 1=Goals now)
      if (index is int && index == 2) {
        // If intended index was Goals (originally 2)
        initialIndex = 1; // Set it to 1 (the new index for Goals)
      } else if (index is int && index == 0) {
        // If intended index was Budgets (originally 0)
        initialIndex = 0; // Keep it 0
      }
    }

    return DefaultTabController(
      // --- FIX: Length is now 2 ---
      length: 2, // Budgets, Goals
      initialIndex: initialIndex,
      // --- END FIX ---
      child: BridgeScaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          toolbarHeight: 0,
          bottom: TabBar(
            // --- FIX: Remove Categories Tab ---
            tabs: const [
              Tab(text: 'Budgets'),
              Tab(text: 'Goals'),
            ],
            // --- END FIX ---
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant,
          ),
        ),
        body: const TabBarView(
          // --- FIX: Remove CategoriesSubTab ---
          children: [BudgetsSubTab(), GoalsSubTab()],
          // --- END FIX ---
        ),
      ),
    );
  }
}

// Remove the placeholder GoalsSubTab class if it was previously defined here
