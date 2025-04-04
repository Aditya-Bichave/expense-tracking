import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/pages/add_edit_category_screen.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart'; // For availableIcons map
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  // Navigation helper to Add/Edit screen
  void _navigateToAddEdit(BuildContext context, {Category? category}) {
    log.info(
        "[CategoryMgmtScreen] Navigating to Add/Edit. Category: ${category?.name}");
    Navigator.of(context).push(MaterialPageRoute(
      // Provide the CategoryManagementBloc down to the AddEdit screen using BlocProvider.value
      builder: (_) => BlocProvider.value(
        value: BlocProvider.of<CategoryManagementBloc>(
            context), // Pass existing bloc instance
        child: AddEditCategoryScreen(initialCategory: category),
      ),
    ));
  }

  // Delete confirmation and event dispatch
  void _handleDelete(BuildContext context, Category category) async {
    log.info("[CategoryMgmtScreen] Delete requested for: ${category.name}");
    if (!category.isCustom) {
      log.warning(
          "[CategoryMgmtScreen] Attempted to delete a non-custom category: ${category.name}");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Predefined categories cannot be deleted.")));
      return;
    }

    final confirmed = await AppDialogs.showConfirmation(
      context,
      title: "Confirm Delete",
      content:
          "Are you sure you want to delete the custom category '${category.name}'?\n\nExisting transactions using this category will be reassigned to '${Category.uncategorized.name}'.",
      confirmText: "Delete",
      confirmColor: Theme.of(context).colorScheme.error,
    );

    if (confirmed == true) {
      log.info("[CategoryMgmtScreen] Delete confirmed for: ${category.name}");
      // Dispatch event to the bloc provided to this screen
      context
          .read<CategoryManagementBloc>()
          .add(DeleteCategory(categoryId: category.id));
    } else {
      log.info("[CategoryMgmtScreen] Delete cancelled for: ${category.name}");
    }
  }

  // Helper to build the list item
  Widget _buildCategoryItem(BuildContext context, Category category) {
    final theme = Theme.of(context);
    final IconData displayIconData =
        availableIcons[category.iconName] ?? Icons.category_outlined;

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: EdgeInsets.zero, // Let ListTile handle padding
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.displayColor.withOpacity(0.15),
          foregroundColor: category.displayColor.computeLuminance() > 0.5
              ? Colors.black54
              : null, // Contrast foreground
          child: Icon(displayIconData, color: category.displayColor, size: 20),
        ),
        title: Text(category.name),
        trailing: category.isCustom
            ? Row(
                // Actions only for custom categories
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: 20,
                    color: theme.colorScheme.secondary,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Edit Category',
                    onPressed: () =>
                        _navigateToAddEdit(context, category: category),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 20,
                    color: theme.colorScheme.error,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete Category',
                    onPressed: () => _handleDelete(context, category),
                  ),
                ],
              )
            : IconButton(
                // Action for predefined (personalize icon)
                icon: const Icon(Icons.palette_outlined),
                iconSize: 20,
                color: theme.colorScheme.secondary,
                visualDensity: VisualDensity.compact,
                tooltip: 'Personalize Icon/Color (Coming Soon)',
                onPressed: () {
                  log.warning(
                      "Personalization for predefined categories not implemented.");
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Personalization coming soon!")));
                },
              ),
      ),
    );
  }

  // Builder for the category list within a tab
  Widget _buildCategoryList(
      BuildContext context, List<Category> categories, String emptyMessage) {
    final theme = Theme.of(context);
    if (categories.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(emptyMessage, style: theme.textTheme.titleMedium)));
    }
    // Sort combined list for consistent display
    categories
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0, bottom: 90.0), // Padding for FAB
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryItem(context, category)
            .animate()
            .fadeIn(
                delay: (40 * index).ms,
                duration: 300.ms) // Slightly adjusted timing
            .slideY(begin: 0.1, curve: Curves.easeOut);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Provide the Bloc specific to this screen
    return BlocProvider<CategoryManagementBloc>(
      create: (context) =>
          sl<CategoryManagementBloc>()..add(const LoadCategories()),
      child: DefaultTabController(
        // Use TabController for Expense/Income separation
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Manage Categories'),
            // Add TabBar to the AppBar
            bottom: TabBar(
              tabs: const [
                Tab(icon: Icon(Icons.arrow_downward), text: 'Expenses'),
                Tab(icon: Icon(Icons.arrow_upward), text: 'Income'),
              ],
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor:
                  Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          body: BlocConsumer<CategoryManagementBloc, CategoryManagementState>(
            listener: (context, state) {
              // Show feedback snackbars
              if (state.status == CategoryManagementStatus.error &&
                  state.errorMessage != null) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                      content: Text("Error: ${state.errorMessage!}"),
                      backgroundColor: Theme.of(context).colorScheme.error));
                // Optionally clear the error message after showing
                // context.read<CategoryManagementBloc>().add(ClearCategoryMessages());
              }
              // Can add success messages here if desired
              // else if (state.status == CategoryManagementStatus.loaded && prev_state had action?) {
              //    ScaffoldMessenger.of(context)... showSnackBar(SnackBar(content: Text("Action successful!")));
              // }
            },
            builder: (context, state) {
              if (state.status == CategoryManagementStatus.initial ||
                  state.status == CategoryManagementStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              // Show error prominently if loading fails initially
              if (state.status == CategoryManagementStatus.error &&
                  state.predefinedExpenseCategories.isEmpty &&
                  state.customExpenseCategories.isEmpty) {
                return Center(
                    child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                            "Error loading categories: ${state.errorMessage ?? 'Unknown error'}",
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error))));
              }

              // Display content within TabBarView
              return TabBarView(
                children: [
                  // Expense Tab Content
                  _buildCategoryList(
                      context,
                      // Combine predefined and custom expense categories
                      [
                        ...state.predefinedExpenseCategories,
                        ...state.customExpenseCategories
                      ],
                      'No expense categories found.'),
                  // Income Tab Content
                  _buildCategoryList(
                      context,
                      // Combine predefined and custom income categories
                      [
                        ...state.predefinedIncomeCategories,
                        ...state.customIncomeCategories
                      ],
                      'No income categories found.'),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'add_category_fab', // Unique Hero tag
            icon: const Icon(Icons.add),
            label: const Text("Add Custom"),
            tooltip: 'Add Custom Category',
            // Pass the context that has the CategoryManagementBloc provider
            onPressed: () => _navigateToAddEdit(context),
          ),
        ),
      ),
    );
  }
}

// Helper extension (if not already in utils)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
