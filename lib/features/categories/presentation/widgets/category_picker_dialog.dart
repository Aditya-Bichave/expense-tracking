// lib/features/categories/presentation/widgets/category_picker_dialog.dart
// MODIFIED FILE
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_expense_categories.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_income_categories.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';

// --- MOVED Enum Definition Here ---
enum CategoryTypeFilter { expense, income }
// --- END MOVED Enum ---

// Function to show the category picker modal bottom sheet
Future<Category?> showCategoryPicker(
  BuildContext context,
  CategoryTypeFilter categoryType, // Uses the enum defined above
) async {
  return await showModalBottomSheet<Category?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (builderContext) {
      return CategoryPickerDialogContent(
          categoryType: categoryType); // Pass type
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
  // ... (State logic remains the same) ...
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
      categories.removeWhere((cat) => cat.id == Category.uncategorized.id);
      _allCategories = categories;
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

  @override
  Widget build(BuildContext context) {
    // ... (Build logic remains the same) ...
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * 0.65;
    return Container(
      height: sheetHeight,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10)),
          ),
          Text(
              "Select ${widget.categoryType == CategoryTypeFilter.expense ? 'Expense' : 'Income'} Category",
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
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
            ),
          ),
          const SizedBox(height: 16),
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
                              final iconWidget = Icon(Icons.category,
                                  color: category.displayColor, size: 20);
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      category.displayColor.withOpacity(0.15),
                                  child: iconWidget,
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
        ],
      ),
    );
  }
}
