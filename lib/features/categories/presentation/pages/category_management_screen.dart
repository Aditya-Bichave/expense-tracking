// lib/features/categories/presentation/pages/category_management_screen.dart
// MODIFIED FILE (Full UI Implementation)

import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/pages/add_edit_category_screen.dart'; // Import Add/Edit Screen
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart'; // For availableIcons map
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart'; // For list animations

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  // Navigation helper to Add/Edit screen
  void _navigateToAddEdit(BuildContext context, {Category? category}) {
    log.info(
        "[CategoryMgmtScreen] Navigating to Add/Edit. Category: ${category?.name}");
    Navigator.of(context).push(MaterialPageRoute(
      // Provide the CategoryManagementBloc from this screen down to the AddEdit screen
      builder: (_) => BlocProvider.value(
        value: BlocProvider.of<CategoryManagementBloc>(context),
        child: AddEditCategoryScreen(initialCategory: category),
      ),
    ));
  }

  // Delete confirmation and event dispatch
  void _handleDelete(BuildContext context, Category category) async {
    log.info("[CategoryMgmtScreen] Delete requested for: ${category.name}");
    final confirmed = await AppDialogs.showConfirmation(
      context,
      title: "Confirm Delete",
      content:
          "Are you sure you want to delete the category '${category.name}'?\n\nExisting transactions using this category will be reassigned to '${Category.uncategorized.name}'.",
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
    final IconData displayIconData = availableIcons[category.iconName] ??
        Icons.category_outlined; // Fallback

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: EdgeInsets.zero, // ListTile has its own padding
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.displayColor.withOpacity(0.15),
          child: Icon(displayIconData, color: category.displayColor, size: 20),
          // Prevent foreground color from theme if background is light
          foregroundColor: category.displayColor.computeLuminance() > 0.5
              ? Colors.black
              : null,
        ),
        title: Text(category.name),
        // Only show edit/delete for custom categories
        trailing: category.isCustom
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        color: theme.colorScheme.secondary),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Edit Category',
                    onPressed: () =>
                        _navigateToAddEdit(context, category: category),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: theme.colorScheme.error),
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete Category',
                    onPressed: () => _handleDelete(context, category),
                  ),
                ],
              )
            : null, // No actions for predefined categories (for now)
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Create and provide the Bloc for this screen and its potential children (Add/Edit)
    return BlocProvider<CategoryManagementBloc>(
      create: (context) =>
          sl<CategoryManagementBloc>()..add(const LoadCategories()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Categories'),
          // Optional: Add refresh button if needed
          // actions: [
          //    IconButton(
          //       icon: const Icon(Icons.refresh),
          //       onPressed: () => context.read<CategoryManagementBloc>().add(const LoadCategories(forceReload: true)),
          //    ),
          // ],
        ),
        body: BlocConsumer<CategoryManagementBloc, CategoryManagementState>(
          listener: (context, state) {
            // Show snackbars for feedback on actions triggered from this screen
            if (state.status == CategoryManagementStatus.error &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                    content: Text("Error: ${state.errorMessage!}"),
                    backgroundColor: Theme.of(context).colorScheme.error));
            }
            // Optionally show success messages for delete/update if needed
          },
          builder: (context, state) {
            if (state.status == CategoryManagementStatus.initial ||
                state.status == CategoryManagementStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final customCategories = state.customCategories;
            // TODO: Add section for predefined categories if personalization is implemented

            if (customCategories.isEmpty) {
              return Center(
                child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('No custom categories yet.',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 10),
                        Text('Tap "+" below to add your first custom category.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    )),
              );
            }

            // Display list of custom categories
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: customCategories.length,
              itemBuilder: (context, index) {
                final category = customCategories[index];
                return _buildCategoryItem(context, category)
                    .animate() // Add animation
                    .fadeIn(delay: (50 * index).ms, duration: 300.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOut);
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text("Add Category"),
          tooltip: 'Add Custom Category',
          onPressed: () =>
              _navigateToAddEdit(context), // Navigate to Add screen
        ),
      ),
    );
  }
}
