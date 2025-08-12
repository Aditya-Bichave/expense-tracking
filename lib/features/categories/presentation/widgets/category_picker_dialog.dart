// lib/features/categories/presentation/widgets/category_picker_dialog.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_expense_categories.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_income_categories.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum CategoryTypeFilter { expense, income }

Future<Category?> showCategoryPicker(
    BuildContext context, CategoryTypeFilter categoryType) async {
  return await showModalBottomSheet<Category?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (builderContext) {
      return CategoryPickerDialogContent(categoryType: categoryType);
    },
  );
}

class CategoryPickerDialogContent extends StatefulWidget {
  final CategoryTypeFilter categoryType;
  const CategoryPickerDialogContent({super.key, required this.categoryType});
  @override
  State<CategoryPickerDialogContent> createState() =>
      _CategoryPickerDialogContentState();
}

class _CategoryPickerDialogContentState
    extends State<CategoryPickerDialogContent> {
  final GetExpenseCategoriesUseCase _getExpenseCategoriesUseCase =
      sl<GetExpenseCategoriesUseCase>();
  final GetIncomeCategoriesUseCase _getIncomeCategoriesUseCase =
      sl<GetIncomeCategoriesUseCase>();
  final TextEditingController _searchController = TextEditingController();
  List<Category> _allCategories = [];
  List<Category> _filteredCategories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAndFilterCategories();
    _searchController.addListener(_filterCategories);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCategories);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAndFilterCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = widget.categoryType == CategoryTypeFilter.expense
        ? await _getExpenseCategoriesUseCase(const NoParams())
        : await _getIncomeCategoriesUseCase(const NoParams());
    if (!mounted) return;
    result.fold((failure) {
      log.warning(
          "[CategoryPicker] Failed to load ${widget.categoryType.name} categories: ${failure.message}");
      setState(() {
        _isLoading = false;
        _error = "Could not load categories.";
        _allCategories = [];
        _filteredCategories = [];
      });
    }, (categories) {
      log.info(
          "[CategoryPicker] Loaded ${categories.length} ${widget.categoryType.name} categories.");
      final uncategorizedId = Category.uncategorized.id;
      _allCategories =
          categories.where((cat) => cat.id != uncategorizedId).toList();
      _allCategories
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _filterCategories();
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategories = _allCategories.where((category) {
        return category.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _navigateToAddCategory() {
    Navigator.pop(context);
    final categoryType = widget.categoryType == CategoryTypeFilter.expense
        ? CategoryType.expense
        : CategoryType.income;
    // Pass initialType via extra when pushing the route
    context.push(
        '${RouteNames.budgetsAndCats}/${RouteNames.manageCategories}/${RouteNames.addCategory}',
        extra: {'initialType': categoryType});
    log.info(
        "[CategoryPicker] Navigating to Add Category screen for type: ${categoryType.name}.");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * 0.7;

    return Container(
      height: sheetHeight,
      padding:
          const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0, bottom: 8.0),
      child: Column(
        children: [
          // Drag Handle
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10)))),
          // Title
          Text(
              "Select ${widget.categoryType == CategoryTypeFilter.expense ? 'Expense' : 'Income'} Category",
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search categories...",
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear())
                  : null,
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          // Category List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: TextStyle(color: theme.colorScheme.error)))
                    : _filteredCategories.isEmpty
                        ? Center(
                            child: Text(_searchController.text.isEmpty
                                ? 'No Categories Found'
                                : 'No matching categories found.'))
                        : ListView.builder(
                            itemCount: _filteredCategories.length,
                            itemBuilder: (context, index) {
                              final Category category =
                                  _filteredCategories[index];
                              final iconData =
                                  availableIcons[category.iconName] ??
                                      Icons.category_outlined;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      category.displayColor.withOpacity(0.15),
                                  child: Icon(iconData,
                                      color: category.displayColor, size: 20),
                                ),
                                title: Text(category.name),
                                onTap: () {
                                  log.info(
                                      "[CategoryPicker] Selected: ${category.name}");
                                  Navigator.of(context).pop(category);
                                },
                              );
                            },
                          ),
          ),
          const Divider(height: 1),
          // --- FIX: Enhanced "Add New Category" Button ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0), // Add padding
            child: Center(
              // Center the button
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text("Add New Category"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12), // Adjust padding
                  textStyle:
                      theme.textTheme.labelLarge, // Make text slightly larger
                ),
                onPressed: _navigateToAddCategory,
              ),
            ),
          ),
          // --- END FIX ---
          SizedBox(height: MediaQuery.of(context).padding.bottom / 2),
        ],
      ),
    );
  }
}
