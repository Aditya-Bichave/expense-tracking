// lib/features/categories/presentation/pages/add_edit_category_screen.dart
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/widgets/app_text_form_field.dart'; // Ensure this is the updated version
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_appearance_form_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // Keep for color picker dialog if used within section
import 'package:expense_tracker/core/utils/color_utils.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import for SVG icons

class AddEditCategoryScreen extends StatelessWidget {
  final Category? initialCategory;
  final CategoryType? initialType;

  const AddEditCategoryScreen({
    super.key,
    this.initialCategory,
    this.initialType,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEditing = initialCategory != null;
    log.info(
        "[AddEditCategoryScreen] Building. Editing: $isEditing. Category: ${initialCategory?.name}. Initial Type passed: ${initialType?.name}");

    // Bloc should be provided by the caller (e.g., using BlocProvider.value in Navigator.push or GoRouter setup)
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
          initialType: initialType,
          onSubmit: (name, iconName, colorHex, type, parentId, categoryObject) {
            log.info(
                "[AddEditCategoryScreen] Form submitted. Name: $name, Type: ${type.name}");
            final bloc = context.read<CategoryManagementBloc>();
            if (isEditing) {
              bloc.add(UpdateCategory(category: categoryObject));
              Navigator.of(context).pop(); // Pop normally on edit
            } else {
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
        ),
      ),
    );
  }
}

// --- Category Form Widget ---
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
  String _selectedIconName = 'category'; // Default Icon name
  Color _selectedColor = Colors.blue; // Default Color
  late CategoryType _selectedType;
  String? _selectedParentId;
  late bool _isTypeChangeAllowed;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCategory;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _selectedIconName =
        initial?.iconName ?? 'category'; // Use initial or default
    _selectedColor =
        initial != null ? ColorUtils.fromHex(initial.colorHex) : Colors.blue;
    _selectedType = widget.initialType ?? initial?.type ?? CategoryType.expense;
    _selectedParentId = initial?.parentCategoryId;
    // Allow type change only if NOT editing AND no initial type was forced (e.g., from transaction page)
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
        isCustom:
            true, // Assume any save from this form is custom or personalization
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
    // TODO: Implement navigation to a category selection screen (filtered by current _selectedType)
  }

  // Helper to get themed prefix icon or null
  Widget? _getPrefixIcon(
      BuildContext context, String iconKey, IconData fallbackIcon) {
    final modeTheme = context.modeTheme;
    final theme = Theme.of(context);
    if (modeTheme != null) {
      String svgPath = modeTheme.assets.getCommonIcon(iconKey, defaultPath: '');
      if (svgPath.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: SvgPicture.asset(svgPath,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                  theme.colorScheme.onSurfaceVariant, BlendMode.srcIn)),
        );
      }
    }
    return Icon(fallbackIcon);
  }

  @override
  Widget build(BuildContext context) {
    final modeTheme = context.modeTheme;
    final theme = Theme.of(context);
    final bool isEditing = widget.initialCategory != null;

    return Form(
      key: _formKey,
      child: ListView(
        padding: modeTheme?.pagePadding
                .copyWith(left: 16, right: 16, bottom: 40, top: 16) ??
            const EdgeInsets.all(16.0).copyWith(bottom: 40),
        children: [
          // Category Type Selector
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: DropdownButtonFormField<CategoryType>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Category Type',
                border: const OutlineInputBorder(),
                prefixIcon: _getPrefixIcon(context, 'type',
                    Icons.swap_horiz_outlined), // Example key 'type'
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
              items: CategoryType.values
                  .map((type) => DropdownMenuItem<CategoryType>(
                      value: type, child: Text(type.name.capitalize())))
                  .toList(),
              onChanged: _isTypeChangeAllowed
                  ? (CategoryType? newValue) {
                      if (newValue != null)
                        setState(() => _selectedType = newValue);
                    }
                  : null, // Disable if not allowed
              validator: (value) =>
                  value == null ? 'Please select a type' : null,
            ),
          ),

          // Category Name
          AppTextFormField(
            controller: _nameController,
            labelText: 'Category Name',
            // --- CORRECTED: Use prefixIcon instead of prefixIconData ---
            prefixIcon: _getPrefixIcon(context, 'label', Icons.label_outline),
            textCapitalization: TextCapitalization.words,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Please enter a category name'
                : null,
          ),
          const SizedBox(height: 20),

          // Parent Category Picker
          ListTile(
            leading: _getPrefixIcon(context, 'parent',
                Icons.account_tree_outlined), // Example key 'parent'
            title: const Text("Parent Category"),
            subtitle: Text(_selectedParentId ?? "None (Top Level)"),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showParentPicker, // Still a placeholder
            shape: RoundedRectangleBorder(
                side: BorderSide(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8)),
            tileColor: theme.colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 20),

          // Appearance Section
          CategoryAppearanceFormSection(
            selectedIconName: _selectedIconName,
            selectedColor: _selectedColor,
            onIconSelected: (newIcon) =>
                setState(() => _selectedIconName = newIcon),
            onColorSelected: (newColor) =>
                setState(() => _selectedColor = newColor),
          ),
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
