// lib/features/accounts/presentation/widgets/account_form.dart
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/core/utils/currency_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/core/widgets/app_dropdown_form_field.dart';
import 'package:expense_tracker/core/widgets/common_form_fields.dart'; // Import common builders
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:intl/intl.dart';

// Callback remains the same, still submitting the value from the field as 'initialBalance'
typedef AccountSubmitCallback = Function(
    String name, AssetType type, double initialBalance);

class AccountForm extends StatefulWidget {
  final AssetAccount? initialAccount;
  final double? currentBalanceForDisplay;
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

class _AccountFormState extends State<AccountForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController; // Renamed for clarity
  AssetType _selectedType = AssetType.bank;
  late bool _isEditing; // Track edit mode locally

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAccount;
    _isEditing = initial != null; // Determine if editing

    _nameController = TextEditingController(text: initial?.name ?? '');
    // --- MODIFIED: Use currentBalanceForDisplay if editing, otherwise initialBalance or default ---
    _balanceController = TextEditingController(
      text: _isEditing
          ? widget.currentBalanceForDisplay?.toStringAsFixed(2) ??
              '0.00' // Use current balance if editing
          : initial?.initialBalance.toStringAsFixed(2) ??
              '0.00', // Use initial or default if adding
    );
    // --- END MODIFIED ---
    _selectedType = initial?.type ?? AssetType.bank;
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
      // --- Parse the value from the form field, treat it as the new initial balance ---
      // This allows users to potentially correct the initial balance if needed,
      // although the UI now displays the current balance initially during edit.
      final locale = context.read<SettingsBloc>().state.selectedCountryCode;
      final balanceFromField = parseCurrency(_balanceController.text, locale);
      // --- END ---
      widget.onSubmit(
        name,
        _selectedType,
        balanceFromField,
      ); // Pass the value from the field
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the errors in the form.')),
      );
    }
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
        padding: modeTheme?.pagePadding.copyWith(
              left: 16,
              right: 16,
              bottom: 40,
              top: 16,
            ) ??
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
              context,
              'category',
              Icons.category_outlined,
            ),
            items: AssetType.values.map((AssetType type) {
              final iconData = AssetAccount(
                id: '',
                name: '',
                type: type,
                currentBalance: 0,
              ).iconData;
              return DropdownMenuItem<AssetType>(
                value: type,
                child: Row(
                  children: [
                    Icon(
                      iconData,
                      size: 20,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(toBeginningOfSentenceCase(type.name) ?? type.name),
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
              final locale =
                  context.read<SettingsBloc>().state.selectedCountryCode;
              if (parseCurrency(value, locale).isNaN) {
                return 'Invalid number';
              }
              return null;
            },
          ),
          if (_isEditing) // Add helper text when editing
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 4.0, start: 12.0),
              child: Text(
                'Editing this updates the initial balance setting.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.disabledColor,
                ),
              ),
            ),
          // --- END MODIFIED ---
          const SizedBox(height: 32),

          // Submit Button
          ElevatedButton.icon(
            icon: Icon(
              widget.initialAccount == null
                  ? Icons.add_circle_outline
                  : Icons.save_outlined,
            ),
            label: Text(
              widget.initialAccount == null ? 'Add Account' : 'Update Account',
            ),
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
