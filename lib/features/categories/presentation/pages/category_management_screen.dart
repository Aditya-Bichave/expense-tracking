// lib/features/categories/presentation/pages/category_management_screen.dart
// MODIFIED FILE
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
// --- UPDATED Import ---
import 'package:expense_tracker/features/categories/presentation/pages/add_edit_category_screen.dart';
// --- END UPDATED ---
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart'; // For availableIcons map
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart'; // Keep if using named routes

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  // Navigation helper now uses MaterialPageRoute with the implemented screen
  void _navigateToAddEdit(BuildContext context, {Category? category}) {
    log.info(
        "[CategoryMgmtScreen] Navigating to Add/Edit. Category: ${category?.name}");
    Navigator.of(context).push(MaterialPageRoute(
      // Provide the CategoryManagementBloc down to the AddEdit screen
      // This allows AddEdit screen to dispatch Add/Update events
      builder: (_) => BlocProvider.value(
        value: BlocProvider.of<CategoryManagementBloc>(context),
        child: AddEditCategoryScreen(initialCategory: category),
      ),
    ));
  }

  void _handleDelete(BuildContext context, Category category) async {
    log.info("[CategoryMgmtScreen] Delete requested for: ${category.name}");
    // Confirmation dialog as before
    final confirmed = await AppDialogs.showConfirmation(
      context,
      title: "Confirm Delete",
      content:
          "Are you sure you want to delete the category '${category.name}'?\n\nThis action cannot be undone easily and might affect transaction history if reassignment fails.",
      confirmText: "Delete",
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (confirmed == true) {
      log.info("[CategoryMgmtScreen] Delete confirmed for: ${category.name}");
      // Transaction reassignment logic needs to be robust in the UseCase/Bloc
      context
          .read<CategoryManagementBloc>()
          .add(DeleteCategory(categoryId: category.id));
    } else {
      log.info("[CategoryMgmtScreen] Delete cancelled for: ${category.name}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CategoryManagementBloc>(
      create: (context) =>
          sl<CategoryManagementBloc>()..add(const LoadCategories()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Categories'),
        ),
        body: BlocConsumer<CategoryManagementBloc, CategoryManagementState>(
          listener: (context, state) {
            /* ... Listener logic remains the same ... */ if (state.status ==
                    CategoryManagementStatus.error &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                    content: Text("Error: ${state.errorMessage!}"),
                    backgroundColor: Theme.of(context).colorScheme.error));
            }
          },
          builder: (context, state) {
            if (state.status == CategoryManagementStatus.initial ||
                state.status == CategoryManagementStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Combine custom and predefined (for potential editing later)
            // For now, only list custom categories for management.
            final categoriesToList = state
                .customCategories; // Change this later for predefined personalization

            if (categoriesToList.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'No custom categories created yet.\nTap "+" to add one!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: categoriesToList.length,
              itemBuilder: (context, index) {
                final category = categoriesToList[index];
                // Get IconData for display
                final IconData displayIconData =
                    availableIcons[category.iconName] ??
                        Icons.help_outline; // Fallback

                return AppCard(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: category.displayColor.withOpacity(0.2),
                      child: Icon(displayIconData,
                          color: category.displayColor, size: 20),
                    ),
                    title: Text(category.name),
                    // Only show edit/delete for custom categories
                    trailing: category.isCustom
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit Category',
                                onPressed: () => _navigateToAddEdit(context,
                                    category: category),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: Theme.of(context).colorScheme.error),
                                tooltip: 'Delete Category',
                                onPressed: () =>
                                    _handleDelete(context, category),
                              ),
                            ],
                          )
                        : null, // No actions for predefined categories yet
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          tooltip: 'Add Custom Category',
          onPressed: () => _navigateToAddEdit(context),
        ),
      ),
    );
  }
}

// REMOVED Placeholder for AddEditCategoryScreen - Now imported
