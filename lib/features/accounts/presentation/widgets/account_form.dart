// lib/features/accounts/presentation/widgets/account_form.dart
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/core/widgets/app_dropdown_form_field.dart';
import 'package:expense_tracker/core/widgets/common_form_fields.dart'; // Import common builders
import 'package:expense_tracker/core/theme/app_mode_theme.dart';

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

extension StringExtensionCapitalize on String {
  String capitalizeForm() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class _AccountFormState extends State<AccountForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _initialBalanceController;
  AssetType _selectedType = AssetType.bank;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAccount;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _initialBalanceController = TextEditingController(
        text: initial?.initialBalance.toStringAsFixed(2) ?? '0.00');
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

  // getPrefixIcon is now in CommonFormFields

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;

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
            value: _selectedType, labelText: 'Account Type',
            // --- FIX: Use CommonFormFields.getPrefixIcon ---
            prefixIcon: CommonFormFields.getPrefixIcon(
                context, 'category', Icons.category_outlined),
            // --- END FIX ---
            items: AssetType.values.map((AssetType type) {
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
                    Text(type.name.capitalizeForm()),
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

          // Initial Balance
          CommonFormFields.buildAmountField(
            context: context,
            controller: _initialBalanceController,
            labelText: 'Initial Balance',
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
