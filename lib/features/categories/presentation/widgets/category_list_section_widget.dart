// lib/features/categories/presentation/widgets/category_list_section_widget.dart
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CategoryListSectionWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (categories.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(emptyMessage, style: theme.textTheme.titleMedium)));
    }
    // Sort combined list for consistent display
    categories
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

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
