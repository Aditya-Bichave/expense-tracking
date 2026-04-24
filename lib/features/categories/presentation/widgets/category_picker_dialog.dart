// lib/features/categories/presentation/widgets/category_picker_dialog.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'dart:async';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/ui_bridge/bridge_list_tile.dart';
import 'package:expense_tracker/ui_bridge/bridge_decoration.dart';
import 'package:expense_tracker/ui_bridge/bridge_border_radius.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

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
  Timer? _debounce;
  Map<String, String> _lowerCaseNames = {};

  @override
  void initState() {
    super.initState();
    final uncategorizedId = Category.uncategorized.id;

    // ⚡ Bolt Performance Optimization
    // Problem: a.name.toLowerCase() inside .sort() allocates O(N log N) strings during dialog load
    // Solution: Cache lowercased names outside the sort function
    // Impact: Improves dialog open speed by reducing CPU cycles and garbage collection
    _lowerCaseNames = {
      for (var c in widget.categories) c.id: c.name.toLowerCase(),
    };

    _allCategories = <Category>[];
    for (final c in widget.categories) {
      if (c.id != uncategorizedId) {
        _allCategories.add(c);
      }
    }
    _allCategories.sort(
      (a, b) => _lowerCaseNames[a.id]!.compareTo(_lowerCaseNames[b.id]!),
    );
    // ⚡ Bolt Performance Optimization
    // Problem: List.from creates a full clone which is unnecessary when we just need a reference to the sorted list
    // Solution: Assign the reference directly. _filterCategories reassings _filteredCategories instead of mutating.
    // Impact: Avoids unnecessary O(N) memory allocation and copy.
    _filteredCategories = _allCategories;
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCategories);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ⚡ Bolt Performance Optimization
  // Problem: Re-calculating lowercased names and filtering on every keystroke
  // Solution: Debounce the search input using Dart's async features
  // Impact: Reduces UI jank and unnecessary re-renders when typing fast
  void _filterCategories() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.toLowerCase();
      setState(() {
        // ⚡ Bolt Performance Optimization
        // Problem: `category.name.toLowerCase()` allocates strings during the search loop
        // Solution: Use the cached _lowerCaseNames map we already computed!
        // Impact: Further reduces lag when searching categories
        _filteredCategories = <Category>[];
        for (final category in _allCategories) {
          if (_lowerCaseNames[category.id]!.contains(query)) {
            _filteredCategories.add(category);
          }
        }
      });
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
      padding: const EdgeInsets.only(
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
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BridgeDecoration(
                color: context.kit.colors.borderSubtle.withOpacity(0.3),
                borderRadius: context.kit.radii.small,
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
              contentPadding: const EdgeInsets.symmetric(
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
          Divider(height: 1),
          Padding(
            padding: context.space.vMd,
            child: Center(
              child: ElevatedButton.icon(
                key: const ValueKey('button_add_new_category'),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text("Add New Category"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
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
