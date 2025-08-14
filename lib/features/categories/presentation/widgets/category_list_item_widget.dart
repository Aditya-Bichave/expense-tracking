// lib/features/categories/presentation/widgets/category_list_item_widget.dart
import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart';
import 'package:flutter/material.dart';

class CategoryListItemWidget extends StatelessWidget {
  final Category category;
  final VoidCallback? onEdit; // Callback for edit action
  final VoidCallback? onDelete; // Callback for delete action
  final VoidCallback? onPersonalize; // Callback for personalize action

  const CategoryListItemWidget({
    super.key,
    required this.category,
    this.onEdit,
    this.onDelete,
    this.onPersonalize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final IconData displayIconData =
        availableIcons[category.iconName] ?? Icons.category_outlined;

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: EdgeInsets.zero, // Let ListTile handle padding
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.displayColor.withOpacity(0.15),
          foregroundColor: category.displayColor.computeLuminance() > 0.5
              ? Colors.black54
              : null, // Contrast foreground
          child: Icon(displayIconData, color: category.displayColor, size: 20),
        ),
        title: Text(category.name),
        trailing: category.isCustom
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      iconSize: 20,
                      color: theme.colorScheme.secondary,
                      padding: EdgeInsets.zero,
                      tooltip: 'Edit Category',
                      onPressed: onEdit, // Use callback
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      iconSize: 20,
                      color: theme.colorScheme.error,
                      padding: EdgeInsets.zero,
                      tooltip: 'Delete Category',
                      onPressed: onDelete, // Use callback
                    ),
                  ),
                ],
              )
            : SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  // Action for predefined (personalize icon)
                  icon: const Icon(Icons.palette_outlined),
                  iconSize: 20,
                  color: theme.colorScheme.secondary,
                  padding: EdgeInsets.zero,
                  tooltip: 'Personalize Icon/Color (Coming Soon)',
                  onPressed: onPersonalize, // Use callback
                ),
              ),
      ),
    );
  }
}
