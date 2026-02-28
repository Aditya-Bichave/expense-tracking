// lib/features/categories/presentation/widgets/category_picker_dialog.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/ui_bridge/bridge_list_tile.dart';
import 'package:expense_tracker/ui_bridge/bridge_decoration.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';
import 'package:expense_tracker/ui_bridge/bridge_border_radius.dart';

enum CategoryTypeFilter { expense, income }

Future<Category?> showCategoryPicker(
  BuildContext context,
  CategoryTypeFilter categoryType,
  List<Category> categories,
) async {
  return await showModalBottomSheet<Category?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BridgeBorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (builderContext) {
      return CategoryPickerDialogContent(
        categoryType: categoryType,
        categories: categories,
      );
    },
  );
}

class CategoryPickerDialogContent extends StatefulWidget {
  final CategoryTypeFilter categoryType;
  final List<Category> categories;
  const CategoryPickerDialogContent({
    super.key,
    required this.categoryType,
    required this.categories,
  });

  @override
  State<CategoryPickerDialogContent> createState() =>
      _CategoryPickerDialogContentState();
}

class _CategoryPickerDialogContentState
    extends State<CategoryPickerDialogContent> {
  final TextEditingController _searchController = TextEditingController();
  List<Category> _allCategories = [];
  List<Category> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    final uncategorizedId = Category.uncategorized.id;
    _allCategories =
        widget.categories.where((c) => c.id != uncategorizedId).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    _filteredCategories = List.from(_allCategories);
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCategories);
    _searchController.dispose();
    super.dispose();
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategories = _allCategories
          .where((category) => category.name.toLowerCase().contains(query))
          .toList();
    });
  }

  void _navigateToAddCategory() {
    Navigator.pop(context);
    final categoryType = widget.categoryType == CategoryTypeFilter.expense
        ? CategoryType.expense
        : CategoryType.income;
    context.push(
      '${RouteNames.budgetsAndCats}/${RouteNames.manageCategories}/${RouteNames.addCategory}',
      extra: {'initialType': categoryType},
    );
    log.info(
      "[CategoryPicker] Navigating to Add Category screen for type: ${categoryType.name}.",
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * 0.7;

    return Container(
      height: sheetHeight,
      padding: const BridgeEdgeInsets.only(
        top: 8.0,
        left: 16.0,
        right: 16.0,
        bottom: 8.0,
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const BridgeEdgeInsets.only(bottom: 10),
              decoration: BridgeDecoration(
                color: Colors.grey[300],
                borderRadius: BridgeBorderRadius.circular(10),
              ),
            ),
          ),
          Text(
            "Select ${widget.categoryType == CategoryTypeFilter.expense ? 'Expense' : 'Income'} Category",
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search categories...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BridgeBorderRadius.circular(30),
              ),
              contentPadding: const BridgeEdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _filteredCategories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No Categories Found'
                              : 'No matching categories found.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, index) {
                      final Category category = _filteredCategories[index];
                      final iconData =
                          availableIcons[category.iconName] ??
                          Icons.category_outlined;
                      return BridgeListTile(
                        leading: CircleAvatar(
                          backgroundColor: category.displayColor.withOpacity(
                            0.15,
                          ),
                          child: Icon(
                            iconData,
                            color: category.displayColor,
                            size: 20,
                          ),
                        ),
                        title: Text(category.name),
                        onTap: () {
                          log.info(
                            "[CategoryPicker] Selected: ${category.name}",
                          );
                          Navigator.of(context).pop(category);
                        },
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const BridgeEdgeInsets.symmetric(vertical: 12.0),
            child: Center(
              child: ElevatedButton.icon(
                key: const ValueKey('button_add_new_category'),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text("Add New Category"),
                style: ElevatedButton.styleFrom(
                  padding: const BridgeEdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: theme.textTheme.labelLarge,
                ),
                onPressed: _navigateToAddCategory,
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom / 2),
        ],
      ),
    );
  }
}
