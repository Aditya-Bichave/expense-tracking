import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
// Import Add/Edit Category Screen (to be created)
// import 'package:expense_tracker/features/categories/presentation/pages/add_edit_category_screen.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart'; // For navigation if needed

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  // Navigation helper (replace 'add_edit_category_route' with actual route name)
  void _navigateToAddEdit(BuildContext context, {Category? category}) {
    log.info(
        "[CategoryMgmtScreen] Navigating to Add/Edit. Category: ${category?.name}");
    // Option 1: Using GoRouter push/pushNamed if route is defined
    // context.pushNamed('add_edit_category_route', extra: category);

    // Option 2: Using MaterialPageRoute (simpler if no complex routing needed)
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: BlocProvider.of<CategoryManagementBloc>(
            context), // Pass existing bloc? Or create new? Re-using for simplicity
        child: AddEditCategoryScreen(
            initialCategory: category), // Pass category for editing
      ),
    ));
  }

  void _handleDelete(BuildContext context, Category category) async {
    log.info("[CategoryMgmtScreen] Delete requested for: ${category.name}");
    final confirmed = await AppDialogs.showConfirmation(
      context,
      title: "Confirm Delete",
      content:
          "Are you sure you want to delete the category '${category.name}'?\n\nTransactions using this category will be marked as 'Uncategorized'.", // Simplification: Reassigning handled in Bloc/UseCase
      confirmText: "Delete",
      confirmColor: Theme.of(context).colorScheme.error,
    );

    if (confirmed == true) {
      log.info("[CategoryMgmtScreen] Delete confirmed for: ${category.name}");
      context
          .read<CategoryManagementBloc>()
          .add(DeleteCategory(categoryId: category.id));
    } else {
      log.info("[CategoryMgmtScreen] Delete cancelled for: ${category.name}");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Assuming CategoryManagementBloc is provided higher up or created here
    return BlocProvider<CategoryManagementBloc>(
      create: (context) =>
          sl<CategoryManagementBloc>()..add(const LoadCategories()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Categories'),
        ),
        body: BlocConsumer<CategoryManagementBloc, CategoryManagementState>(
          listener: (context, state) {
            if (state.status == CategoryManagementStatus.error &&
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

            if (state.customCategories.isEmpty) {
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

            // Display list of custom categories
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.customCategories.length,
              itemBuilder: (context, index) {
                final category = state.customCategories[index];
                return AppCard(
                  // Use AppCard for consistent styling
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: category.displayColor.withOpacity(0.2),
                      child: Icon(
                        // TODO: Implement proper icon mapping based on category.iconName
                        Icons.category, // Placeholder
                        color: category.displayColor,
                        size: 20,
                      ),
                    ),
                    title: Text(category.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit Category',
                          onPressed: () =>
                              _navigateToAddEdit(context, category: category),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error),
                          tooltip: 'Delete Category',
                          onPressed: () => _handleDelete(context, category),
                        ),
                      ],
                    ),
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

// Placeholder for AddEditCategoryScreen - CREATE THIS FILE NEXT
class AddEditCategoryScreen extends StatelessWidget {
  final Category? initialCategory;
  const AddEditCategoryScreen({super.key, this.initialCategory});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement the form UI for adding/editing categories
    return Scaffold(
      appBar: AppBar(
          title:
              Text(initialCategory == null ? 'Add Category' : 'Edit Category')),
      body: Center(
          child: Text(initialCategory == null
              ? 'Add Category Form Placeholder'
              : 'Edit Category Form Placeholder for ${initialCategory!.name}')),
    );
  }
}
