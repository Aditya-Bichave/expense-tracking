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
  late List<Category> _sortedCategories;

  @override
  void initState() {
    super.initState();
    _sortCategories();
  }

  @override
  void didUpdateWidget(CategoryListSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categories != oldWidget.categories) {
      _sortCategories();
    }
  }

  void _sortCategories() {
    // ⚡ Bolt Performance Optimization
    // Problem: a.name.toLowerCase() inside .sort() allocates O(N log N) strings during widget build
    // Solution: Cache lowercased names outside the sort function
    // Impact: Improves UI rendering speed by avoiding tight-loop allocations
    final lowerCaseNames = {
      for (var c in widget.categories) c.id: c.name.toLowerCase(),
    };

    // Copy to avoid mutating the original list
    _sortedCategories = List.from(widget.categories)
      ..sort((a, b) => lowerCaseNames[a.id]!.compareTo(lowerCaseNames[b.id]!));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_sortedCategories.isEmpty) {
      return Center(
        child: Padding(
          padding: context.space.allXl,
          child: Text(widget.emptyMessage, style: theme.textTheme.titleMedium),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0, bottom: 90.0), // Padding for FAB
      itemCount: _sortedCategories.length,
      itemBuilder: (context, index) {
        final category = _sortedCategories[index];
        return CategoryListItemWidget(
              category: category,
              onEdit: () => widget.onEditCategory(category),
              onDelete: () => widget.onDeleteCategory(category),
              onPersonalize: () => widget.onPersonalizeCategory(category),
            )
            .animate()
            .fadeIn(delay: (40 * index).ms, duration: 300.ms)
            .slideY(begin: 0.1, curve: Curves.easeOut);
      },
    );
  }
}
