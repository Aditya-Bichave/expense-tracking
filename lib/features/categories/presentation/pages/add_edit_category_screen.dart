// lib/features/categories/presentation/pages/add_edit_category_screen.dart
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
// Keep if needed elsewhere
import 'package:expense_tracker/core/widgets/common_form_fields.dart'; // Import common builders
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_appearance_form_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Keep for section if needed
import 'package:expense_tracker/core/utils/color_utils.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:uuid/uuid.dart';
// Keep for common builder

class AddEditCategoryScreen extends StatelessWidget {
  final Category? initialCategory;
  final CategoryType? initialType; // Added to receive initial type

  const AddEditCategoryScreen({
    super.key,
    this.initialCategory,
    this.initialType, // Added
  });

  @override
  Widget build(BuildContext context) {
    final bool isEditing = initialCategory != null;
    // Get forced initial type from arguments if passed via push extra
    final routeArgs =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final forcedInitialType = routeArgs?['initialType'] as CategoryType?;

    log.info(
        "[AddEditCategoryScreen] Building. Editing: $isEditing. Category: ${initialCategory?.name}. Forced Initial Type: ${forcedInitialType?.name}");

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Category' : 'Add Category'),
        leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
            onPressed: () => Navigator.of(context).pop()),
      ),
      body: SafeArea(
        // Ensure CategoryManagementBloc is provided up the tree or provide here
        child: CategoryForm(
          initialCategory: initialCategory,
          initialType: forcedInitialType ?? initialCategory?.type,
          onSubmit: (name, iconName, colorHex, type, parentId, categoryObject) {
            log.info(
                "[AddEditCategoryScreen] Form submitted. Name: $name, Type: ${type.name}");
            final bloc = context.read<CategoryManagementBloc>();
            if (isEditing) {
              bloc.add(UpdateCategory(category: categoryObject));
              Navigator.of(context).pop();
            } else {
              bloc.add(AddCategory(
                  name: name,
                  iconName: iconName,
                  colorHex: colorHex,
                  type: type,
                  parentId: parentId));
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

  // Removed _getPrefixIcon

  @override
  Widget build(BuildContext context) {
    final modeTheme = context.modeTheme;
    final theme = Theme.of(context);
    final bool isEditing = widget.initialCategory != null;

    final List<Color> expenseColors = [
      theme.colorScheme.errorContainer.withAlpha((255 * 0.7).round()),
      theme.colorScheme.errorContainer
    ];
    final List<Color> incomeColors = [
      theme.colorScheme.primaryContainer,
      theme.colorScheme.primaryContainer.withAlpha((255 * 0.7).round())
    ];

    return Form(
      key: _formKey,
      child: ListView(
        padding: modeTheme?.pagePadding
                .copyWith(left: 16, right: 16, bottom: 40, top: 16) ??
            const EdgeInsets.all(16.0).copyWith(bottom: 40),
        children: [
          // Category Type Toggle
          CommonFormFields.buildTypeToggle(
            context: context,
            initialIndex: _selectedType == CategoryType.expense ? 0 : 1,
            labels: const ['Expense', 'Income'],
            activeBgColors: [expenseColors, incomeColors], // Pass list of lists
            disabled: !_isTypeChangeAllowed,
            onToggle: (index) {
              if (index != null) {
                final newType =
                    index == 0 ? CategoryType.expense : CategoryType.income;
                if (_selectedType != newType) {
                  setState(() => _selectedType = newType);
                  log.info(
                      "[CategoryForm] Type toggled to: ${_selectedType.name}");
                  // Reset parent on type change
                  // setState(() => _selectedParentId = null);
                }
              }
            },
          ),
          const SizedBox(height: 16),

          // Category Name
          CommonFormFields.buildNameField(
            context: context,
            controller: _nameController,
            labelText: 'Category Name',
            iconKey: 'label',
            fallbackIcon: Icons.label_outline,
          ),
          const SizedBox(height: 20),

          // Parent Category Picker
          ListTile(
            leading: CommonFormFields.getPrefixIcon(context, 'parent',
                Icons.account_tree_outlined), // Use public helper
            title: const Text("Parent Category"),
            subtitle: Text(_selectedParentId ?? "None (Top Level)"),
            trailing: const Icon(Icons.chevron_right), onTap: _showParentPicker,
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
                textStyle: theme.textTheme.titleMedium),
            onPressed: _submitForm,
          ),
        ],
      ),
    );
  }
}

import 'package:expense_tracker/core/utils/string_extensions.dart';
