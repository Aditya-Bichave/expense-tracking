// lib/features/categories/presentation/widgets/category_list_section_widget.dart
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class CategoryListSectionWidget extends StatefulWidget {
  final List<Category> categories;
  final String emptyMessage;
  final Function(Category) onEditCategory;
  final Function(Category) onDeleteCategory;
  final Function(Category) onPersonalizeCategory;

  const CategoryListSectionWidget({
    super.key,
    required this.categories,
    required this.emptyMessage,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onPersonalizeCategory,
  });

  @override
  State<CategoryListSectionWidget> createState() =>
      _CategoryListSectionWidgetState();
}

class _CategoryListSectionWidgetState extends State<CategoryListSectionWidget> {
  List<Category>? _previousCategories;

  @override
  Widget build(BuildContext context) {
    final categories = widget.categories;
    final emptyMessage = widget.emptyMessage;
    final onEditCategory = widget.onEditCategory;
    final onDeleteCategory = widget.onDeleteCategory;
    final onPersonalizeCategory = widget.onPersonalizeCategory;
    final theme = Theme.of(context);
    if (categories.isEmpty) {
      return Center(
        child: Padding(
          padding: context.space.allXl,
          child: Text(emptyMessage, style: theme.textTheme.titleMedium),
        ),
      );
    }
    // ⚡ Bolt Performance Optimization
    // Problem: a.name.toLowerCase() inside .sort() allocates O(N log N) strings during widget build
    // Solution: Cache lowercased names outside the sort function
    // Impact: Improves UI rendering speed by avoiding tight-loop allocations
    if (_previousCategories != categories) {
      final lowerCaseNames = {
        for (var c in categories) c.id: c.name.toLowerCase(),
      };

      // Sort combined list for consistent display
      categories.sort(
        (a, b) => lowerCaseNames[a.id]!.compareTo(lowerCaseNames[b.id]!),
      );
      _previousCategories = categories;
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0, bottom: 90.0), // Padding for FAB
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryListItemWidget(
              category: category,
              onEdit: () => onEditCategory(category),
              onDelete: () => onDeleteCategory(category),
              onPersonalize: () => onPersonalizeCategory(category),
            )
            .animate()
            .fadeIn(delay: (40 * index).ms, duration: 300.ms)
            .slideY(begin: 0.1, curve: Curves.easeOut);
      },
    );
  }
}
