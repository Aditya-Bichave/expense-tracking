// lib/features/accounts/presentation/widgets/account_form.dart
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/core/widgets/app_dropdown_form_field.dart';
import 'package:expense_tracker/core/widgets/common_form_fields.dart'; // Import common builders
import 'package:expense_tracker/core/theme/app_mode_theme.dart';

import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:expense_tracker/core/utils/color_utils.dart';
import 'dart:math';

// Callback now includes the color hex string
typedef AccountSubmitCallback = Function(
    String name, AssetType type, double initialBalance, String colorHex);

class AccountForm extends StatefulWidget {
  final AssetAccount? initialAccount;
  // --- ADDED: Pass current balance for display during edit ---
  final double? currentBalanceForDisplay;
  // --- END ADDED ---
  final AccountSubmitCallback onSubmit;

  const AccountForm({
    super.key,
    this.initialAccount,
    this.currentBalanceForDisplay, // Added
    required this.onSubmit,
  });

  @override
  State<AccountForm> createState() => _AccountFormState();
}

import 'package:expense_tracker/core/utils/string_extensions.dart';

class _AccountFormState extends State<AccountForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  AssetType _selectedType = AssetType.bank;
  late bool _isEditing;
  late Color _selectedColor;

  // A simple palette for new accounts
  final List<Color> _defaultPalette = [
    Colors.blue.shade300,
    Colors.red.shade300,
    Colors.green.shade300,
    Colors.orange.shade300,
    Colors.purple.shade300,
    Colors.teal.shade300,
    Colors.pink.shade300,
    Colors.indigo.shade300,
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAccount;
    _isEditing = initial != null;

    _nameController = TextEditingController(text: initial?.name ?? '');
    _balanceController = TextEditingController(
      text: _isEditing
          ? widget.currentBalanceForDisplay?.toStringAsFixed(2) ?? '0.00'
          : initial?.initialBalance.toStringAsFixed(2) ?? '0.00',
    );
    _selectedType = initial?.type ?? AssetType.bank;
    _selectedColor = initial?.colorHex != null
        ? ColorUtils.fromHex(initial!.colorHex)
        : _defaultPalette[Random().nextInt(_defaultPalette.length)];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose(); // Dispose renamed controller
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final balanceFromField =
          double.tryParse(_balanceController.text.replaceAll(',', '.')) ?? 0.0;
      widget.onSubmit(
          name, _selectedType, balanceFromField, ColorUtils.toHex(_selectedColor));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please correct the errors in the form.')));
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
            },
            availableColors: _defaultPalette,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Done'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;

    // --- Determine Label Text Dynamically ---
    final String balanceLabel =
        _isEditing ? 'Current Balance' : 'Initial Balance';
    // --- End ---

    return Form(
      key: _formKey,
      child: ListView(
        padding: modeTheme?.pagePadding
                .copyWith(left: 16, right: 16, bottom: 40, top: 16) ??
            const EdgeInsets.all(16.0).copyWith(bottom: 40),
        children: [
          // Name
          CommonFormFields.buildNameField(
            context: context,
            controller: _nameController,
            labelText: 'Account Name',
            iconKey: 'edit',
            fallbackIcon: Icons.edit,
          ),
          const SizedBox(height: 16),

          // Type Dropdown
          AppDropdownFormField<AssetType>(
            value: _selectedType,
            labelText: 'Account Type',
            prefixIcon: CommonFormFields.getPrefixIcon(
                context, 'category', Icons.category_outlined),
            items: AssetType.values.map((AssetType type) {
              final iconData = AssetAccount(
                      id: '',
                      name: '',
                      type: type,
                      currentBalance: 0,
                      colorHex: '#FFFFFF')
                  .iconData;
              return DropdownMenuItem<AssetType>(
                value: type,
                child: Row(
                  children: [
                    Icon(iconData,
                        size: 20, color: theme.colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text(type.name.capitalize()),
                  ],
                ),
              );
            }).toList(),
            onChanged: (AssetType? newValue) {
              if (newValue != null) {
                setState(() => _selectedType = newValue);
              }
            },
            validator: (value) =>
                value == null ? 'Please select an account type' : null,
          ),
          const SizedBox(height: 16),

          // Color Picker
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            leading: CommonFormFields.getPrefixIcon(
                context, 'color', Icons.color_lens_outlined),
            title: const Text('Account Color'),
            trailing: CircleAvatar(backgroundColor: _selectedColor, radius: 14),
            onTap: _showColorPicker,
          ),
          const SizedBox(height: 16),

          // --- MODIFIED: Use dynamic label and renamed controller ---
          // Balance (Displayed as Current when editing, Initial when adding)
          CommonFormFields.buildAmountField(
            context: context,
            controller: _balanceController, // Use renamed controller
            labelText: balanceLabel, // Use dynamic label
            currencySymbol: currencySymbol,
            iconKey: 'wallet',
            fallbackIcon: Icons.account_balance_wallet_outlined,
            validator: (value) {
              // Allow negative balance
              if (value == null || value.isEmpty) {
                return 'Enter balance (0 is valid)';
              }
              if (double.tryParse(value.replaceAll(',', '.')) == null) {
                return 'Invalid number';
              }
              return null;
            },
          ),
          if (_isEditing) // Add helper text when editing
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 12.0),
              child: Text(
                'Editing this updates the initial balance setting.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.disabledColor),
              ),
            ),
          // --- END MODIFIED ---
          const SizedBox(height: 32),

          // Submit Button
          ElevatedButton.icon(
            icon: Icon(widget.initialAccount == null
                ? Icons.add_circle_outline
                : Icons.save_outlined),
            label: Text(widget.initialAccount == null
                ? 'Add Account'
                : 'Update Account'),
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
