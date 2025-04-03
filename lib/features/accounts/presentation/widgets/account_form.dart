import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Import reusable form fields
import 'package:expense_tracker/core/widgets/app_text_form_field.dart';
import 'package:expense_tracker/core/widgets/app_dropdown_form_field.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart'; // For themed padding

class AccountForm extends StatefulWidget {
  final AssetAccount? initialAccount;
  final Function(String name, AssetType type, double initialBalance) onSubmit;

  const AccountForm({
    super.key,
    this.initialAccount,
    required this.onSubmit,
  });

  @override
  State<AccountForm> createState() => _AccountFormState();
}

// Keep capitalize extension local or move to utils
extension StringExtensionCapitalize on String {
  String capitalizeForm() {
    // Renamed to avoid conflict if moved globally later
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class _AccountFormState extends State<AccountForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _initialBalanceController;
  AssetType _selectedType = AssetType.bank; // Default

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAccount;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _initialBalanceController = TextEditingController(
      text: initial?.initialBalance.toStringAsFixed(2) ?? '0.00',
    );
    _selectedType = initial?.type ?? AssetType.bank;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final initialBalance = double.tryParse(
              _initialBalanceController.text.replaceAll(',', '.')) ??
          0.0;
      widget.onSubmit(name, _selectedType, initialBalance);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please correct the errors in the form.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol; // Use default if null
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: modeTheme?.pagePadding ??
            const EdgeInsets.all(16.0), // Themed padding
        children: [
          // --- Use AppTextFormField ---
          AppTextFormField(
            controller: _nameController,
            labelText: 'Account Name',
            prefixIconData: Icons.edit,
            textCapitalization: TextCapitalization.words,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Please enter an account name'
                : null,
          ),
          const SizedBox(height: 16),
          // --- Use AppDropdownFormField ---
          AppDropdownFormField<AssetType>(
            value: _selectedType,
            labelText: 'Account Type',
            prefixIconData: Icons.category_outlined,
            items: AssetType.values.map((AssetType type) {
              // Create dummy account just to get icon
              final iconData =
                  AssetAccount(id: '', name: '', type: type, currentBalance: 0)
                      .iconData;
              return DropdownMenuItem<AssetType>(
                value: type,
                child: Row(
                  children: [
                    Icon(iconData,
                        size: 20, color: theme.colorScheme.secondary),
                    const SizedBox(width: 8),
                    // Use the local capitalize extension
                    Text(type.name.capitalizeForm()),
                  ],
                ),
              );
            }).toList(),
            onChanged: (AssetType? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedType = newValue;
                });
              }
            },
            validator: (value) =>
                value == null ? 'Please select an account type' : null,
          ),
          const SizedBox(height: 16),
          // --- Use AppTextFormField ---
          AppTextFormField(
            controller: _initialBalanceController,
            labelText: 'Initial Balance',
            prefixText: '$currencySymbol ',
            prefixIconData: Icons.account_balance_wallet_outlined,
            keyboardType: const TextInputType.numberWithOptions(
                signed: true, decimal: true), // Allow negative for balance
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*[,.]?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Please enter an initial balance (can be 0 or negative)';
              if (double.tryParse(value.replaceAll(',', '.')) == null)
                return 'Please enter a valid number';
              return null;
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: Icon(widget.initialAccount == null ? Icons.add : Icons.save),
            label: Text(widget.initialAccount == null
                ? 'Add Account'
                : 'Update Account'),
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
