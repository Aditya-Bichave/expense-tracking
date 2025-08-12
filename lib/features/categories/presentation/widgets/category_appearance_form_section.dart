// lib/features/categories/presentation/widgets/category_appearance_form_section.dart
import 'package:expense_tracker/core/utils/color_utils.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
    final String? selectedIcon =
        await showIconPicker(context, selectedIconName);
    if (selectedIcon != null && selectedIcon != selectedIconName) {
      onIconSelected(selectedIcon);
    }
  }

  void _showColorPicker(BuildContext context) {
    Color pickerColor = selectedColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            pickerAreaBorderRadius: BorderRadius.circular(8),
            hexInputBar: true,
          ),
        ),
        actions: <Widget>[
          TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop()),
          TextButton(
              child: const Text('Select'),
              onPressed: () {
                onColorSelected(pickerColor);
                Navigator.of(context).pop();
              }),
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
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
              side: BorderSide(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12)),
          tileColor: theme.colorScheme.surfaceContainerHighest,
          leading: Padding(
            padding: const EdgeInsets.only(left: 0.0),
            child: Icon(displayIconData, color: selectedColor, size: 28),
          ),
          title: const Text('Icon'),
          subtitle: Text(selectedIconName),
          trailing: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
          ),
          onTap: () => _showIconPicker(context),
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
              side: BorderSide(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12)),
          tileColor: theme.colorScheme.surfaceContainerHighest,
          leading: Padding(
            padding: const EdgeInsets.only(left: 0.0),
            child:
                Icon(Icons.color_lens_outlined, color: selectedColor, size: 28),
          ),
          title: const Text('Color'),
          subtitle: Text(ColorUtils.toHex(selectedColor)),
          trailing: Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                  color: selectedColor,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: theme.dividerColor.withAlpha((255 * 0.5).round()))),
            ),
          ),
          onTap: () => _showColorPicker(context),
        ),
      ],
    );
  }
}
