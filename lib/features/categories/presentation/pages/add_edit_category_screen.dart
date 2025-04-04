// lib/features/categories/presentation/pages/add_edit_category_screen.dart
// MODIFIED FILE (Implement UI)
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/widgets/app_text_form_field.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:expense_tracker/core/utils/color_utils.dart';
import 'package:expense_tracker/main.dart';

class AddEditCategoryScreen extends StatelessWidget {
  final Category? initialCategory;

  const AddEditCategoryScreen({super.key, this.initialCategory});

  @override
  Widget build(BuildContext context) {
    final bool isEditing = initialCategory != null;
    // Assuming CategoryManagementBloc is provided via BlocProvider.value in CategoryManagementScreen
    // If navigating differently, ensure the Bloc is available here.

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Category' : 'Add Category'),
        leading: IconButton(
          // Add explicit back button
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // Use SafeArea to avoid overlaps
      body: SafeArea(
        child: CategoryForm(
          initialCategory: initialCategory,
          onSubmit: (name, iconName, colorHex) {
            log.info(
                "[AddEditCategoryScreen] Form submitted. Name: $name, Icon: $iconName, Color: $colorHex");
            final bloc = context.read<CategoryManagementBloc>();
            if (isEditing) {
              final updatedCategory = Category(
                // Create the updated entity
                id: initialCategory!.id,
                name: name, iconName: iconName, colorHex: colorHex,
                isCustom: initialCategory!
                    .isCustom, // Preserve original custom status
                parentCategoryId:
                    initialCategory!.parentCategoryId, // Preserve parent
              );
              bloc.add(UpdateCategory(category: updatedCategory));
            } else {
              bloc.add(AddCategory(
                  name: name, iconName: iconName, colorHex: colorHex));
            }
            Navigator.of(context).pop(); // Pop after submitting
          },
        ),
      ),
    );
  }
}

// --- Category Form Widget ---
class CategoryForm extends StatefulWidget {
  final Category? initialCategory;
  final Function(String name, String iconName, String colorHex) onSubmit;

  const CategoryForm({
    super.key,
    this.initialCategory,
    required this.onSubmit,
  });

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String _selectedIconName = 'default_category_icon';
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialCategory?.name ?? '');
    _selectedIconName =
        widget.initialCategory?.iconName ?? 'default_category_icon';
    // Use ColorUtils to parse hex, default if editing or adding
    _selectedColor = widget.initialCategory != null
        ? ColorUtils.fromHex(widget.initialCategory!.colorHex)
        : Colors.blue;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _nameController.text.trim(),
        _selectedIconName,
        ColorUtils.toHex(_selectedColor),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please correct the errors in the form.')));
    }
  }

  // Show Icon Picker
  void _showIconPicker() async {
    log.info("[CategoryForm] Icon picker requested");
    final String? selectedIcon =
        await showIconPicker(context, _selectedIconName);
    if (selectedIcon != null && selectedIcon != _selectedIconName) {
      log.info("[CategoryForm] New Icon selected: $selectedIcon");
      setState(() => _selectedIconName = selectedIcon);
    } else {
      log.info("[CategoryForm] Icon selection cancelled or unchanged.");
    }
  }

  // Show Color Picker (with accessibility check example)
  void _showColorPicker() {
    log.info("[CategoryForm] Color picker requested.");
    Color pickerColor = _selectedColor; // Temp color for picker
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor, // Use temp color
            onColorChanged: (color) => pickerColor = color, // Update temp color
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false,
            // --- Accessibility Check Example (Simple Contrast) ---
            colorPickerWidth: 300,
            displayThumbColor: true,
            paletteType: PaletteType.hueWheel, // Or other types
            labelTypes: const [ColorLabelType.hex],
            pickerAreaBorderRadius: BorderRadius.circular(8),
            // You might add custom actions or previews here to check contrast
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
              child: const Text('Select'),
              onPressed: () {
                // Basic contrast check (example against white text)
                // Use a proper accessibility library for robust checks
                final contrast =
                    ThemeData.estimateBrightnessForColor(pickerColor);
                if (contrast == Brightness.light) {
                  log.warning(
                      "[CategoryForm] Selected color might have low contrast with white text.");
                  // Optionally show another warning dialog
                }
                setState(
                    () => _selectedColor = pickerColor); // Set the actual color
                Navigator.of(context).pop();
              }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeTheme = context.modeTheme;
    final theme = Theme.of(context);
    // Get IconData for display
    final IconData displayIconData =
        availableIcons[_selectedIconName] ?? Icons.category_outlined;

    return Form(
      key: _formKey,
      child: ListView(
        // Use ListView for scrollability on small screens
        padding: modeTheme?.pagePadding ?? const EdgeInsets.all(16.0),
        children: [
          AppTextFormField(
              controller: _nameController,
              labelText: 'Category Name',
              prefixIconData: Icons.label_outline,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return 'Please enter a category name';
                // TODO: Add check for name uniqueness against state.categories in BlocListener or here
                return null;
              }),
          const SizedBox(height: 20),
          Text("Appearance", style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          // Icon Picker Tile
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 0), // No padding needed if inside ListView padding
            shape: RoundedRectangleBorder(
                side: BorderSide(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(12) // Match input border
                ),
            tileColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            leading: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Icon(displayIconData,
                  color: _selectedColor,
                  size: 28), // Show selected icon colored
            ),
            title: const Text('Icon'),
            subtitle: Text(_selectedIconName),
            trailing: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child:
                  Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
            ),
            onTap: _showIconPicker,
          ),
          const SizedBox(height: 16),
          // Color Picker Tile
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            shape: RoundedRectangleBorder(
                side: BorderSide(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(12) // Match input border
                ),
            tileColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            leading: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Icon(Icons.color_lens_outlined,
                  color: _selectedColor, size: 28),
            ),
            title: const Text('Color'),
            subtitle: Text(ColorUtils.toHex(_selectedColor)),
            trailing: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.dividerColor)),
              ),
            ),
            onTap: _showColorPicker,
          ),
          // TODO: Add Parent Category Selector if implementing sub-categories
          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: Text(widget.initialCategory == null
                ? 'Add Category'
                : 'Update Category'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: theme.textTheme.titleMedium,
            ),
            onPressed: _submitForm,
          ),
        ],
      ),
    );
  }
}
