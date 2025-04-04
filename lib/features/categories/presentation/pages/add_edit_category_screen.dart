import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/widgets/app_text_form_field.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart'; // Import enum
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
    log.info(
        "[AddEditCategoryScreen] Building. Editing: $isEditing. Category: ${initialCategory?.name}");

    // CategoryManagementBloc is expected to be provided by the route or parent widget
    // (e.g., via BlocProvider.value from CategoryManagementScreen)

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Category' : 'Add Category'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: CategoryForm(
          initialCategory: initialCategory,
          onSubmit: (name, iconName, colorHex, type, parentId) {
            log.info(
                "[AddEditCategoryScreen] Form submitted. Name: $name, Icon: $iconName, Color: $colorHex, Type: ${type.name}, Parent: $parentId");
            final bloc = context.read<CategoryManagementBloc>();
            if (isEditing) {
              // Ensure we don't change the type or custom status on edit
              final updatedCategory = initialCategory!.copyWith(
                name: name,
                iconName: iconName,
                colorHex: colorHex,
                // Type and isCustom should not change during edit
                // parentId update logic if subcategories are implemented
              );
              bloc.add(UpdateCategory(category: updatedCategory));
            } else {
              // Pass the selected type when adding
              bloc.add(AddCategory(
                name: name,
                iconName: iconName,
                colorHex: colorHex,
                type: type, // Pass type for new category
                parentId: parentId, // Pass parent for new subcategory
              ));
            }
            Navigator.of(context).pop(); // Pop back after submitting
          },
        ),
      ),
    );
  }
}

// --- Category Form Widget ---
class CategoryForm extends StatefulWidget {
  final Category? initialCategory;
  // Updated signature includes CategoryType and optional parentId
  final Function(String name, String iconName, String colorHex,
      CategoryType type, String? parentId) onSubmit;

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
  String _selectedIconName = 'category'; // Default icon name
  Color _selectedColor = Colors.blue;
  CategoryType _selectedType =
      CategoryType.expense; // Default type for new categories
  String? _selectedParentId; // For subcategories later

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCategory;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _selectedIconName = initial?.iconName ?? 'category';
    _selectedColor =
        initial != null ? ColorUtils.fromHex(initial.colorHex) : Colors.blue;
    // IMPORTANT: Do not change type when editing! Only set initial type if editing.
    _selectedType = initial?.type ?? CategoryType.expense;
    _selectedParentId = initial?.parentCategoryId;
    log.info(
        "[CategoryForm] initState. Initial Type: ${_selectedType.name}, Icon: $_selectedIconName, Color: $_selectedColor");
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      log.info(
          "[CategoryForm] Form validated. Submitting with Type: ${_selectedType.name}, Parent: $_selectedParentId");
      widget.onSubmit(
        _nameController.text.trim(),
        _selectedIconName,
        ColorUtils.toHex(_selectedColor),
        _selectedType, // Pass the selected type
        _selectedParentId, // Pass the selected parent ID
      );
    } else {
      log.warning("[CategoryForm] Form validation failed.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please correct the errors in the form.'),
          backgroundColor: Colors.orangeAccent));
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

  // Show Color Picker
  void _showColorPicker() {
    log.info("[CategoryForm] Color picker requested.");
    Color pickerColor = _selectedColor; // Start with current color
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) =>
                pickerColor = color, // Update temporary color
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false, // Disable alpha for category colors
            colorPickerWidth: 300, // Adjust width as needed
            displayThumbColor: true,
            paletteType: PaletteType.hsvWithHue, // Or other palette types
            labelTypes: const [ColorLabelType.hex],
            pickerAreaBorderRadius: BorderRadius.circular(8),
            hexInputBar: true, // Show hex input
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
                // TODO: Add contrast check against common background colors if desired
                log.info("[CategoryForm] New Color selected: $pickerColor");
                setState(
                    () => _selectedColor = pickerColor); // Update final color
                Navigator.of(context).pop();
              }),
        ],
      ),
    );
  }

  // Placeholder for Parent Category Picker (Implement when needed)
  void _showParentPicker() {
    log.warning("[CategoryForm] Parent Category Picker not implemented yet.");
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sub-category selection coming soon!")));
    // Implementation would involve:
    // 1. Fetching existing categories (of the same _selectedType).
    // 2. Showing a dialog/modal with a searchable list.
    // 3. Allowing selection of a parent or "None".
    // 4. Updating _selectedParentId state.
  }

  @override
  Widget build(BuildContext context) {
    final modeTheme = context.modeTheme;
    final theme = Theme.of(context);
    final IconData displayIconData =
        availableIcons[_selectedIconName] ?? Icons.category_outlined;
    final bool isEditing = widget.initialCategory != null;

    return Form(
      key: _formKey,
      child: ListView(
        padding: modeTheme?.pagePadding ?? const EdgeInsets.all(16.0),
        children: [
          // --- Category Type Selector (Only for Adding) ---
          if (!isEditing)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: DropdownButtonFormField<CategoryType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Category Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.swap_horiz_outlined),
                  hintText: 'Select if Expense or Income',
                ),
                items: CategoryType.values.map((type) {
                  return DropdownMenuItem<CategoryType>(
                    value: type,
                    child: Text(type.name.capitalize()), // Capitalize name
                  );
                }).toList(),
                onChanged: (CategoryType? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedType = newValue);
                  }
                },
                validator: (value) =>
                    value == null ? 'Please select a type' : null,
              ),
            )
          else // Show read-only type when editing
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: InputDecorator(
                // Use InputDecorator for consistent styling
                decoration: InputDecoration(
                  labelText: 'Category Type',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.swap_horiz_outlined),
                  // Style to look disabled
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: theme.disabledColor.withOpacity(0.5)),
                  ),
                  filled: true,
                  fillColor: theme.disabledColor.withOpacity(0.05),
                ),
                child: Text(_selectedType.name.capitalize(),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.disabledColor)),
              ),
            ),

          // --- Category Name ---
          AppTextFormField(
              controller: _nameController,
              labelText: 'Category Name',
              prefixIconData: Icons.label_outline,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a category name';
                }
                // TODO: Add check for name uniqueness within the same type/parent
                return null;
              }),
          const SizedBox(height: 20),

          // --- Parent Category Selector (Placeholder UI) ---
          ListTile(
            leading: const Icon(Icons.account_tree_outlined),
            title: const Text("Parent Category"),
            subtitle: Text(_selectedParentId ?? "None (Top Level)"),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showParentPicker, // Calls the placeholder function
            shape: RoundedRectangleBorder(
                side: BorderSide(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8)),
            tileColor: theme.colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 20),

          // --- Appearance Section ---
          Text("Appearance", style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          // Icon Picker Tile
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
                side: BorderSide(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(12)),
            tileColor: theme.colorScheme.surfaceContainerHighest,
            leading: Padding(
              padding: const EdgeInsets.only(left: 0.0),
              child: Icon(displayIconData, color: _selectedColor, size: 28),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
                side: BorderSide(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(12)),
            tileColor: theme.colorScheme.surfaceContainerHighest,
            leading: Padding(
              padding: const EdgeInsets.only(left: 0.0),
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
                    border:
                        Border.all(color: theme.dividerColor.withOpacity(0.5))),
              ),
            ),
            onTap: _showColorPicker,
          ),
          const SizedBox(height: 40),

          // --- Submit Button ---
          ElevatedButton.icon(
            icon: Icon(
                isEditing ? Icons.save_outlined : Icons.add_circle_outline),
            label: Text(isEditing ? 'Update Category' : 'Add Category'),
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

// Helper extension (if not already in utils)
extension StringCapExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
