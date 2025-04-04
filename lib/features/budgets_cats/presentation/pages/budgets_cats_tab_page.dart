import 'package:expense_tracker/core/di/service_locator.dart'; // To be created
import 'package:expense_tracker/features/budgets_cats/presentation/pages/budgets_sub_tab.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/pages/categories_sub_tab.dart'; // To be created
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BudgetsAndCatsTabPage extends StatelessWidget {
  const BudgetsAndCatsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide CategoryManagementBloc if not already global
    // It's needed by CategoriesSubTab and potentially Manage Categories screen
    // return BlocProvider<CategoryManagementBloc>(
    //   create: (context) => sl<CategoryManagementBloc>()..add(const LoadCategories()), // Load if needed
    //   child: _buildTabs(context),
    // );
    return _buildTabs(context); // Assuming Bloc is provided globally
  }

  Widget _buildTabs(BuildContext context) {
    return DefaultTabController(
      length: 2, // Budgets and Categories
      child: Scaffold(
        // Use a nested AppBar for the tabs
        appBar: AppBar(
          // Remove elevation or background if it clashes with MainShell AppBar style
          elevation: 0,
          backgroundColor:
              Theme.of(context).colorScheme.surface, // Or transparent
          toolbarHeight: 0, // Hide the default AppBar height
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Budgets'),
              Tab(text: 'Categories'),
            ],
            // Customize indicator/label colors if needed
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        body: const TabBarView(
          children: [
            BudgetsSubTab(), // Placeholder content
            CategoriesSubTab(), // List of categories
          ],
        ),
      ),
    );
  }
}
