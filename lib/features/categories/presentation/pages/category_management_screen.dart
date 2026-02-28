// lib/features/categories/presentation/pages/category_management_screen.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/pages/add_edit_category_screen.dart';
// Import decomposed widget
import 'package:expense_tracker/features/categories/presentation/widgets/category_list_section_widget.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/ui_bridge/bridge_circular_progress_indicator.dart';
import 'package:expense_tracker/ui_bridge/bridge_scaffold.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_style.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  void _navigateToAddEdit(BuildContext context, {Category? category}) {
    log.info(
      "[CategoryMgmtScreen] Navigating to Add/Edit. Category: ${category?.name}",
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: BlocProvider.of<CategoryManagementBloc>(context),
          child: AddEditCategoryScreen(initialCategory: category),
        ),
      ),
    );
  }

  void _handleDelete(BuildContext context, Category category) async {
    log.info("[CategoryMgmtScreen] Delete requested for: ${category.name}");
    if (!category.isCustom) {
      log.warning(
        "[CategoryMgmtScreen] Attempted to delete a non-custom category: ${category.name}",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Predefined categories cannot be deleted."),
        ),
      );
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
    if (confirmed == true && context.mounted) {
      log.info("[CategoryMgmtScreen] Delete confirmed for: ${category.name}");
      context.read<CategoryManagementBloc>().add(
        DeleteCategory(categoryId: category.id),
      );
    } else {
      log.info("[CategoryMgmtScreen] Delete cancelled for: ${category.name}");
    }
  }

  void _handlePersonalize(BuildContext context, Category category) {
    log.warning("Personalization for predefined categories not implemented.");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Personalization coming soon!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CategoryManagementBloc>(
      create: (context) =>
          sl<CategoryManagementBloc>()..add(const LoadCategories()),
      child: DefaultTabController(
        length: 2,
        child: BridgeScaffold(
          appBar: AppBar(
            title: const Text('Manage Categories'),
            bottom: TabBar(
              tabs: const [
                Tab(icon: Icon(Icons.arrow_downward), text: 'Expenses'),
                Tab(icon: Icon(Icons.arrow_upward), text: 'Income'),
              ],
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant,
            ),
          ),
          body: BlocConsumer<CategoryManagementBloc, CategoryManagementState>(
            listener: (context, state) {
              if (state.status == CategoryManagementStatus.error &&
                  state.errorMessage != null) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text("Error: ${state.errorMessage!}"),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                // Optionally clear error message via Bloc event
                // context.read<CategoryManagementBloc>().add(const ClearCategoryMessages());
              }
            },
            builder: (context, state) {
              if (state.status == CategoryManagementStatus.initial ||
                  state.status == CategoryManagementStatus.loading) {
                return const Center(child: BridgeCircularProgressIndicator());
              }
              if (state.status == CategoryManagementStatus.error &&
                  state.predefinedExpenseCategories.isEmpty &&
                  state.customExpenseCategories.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const BridgeEdgeInsets.all(20.0),
                    child: Text(
                      "Error loading categories: ${state.errorMessage ?? 'Unknown error'}",
                      style: BridgeTextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                );
              }

              // Use the decomposed list section widget
              return TabBarView(
                children: [
                  CategoryListSectionWidget(
                    categories: [
                      ...state.predefinedExpenseCategories,
                      ...state.customExpenseCategories,
                    ],
                    emptyMessage: 'No expense categories found.',
                    onEditCategory: (category) =>
                        _navigateToAddEdit(context, category: category),
                    onDeleteCategory: (category) =>
                        _handleDelete(context, category),
                    onPersonalizeCategory: (category) =>
                        _handlePersonalize(context, category),
                  ),
                  CategoryListSectionWidget(
                    categories: [
                      ...state.predefinedIncomeCategories,
                      ...state.customIncomeCategories,
                    ],
                    emptyMessage: 'No income categories found.',
                    onEditCategory: (category) =>
                        _navigateToAddEdit(context, category: category),
                    onDeleteCategory: (category) =>
                        _handleDelete(context, category),
                    onPersonalizeCategory: (category) =>
                        _handlePersonalize(context, category),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const ValueKey('fab_add_custom'),
            heroTag: 'add_category_fab',
            icon: const Icon(Icons.add),
            label: const Text("Add Custom"),
            tooltip: 'Add Custom Category',
            onPressed: () => _navigateToAddEdit(context),
          ),
        ),
      ),
    );
  }
}
