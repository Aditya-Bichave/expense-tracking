// lib/core/widgets/category_selector_tile.dart
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:expense_tracker/ui_bridge/bridge_list_tile.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_style.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';
import 'package:expense_tracker/ui_bridge/bridge_border_radius.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class CategorySelectorTile extends StatelessWidget {
  final Category? selectedCategory;
  final String label;
  final String hint;
  final VoidCallback onTap;
  final String? errorText;
  // --- ADDED: Receive uncategorized category for placeholder ---
  final Category uncategorizedCategory;
  // --- END ADD ---

  const CategorySelectorTile({
    super.key,
    required this.selectedCategory,
    required this.onTap,
    this.label = 'Category', // Changed default label
    this.hint = 'Select Category',
    this.errorText,
    required this.uncategorizedCategory, // Make required
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;
    final bool hasError = errorText != null && errorText!.isNotEmpty;

    // --- Use uncategorized placeholder if selected is null ---
    final Category displayPlaceholder =
        selectedCategory ?? uncategorizedCategory;
    Color displayColor =
        selectedCategory?.displayColor ??
        theme.disabledColor; // Use disabled color if null
    Widget leadingWidget;
    // --- End Use ---

    // Icon Logic (remains similar, uses displayPlaceholder for iconName)
    String? svgPath;
    if (modeTheme != null) {
      svgPath = modeTheme.assets.getCategoryIcon(
        displayPlaceholder.iconName,
        defaultPath: '',
      );
    }
    if (svgPath != null && svgPath.isNotEmpty) {
      leadingWidget = Padding(
        padding: const context.space.allSm,
        child: SvgPicture.asset(
          svgPath,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(displayColor, BlendMode.srcIn),
        ),
      );
    } else {
      final iconData =
          availableIcons[displayPlaceholder.iconName] ?? Icons.help_outline;
      leadingWidget = Icon(iconData, color: displayColor);
    }

    BorderRadius inputBorderRadius = Bridgecontext.kit.radii.small;
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
          contentPadding: const context.space.hMd,
          shape: OutlineInputBorder(
            borderRadius: inputBorderRadius,
            borderSide: borderSide,
          ),
          leading: leadingWidget,
          title: Text(
            selectedCategory?.name ?? hint,
            style: BridgeTextStyle(
              color: hasError
                  ? theme.colorScheme.error
                  : (selectedCategory == null ? theme.disabledColor : null),
            ),
          ),
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
