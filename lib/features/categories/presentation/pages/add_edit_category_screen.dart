import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/widgets/app_text_form_field.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
// --- ADDED Import ---
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart';
// --- END ADDED ---
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
    // Assuming CategoryManagementBloc is provided by the navigator

    return Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Category' : 'Add Category'),
        ),
        body: CategoryForm(
          // Use a dedicated form widget
          initialCategory: initialCategory,
          onSubmit: (name, iconName, colorHex) {
            log.info(
                "[AddEditCategoryScreen] Form submitted. Name: $name, Icon: $iconName, Color: $colorHex");
            final bloc = context.read<CategoryManagementBloc>();
            if (isEditing) {
              // Create a NEW Category entity with updated values
              final updatedCategory = Category(
                id: initialCategory!.id, // Keep original ID
                name: name,
                iconName: iconName,
                colorHex: colorHex,
                isCustom:
                    initialCategory!.isCustom, // Keep original custom status
                parentCategoryId: initialCategory!.parentCategoryId,
              );
              bloc.add(UpdateCategory(category: updatedCategory));
            } else {
              bloc.add(AddCategory(
                  name: name, iconName: iconName, colorHex: colorHex));
            }
            // Pop *after* dispatching the event
            Navigator.of(context).pop();
          },
        ));
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
  // Use the string identifier for the icon name
  String _selectedIconName = 'default_category_icon'; // Default icon identifier
  Color _selectedColor = Colors.blue; // Default color

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialCategory?.name ?? '');
    _selectedIconName =
        widget.initialCategory?.iconName ?? 'default_category_icon';
    _selectedColor = widget.initialCategory?.displayColor ?? Colors.blue;
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

  // --- Update Icon Picker Call ---
  void _showIconPicker() async {
    log.info("[CategoryForm] Icon picker requested");
    // Call the dialog function
    final String? selectedIcon =
        await showIconPicker(context, _selectedIconName);
    if (selectedIcon != null && selectedIcon != _selectedIconName) {
      log.info("[CategoryForm] New Icon selected: $selectedIcon");
      setState(() => _selectedIconName = selectedIcon);
    } else {
      log.info("[CategoryForm] Icon selection cancelled or unchanged.");
    }
  }
  // --- END Update ---

  // Color Picker logic remains the same
  void _showColorPicker() {
    log.info("[CategoryForm] Color picker requested.");
    showDialog(
      /* ... ColorPicker Dialog ... */
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) => setState(() => _selectedColor = color),
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Got it'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeTheme = context.modeTheme;
    final theme = Theme.of(context);

    // Get the IconData for the currently selected icon name for display
    final IconData displayIconData =
        availableIcons[_selectedIconName] ?? Icons.help_outline;

    return Form(
      key: _formKey,
      child: ListView(
        padding: modeTheme?.pagePadding ?? const EdgeInsets.all(16.0),
        children: [
          AppTextFormField(
            controller: _nameController,
            labelText: 'Category Name',
            prefixIconData: Icons.label_outline,
            textCapitalization: TextCapitalization.words,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Please enter a category name'
                : null,
          ),
          const SizedBox(height: 16),
          // --- UPDATED Icon Picker Tile ---
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: theme.inputDecorationTheme.enabledBorder ??
                const OutlineInputBorder(),
            leading: Icon(displayIconData,
                color: theme.colorScheme.primary), // Show selected icon
            title: const Text('Icon'),
            subtitle: Text(_selectedIconName), // Display selected icon name
            trailing:
                Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
            onTap: _showIconPicker, // Open icon picker
          ),
          // --- END UPDATE ---
          const SizedBox(height: 16),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: theme.inputDecorationTheme.enabledBorder ??
                const OutlineInputBorder(),
            leading: Icon(Icons.color_lens_outlined, color: _selectedColor),
            title: const Text('Color'),
            subtitle: Text(ColorUtils.toHex(_selectedColor)),
            trailing: Container(
              width: 24,
              height: 24,
              color: _selectedColor,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                  color: _selectedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.dividerColor)),
            ),
            onTap: _showColorPicker,
          ),
          const SizedBox(height: 32),
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
