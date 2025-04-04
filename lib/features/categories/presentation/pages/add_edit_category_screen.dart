import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/widgets/app_text_form_field.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart'; // Import enum
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_appearance_form_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:expense_tracker/core/utils/color_utils.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // Import Uuid and sl
import 'package:uuid/uuid.dart';

class AddEditCategoryScreen extends StatelessWidget {
  final Category? initialCategory;
  // --- ADDED: Accept initial type ---
  final CategoryType? initialType; // Used when adding from transaction page

  const AddEditCategoryScreen({
    super.key,
    this.initialCategory,
    this.initialType, // Added optional parameter
  });

  @override
  Widget build(BuildContext context) {
    final bool isEditing = initialCategory != null;
    log.info(
        "[AddEditCategoryScreen] Building. Editing: $isEditing. Category: ${initialCategory?.name}. Initial Type passed: ${initialType?.name}");

    // Bloc should be provided by the caller
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
          initialType: initialType, // Pass initial type to form
          // --- MODIFIED onSubmit: Pops with Category object when adding ---
          onSubmit: (name, iconName, colorHex, type, parentId, categoryObject) {
            log.info(
                "[AddEditCategoryScreen] Form submitted. Name: $name, Type: ${type.name}");
            final bloc = context.read<CategoryManagementBloc>();
            if (isEditing) {
              // Update logic remains the same
              bloc.add(UpdateCategory(category: categoryObject));
              Navigator.of(context).pop(); // Pop normally on edit
            } else {
              // Dispatch add event
              bloc.add(AddCategory(
                name: name,
                iconName: iconName,
                colorHex: colorHex,
                type: type,
                parentId: parentId,
              ));
              // Pop WITH the newly created category object
              Navigator.of(context).pop(categoryObject);
            }
          },
          // --- END MODIFIED ---
        ),
      ),
    );
  }
}

// --- Category Form Widget (Updated) ---
class CategoryForm extends StatefulWidget {
  final Category? initialCategory;
  final CategoryType? initialType;
  final Function(String name, String iconName, String colorHex,
      CategoryType type, String? parentId, Category categoryObject) onSubmit;

  const CategoryForm({
    super.key,
    this.initialCategory,
    this.initialType,
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
  late CategoryType _selectedType;
  String? _selectedParentId;
  late bool _isTypeChangeAllowed;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCategory;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _selectedIconName = initial?.iconName ?? 'category';
    _selectedColor =
        initial != null ? ColorUtils.fromHex(initial.colorHex) : Colors.blue;
    _selectedType = widget.initialType ?? initial?.type ?? CategoryType.expense;
    _selectedParentId = initial?.parentCategoryId;
    _isTypeChangeAllowed =
        widget.initialCategory == null && widget.initialType == null;
    log.info(
        "[CategoryForm] initState. Initial Type: ${_selectedType.name}, AllowChange: $_isTypeChangeAllowed");
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      log.info(
          "[CategoryForm] Form validated. Submitting with Type: ${_selectedType.name}");
      final categoryObject = Category(
        id: widget.initialCategory?.id ?? sl<Uuid>().v4(),
        name: _nameController.text.trim(),
        iconName: _selectedIconName,
        colorHex: ColorUtils.toHex(_selectedColor),
        type: _selectedType,
        isCustom: true,
        parentCategoryId: _selectedParentId,
      );
      widget.onSubmit(
          categoryObject.name,
          categoryObject.iconName,
          categoryObject.colorHex,
          categoryObject.type,
          categoryObject.parentCategoryId,
          categoryObject);
    } else {
      log.warning("[CategoryForm] Form validation failed.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please correct the errors in the form.'),
          backgroundColor: Colors.orangeAccent));
    }
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
    final bool isEditing = widget.initialCategory != null;

    return Form(
      key: _formKey,
      child: ListView(
        padding: modeTheme?.pagePadding ?? const EdgeInsets.all(16.0),
        children: [
          // Category Type Selector
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: DropdownButtonFormField<CategoryType>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Category Type',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.swap_horiz_outlined),
                hintText: 'Select if Expense or Income',
                enabledBorder: _isTypeChangeAllowed
                    ? null
                    : OutlineInputBorder(
                        borderSide: BorderSide(
                            color: theme.disabledColor.withOpacity(0.5))),
                filled: !_isTypeChangeAllowed,
                fillColor: !_isTypeChangeAllowed
                    ? theme.disabledColor.withOpacity(0.05)
                    : null,
                labelStyle: !_isTypeChangeAllowed
                    ? TextStyle(color: theme.disabledColor)
                    : null,
              ),
              items: CategoryType.values.map((type) {
                return DropdownMenuItem<CategoryType>(
                    value: type, child: Text(type.name.capitalize()));
              }).toList(),
              onChanged: _isTypeChangeAllowed
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

          // Parent Category Picker (Placeholder)
          ListTile(
            leading: const Icon(Icons.account_tree_outlined),
            title: const Text("Parent Category"),
            subtitle: Text(_selectedParentId ?? "None (Top Level)"),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showParentPicker,
            shape: RoundedRectangleBorder(
                side: BorderSide(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8)),
            tileColor: theme.colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 20),

          // --- Use the decomposed Appearance Section ---
          CategoryAppearanceFormSection(
            selectedIconName: _selectedIconName,
            selectedColor: _selectedColor,
            onIconSelected: (newIcon) =>
                setState(() => _selectedIconName = newIcon),
            onColorSelected: (newColor) =>
                setState(() => _selectedColor = newColor),
          ),
          // --- End Appearance Section ---

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

// Helper extension
extension StringCapExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
