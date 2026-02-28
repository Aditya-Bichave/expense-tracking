// lib/core/widgets/category_selector_multi_tile.dart
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart'; // For icons
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:collection/collection.dart';
import 'package:expense_tracker/ui_bridge/bridge_list_tile.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';
import 'package:expense_tracker/ui_bridge/bridge_border_radius.dart';

class CategorySelectorMultiTile extends StatelessWidget {
  final List<String> selectedCategoryIds;
  final List<Category> availableCategories; // To look up names/icons
  final String label;
  final String hint;
  final VoidCallback onTap; // Triggers the multi-select sheet
  final String? errorText;

  const CategorySelectorMultiTile({
    super.key,
    required this.selectedCategoryIds,
    required this.availableCategories,
    required this.onTap,
    this.label = 'Categories',
    this.hint = 'Select Categories',
    this.errorText,
  });

  // Helper to get display icons (similar to BudgetCard)
  List<Widget> _getDisplayIcons(BuildContext context, int maxIcons) {
    final modeTheme = context.modeTheme;
    List<Widget> iconWidgets = [];
    int count = 0;
    for (String id in selectedCategoryIds) {
      if (count >= maxIcons) break;
      final category = availableCategories.firstWhereOrNull((c) => c.id == id);
      if (category != null) {
        final iconColor = category.displayColor;
        Widget iconWidget;
        IconData fallbackIcon =
            availableIcons[category.iconName] ?? Icons.label;

        if (modeTheme != null) {
          String svgPath = modeTheme.assets.getCategoryIcon(
            category.iconName,
            defaultPath: '',
          );
          if (svgPath.isNotEmpty) {
            iconWidget = SvgPicture.asset(
              svgPath,
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            );
          } else {
            iconWidget = Icon(fallbackIcon, size: 16, color: iconColor);
          }
        } else {
          iconWidget = Icon(fallbackIcon, size: 16, color: iconColor);
        }
        iconWidgets.add(
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 3.0),
            child: iconWidget,
          ),
        );
        count++;
      }
    }
    if (selectedCategoryIds.length > maxIcons) {
      iconWidgets.add(
        Text(
          '+${selectedCategoryIds.length - maxIcons}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      );
    }
    return iconWidgets;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasError = errorText != null && errorText!.isNotEmpty;
    final bool isSelectionEmpty = selectedCategoryIds.isEmpty;

    // Determine display text
    String titleText = isSelectionEmpty
        ? hint
        : '${selectedCategoryIds.length} Categories Selected';
    TextStyle? titleStyle = theme.textTheme.bodyLarge;
    if (isSelectionEmpty) {
      titleStyle = titleStyle?.copyWith(color: theme.disabledColor);
    }
    if (hasError) {
      titleStyle = titleStyle?.copyWith(color: theme.colorScheme.error);
    }

    // Determine leading icons (show max 3)
    final leadingIcons = _getDisplayIcons(context, 3);

    // Determine border style
    BorderRadius inputBorderRadius = BridgeBorderRadius.circular(8.0);
    final borderConfig = theme.inputDecorationTheme.enabledBorder;
    BorderSide borderSide =
        theme.inputDecorationTheme.enabledBorder?.borderSide ??
        BorderSide(color: theme.dividerColor);
    if (hasError) {
      final errorBorderConfig = theme.inputDecorationTheme.errorBorder;
      if (errorBorderConfig is OutlineInputBorder) {
        borderSide = errorBorderConfig.borderSide;
      } else {
        borderSide = BorderSide(color: theme.colorScheme.error, width: 1.5);
      }
    }
    if (borderConfig is OutlineInputBorder) {
      inputBorderRadius = borderConfig.borderRadius;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BridgeListTile(
          contentPadding: const BridgeEdgeInsets.symmetric(horizontal: 12),
          shape: OutlineInputBorder(
            borderRadius: inputBorderRadius,
            borderSide: borderSide,
          ),
          // Show generic category icon or first few selected icons
          leading: isSelectionEmpty
              ? Icon(Icons.category_outlined, color: theme.disabledColor)
              : Row(mainAxisSize: MainAxisSize.min, children: leadingIcons),
          title: Text(titleText, style: titleStyle),
          trailing: const Icon(Icons.arrow_drop_down),
          onTap: onTap,
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 12.0, top: 8.0),
            child: Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
