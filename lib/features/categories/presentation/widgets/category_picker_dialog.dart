import 'package:expense_tracker/core/constants/route_names.dart'; // For navigation
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart'; // Import type
import 'package:expense_tracker/features/categories/domain/usecases/get_expense_categories.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_income_categories.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart'; // For icon lookup
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter for push

// Enum Definition
enum CategoryTypeFilter { expense, income }

// Function to show the category picker modal bottom sheet
Future<Category?> showCategoryPicker(
  BuildContext context,
  CategoryTypeFilter categoryType,
) async {
  return await showModalBottomSheet<Category?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (builderContext) {
      return CategoryPickerDialogContent(categoryType: categoryType);
    },
  );
}

// Content widget for the bottom sheet
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
      // Exclude 'Uncategorized' from the picker list
      _allCategories = categories
          .where((cat) => cat.id != Category.uncategorized.id)
          .toList();
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

  // --- Navigate to Add Category ---
  void _navigateToAddCategory() {
    Navigator.pop(context); // Close the picker first

    // Determine the type to pass to the Add Category screen
    final categoryType = widget.categoryType == CategoryTypeFilter.expense
        ? CategoryType.expense
        : CategoryType.income;

    // Navigate using the defined route structure
    // This assumes AddEditCategoryScreen can handle the initialType parameter
    context.push(
      '${RouteNames.budgetsAndCats}/${RouteNames.manageCategories}/${RouteNames.addCategory}',
      // Optionally pass the type as extra data if AddEditCategoryScreen doesn't take constructor params for this
      // extra: {'initialType': categoryType} // Example if using extra
    );
    log.info(
        "[CategoryPicker] Navigating to Add Category screen for type: ${categoryType.name}.");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * 0.7; // Adjusted height

    return Container(
      height: sheetHeight,
      padding:
          const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0, bottom: 8.0),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10)),
          ),
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
                              final category = _filteredCategories[index];
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
                                  Navigator.of(context)
                                      .pop(category); // Return selected
                                },
                              );
                            },
                          ),
          ),
          const Divider(height: 1),
          // --- ADDED: Add New Category Button ---
          ListTile(
            leading: Icon(Icons.add_circle_outline,
                color: theme.colorScheme.primary),
            title: Text("Add New Category",
                style: TextStyle(color: theme.colorScheme.primary)),
            onTap: _navigateToAddCategory, // Call the navigation function
            contentPadding:
                const EdgeInsets.symmetric(vertical: 4.0), // Adjust padding
          ),
          SizedBox(
              height: MediaQuery.of(context).padding.bottom /
                  2), // SafeArea padding
          // --- END ADDED ---
        ],
      ),
    );
  }
}
