import 'package:expense_tracker/core/di/service_locator.dart';
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
import 'package:uuid/uuid.dart';

class AddEditCategoryScreen extends StatelessWidget {
  final Category? initialCategory;
  // --- ADDED: Accept initial type ---
  final CategoryType? initialType;

  const AddEditCategoryScreen({
    super.key,
    this.initialCategory,
    this.initialType, // Added optional parameter
  });
  // --- END ADDED ---

  @override
  Widget build(BuildContext context) {
    final bool isEditing = initialCategory != null;
    log.info(
        "[AddEditCategoryScreen] Building. Editing: $isEditing. Category: ${initialCategory?.name}. Initial Type passed: ${initialType?.name}");

    // Bloc should be provided by the caller (e.g., CategoryManagementScreen or AddEditTransactionPage)
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Category' : 'Add Category'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: () =>
              Navigator.of(context).pop(), // Pop without result on cancel
        ),
      ),
      body: SafeArea(
        child: CategoryForm(
          initialCategory: initialCategory,
          // --- Pass initial type to form ---
          initialType: initialType,
          onSubmit: (name, iconName, colorHex, type, parentId, newCategory) {
            // Modified callback signature
            log.info(
                "[AddEditCategoryScreen] Form submitted. Name: $name, Icon: $iconName, Color: $colorHex, Type: ${type.name}, Parent: $parentId");
            final bloc = context.read<CategoryManagementBloc>();
            if (isEditing) {
              final updatedCategory = initialCategory!.copyWith(
                name: name,
                iconName: iconName,
                colorHex: colorHex,
                // Type and isCustom should not change during edit
              );
              bloc.add(UpdateCategory(category: updatedCategory));
              Navigator.of(context).pop(); // Pop normally on edit
            } else {
              bloc.add(AddCategory(
                // Dispatch add event
                name: name,
                iconName: iconName,
                colorHex: colorHex,
                type: type,
                parentId: parentId,
              ));
              // --- Pop WITH the newly created category object ---
              Navigator.of(context).pop(newCategory);
              // --- END Pop ---
            }
          },
        ),
      ),
    );
  }
}

// --- Category Form Widget ---
class CategoryForm extends StatefulWidget {
  final Category? initialCategory;
  final CategoryType? initialType; // Accept initial type
  // --- MODIFIED onSubmit signature ---
  final Function(String name, String iconName, String colorHex,
      CategoryType type, String? parentId, Category newCategory) onSubmit;
  // --- END MODIFIED ---

  const CategoryForm({
    super.key,
    this.initialCategory,
    this.initialType, // Added
    required this.onSubmit,
  });

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String _selectedIconName = 'category';
  Color _selectedColor = Colors.blue;
  late CategoryType _selectedType; // Use late initialization
  String? _selectedParentId;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCategory;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _selectedIconName = initial?.iconName ?? 'category';
    _selectedColor =
        initial != null ? ColorUtils.fromHex(initial.colorHex) : Colors.blue;
    // --- Set initial type based on passed param or existing category ---
    _selectedType = widget.initialType ?? initial?.type ?? CategoryType.expense;
    // --- End ---
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

      // --- Create the Category object to be passed back ---
      // Generate ID only if adding (isEditing = false)
      final bool isEditing = widget.initialCategory != null;
      final categoryToSubmit = Category(
        id: widget.initialCategory?.id ??
            sl<Uuid>().v4(), // Use existing ID or generate new
        name: _nameController.text.trim(),
        iconName: _selectedIconName,
        colorHex: ColorUtils.toHex(_selectedColor),
        type: _selectedType, // Use the selected type
        isCustom: true, // Assume any category created/edited here is custom
        parentCategoryId: _selectedParentId,
      );
      // --- END Create ---

      widget.onSubmit(
        categoryToSubmit.name,
        categoryToSubmit.iconName,
        categoryToSubmit.colorHex,
        categoryToSubmit.type,
        categoryToSubmit.parentCategoryId,
        categoryToSubmit, // Pass the created object
      );
    } else {
      log.warning("[CategoryForm] Form validation failed.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please correct the errors in the form.'),
          backgroundColor: Colors.orangeAccent));
    }
  }

  // --- Keep _showIconPicker, _showColorPicker, _showParentPicker ---
  void _showIconPicker() async {
    log.info("[CategoryForm] Icon picker requested");
    final String? selectedIcon =
        await showIconPicker(context, _selectedIconName);
    if (selectedIcon != null && selectedIcon != _selectedIconName && mounted) {
      log.info("[CategoryForm] New Icon selected: $selectedIcon");
      setState(() => _selectedIconName = selectedIcon);
    } else {
      log.info("[CategoryForm] Icon selection cancelled or unchanged.");
    }
  }

  void _showColorPicker() {
    log.info("[CategoryForm] Color picker requested.");
    Color pickerColor = _selectedColor;
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
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
              child: const Text('Select'),
              onPressed: () {
                if (mounted) {
                  log.info("[CategoryForm] New Color selected: $pickerColor");
                  setState(() => _selectedColor = pickerColor);
                }
                Navigator.of(context).pop();
              }),
        ],
      ),
    );
  }

  void _showParentPicker() {
    log.warning("[CategoryForm] Parent Category Picker not implemented yet.");
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sub-category selection coming soon!")));
  }

  @override
  Widget build(BuildContext context) {
    final modeTheme = context.modeTheme;
    final theme = Theme.of(context);
    final IconData displayIconData =
        availableIcons[_selectedIconName] ?? Icons.category_outlined;
    final bool isEditing = widget.initialCategory != null;
    // --- Determine if type selector should be enabled ---
    final bool allowTypeChange = !isEditing && widget.initialType == null;
    // --- End ---

    return Form(
      key: _formKey,
      child: ListView(
        padding: modeTheme?.pagePadding ?? const EdgeInsets.all(16.0),
        children: [
          // --- Category Type Selector (Conditionally Enabled/Disabled) ---
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: DropdownButtonFormField<CategoryType>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Category Type',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.swap_horiz_outlined),
                hintText: 'Select if Expense or Income',
                // Style to look disabled if not changeable
                enabledBorder: allowTypeChange
                    ? null
                    : OutlineInputBorder(
                        borderSide: BorderSide(
                            color: theme.disabledColor.withOpacity(0.5)),
                      ),
                filled: !allowTypeChange,
                fillColor: !allowTypeChange
                    ? theme.disabledColor.withOpacity(0.05)
                    : null,
              ),
              items: CategoryType.values.map((type) {
                return DropdownMenuItem<CategoryType>(
                  value: type,
                  child: Text(type.name.capitalize()),
                );
              }).toList(),
              // Disable changing if editing or initialType was passed
              onChanged: allowTypeChange
                  ? (CategoryType? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedType = newValue);
                      }
                    }
                  : null,
              validator: (value) =>
                  value == null ? 'Please select a type' : null,
            ),
          ),
          // --- END Type Selector ---

          // Category Name
          AppTextFormField(
              controller: _nameController,
              labelText: 'Category Name',
              prefixIconData: Icons.label_outline,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a category name';
                }
                return null;
              }),
          const SizedBox(height: 20),

          // Parent Category (Keep as is)
          ListTile(/* ... */),
          const SizedBox(height: 20),

          // Appearance Section (Keep as is)
          Text("Appearance", style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          ListTile(/* Icon Picker */),
          const SizedBox(height: 16),
          ListTile(/* Color Picker */),
          const SizedBox(height: 40),

          // Submit Button
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
