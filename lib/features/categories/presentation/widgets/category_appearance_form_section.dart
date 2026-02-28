// lib/features/categories/presentation/widgets/category_appearance_form_section.dart
import 'package:expense_tracker/core/utils/color_utils.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_button.dart';
import 'package:expense_tracker/ui_bridge/bridge_list_tile.dart';
import 'package:expense_tracker/ui_bridge/bridge_alert_dialog.dart';
import 'package:expense_tracker/ui_bridge/bridge_decoration.dart';
import 'package:expense_tracker/ui_bridge/bridge_border_radius.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class CategoryAppearanceFormSection extends StatelessWidget {
  final String selectedIconName;
  final Color selectedColor;
  final ValueChanged<String> onIconSelected;
  final ValueChanged<Color> onColorSelected;

  const CategoryAppearanceFormSection({
    super.key,
    required this.selectedIconName,
    required this.selectedColor,
    required this.onIconSelected,
    required this.onColorSelected,
  });

  void _showIconPicker(BuildContext context) async {
    final String? selectedIcon = await showIconPicker(
      context,
      selectedIconName,
    );
    if (selectedIcon != null && selectedIcon != selectedIconName) {
      onIconSelected(selectedIcon);
    }
  }

  void _showColorPicker(BuildContext context) {
    Color pickerColor = selectedColor;
    showDialog(
      context: context,
      builder: (context) => BridgeAlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false,
            colorPickerWidth: 300,
            displayThumbColor: true,
            paletteType: PaletteType.hsvWithHue,
            labelTypes: const [ColorLabelType.hex],
            pickerAreaBorderRadius: context.kit.radii.small,
            hexInputBar: true,
          ),
        ),
        actions: <Widget>[
          BridgeTextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          BridgeTextButton(
            child: const Text('Select'),
            onPressed: () {
              onColorSelected(pickerColor);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final IconData displayIconData =
        availableIcons[selectedIconName] ?? Icons.category_outlined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Appearance", style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        BridgeListTile(
          contentPadding: context.space.hMd,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: theme.dividerColor),
            borderRadius: context.kit.radii.medium,
          ),
          tileColor: theme.colorScheme.surfaceContainerHighest,
          leading: Padding(
            padding: const EdgeInsetsDirectional.only(start: 0.0),
            child: Icon(displayIconData, color: selectedColor, size: 28),
          ),
          title: const Text('Icon'),
          subtitle: Text(selectedIconName),
          trailing: Padding(
            padding: const EdgeInsetsDirectional.only(end: 8.0),
            child: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
          ),
          onTap: () => _showIconPicker(context),
        ),
        const SizedBox(height: 16),
        BridgeListTile(
          contentPadding: context.space.hMd,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: theme.dividerColor),
            borderRadius: context.kit.radii.medium,
          ),
          tileColor: theme.colorScheme.surfaceContainerHighest,
          leading: Padding(
            padding: const EdgeInsetsDirectional.only(start: 0.0),
            child: Icon(
              Icons.color_lens_outlined,
              color: selectedColor,
              size: 28,
            ),
          ),
          title: const Text('Color'),
          subtitle: Text(ColorUtils.toHex(selectedColor)),
          trailing: Padding(
            padding: const EdgeInsetsDirectional.only(end: 12.0),
            child: Container(
              width: 24,
              height: 24,
              decoration: BridgeDecoration(
                color: selectedColor,
                shape: BoxShape.circle,
                border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
              ),
            ),
          ),
          onTap: () => _showColorPicker(context),
        ),
      ],
    );
  }
}
