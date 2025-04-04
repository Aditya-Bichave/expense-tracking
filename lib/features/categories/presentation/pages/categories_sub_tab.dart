import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart'; // Import type
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CategoriesSubTab extends StatelessWidget {
  const CategoriesSubTab({super.key});

  // Reusable list item builder (no actions needed here)
  Widget _buildCategoryItem(BuildContext context, Category category) {
    final theme = Theme.of(context);
    final IconData displayIconData =
        availableIcons[category.iconName] ?? Icons.category_outlined;

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: EdgeInsets.zero,
      child: ListTile(
          leading: CircleAvatar(
            backgroundColor: category.displayColor.withOpacity(0.15),
            child:
                Icon(displayIconData, color: category.displayColor, size: 20),
            foregroundColor: category.displayColor.computeLuminance() > 0.5
                ? Colors.black
                : null,
          ),
          title: Text(category.name)),
    );
  }

  // Builder for the category list within a tab
  Widget _buildCategoryList(
      BuildContext context, List<Category> categories, String title) {
    final theme = Theme.of(context);
    if (categories.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('No $title categories defined.',
                  style: theme.textTheme.bodyMedium)));
    }
    // Sort list before displaying
    categories
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryItem(context, category)
            .animate()
            .fadeIn(delay: (30 * index).ms, duration: 250.ms)
            .slideY(begin: 0.1, curve: Curves.easeOut);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use DefaultTabController to match Management Screen or simplify view
    return DefaultTabController(
      length: 2,
      child: Column(
        // Use column to hold TabBar and TabBarView
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Expenses'),
              Tab(text: 'Income'),
            ],
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          ),
          Expanded(
            child: BlocBuilder<CategoryManagementBloc, CategoryManagementState>(
              builder: (context, state) {
                if (state.status == CategoryManagementStatus.initial ||
                    state.status == CategoryManagementStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == CategoryManagementStatus.error) {
                  return Center(
                      child: Text(
                          "Error: ${state.errorMessage ?? 'Could not load'}"));
                }

                // Combine predefined and custom for display in each tab
                final expenseCats = [
                  ...state.predefinedExpenseCategories,
                  ...state.customExpenseCategories
                ];
                final incomeCats = [
                  ...state.predefinedIncomeCategories,
                  ...state.customIncomeCategories
                ];

                return TabBarView(
                  children: [
                    _buildCategoryList(context, expenseCats, "expense"),
                    _buildCategoryList(context, incomeCats, "income"),
                  ],
                );
              },
            ),
          ),
          // Button to navigate to Management Screen
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.settings_outlined),
              label: const Text("Manage Categories"),
              onPressed: () => context.pushNamed(RouteNames.manageCategories),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(45), // Make button wider
              ),
            ),
          )
        ],
      ),
    );
  }
}
