import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      // Ensure correct formatting on init
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
    // Ensure validation passes before submitting
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      // Use double.tryParse for safety, default to 0.0 if parsing fails
      final initialBalance =
          double.tryParse(_initialBalanceController.text.replaceAll(',', '')) ??
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
    final currencySymbol =
        settingsState.currencySymbol ?? '\$'; // Use default if null
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Account Name',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.edit),
              // Add clear button
              suffixIcon: _nameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _nameController.clear(),
                      tooltip: 'Clear',
                    )
                  : null,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an account name';
              }
              return null;
            },
            // Update suffix icon state on change
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<AssetType>(
            value: _selectedType,
            decoration: InputDecoration(
              labelText: 'Account Type',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(
                  Icons.category_outlined), // Use specific icon if desired
            ),
            items: AssetType.values.map((AssetType type) {
              return DropdownMenuItem<AssetType>(
                value: type,
                child: Row(
                  // Add icon to dropdown item
                  children: [
                    Icon(
                      // Get icon dynamically
                      AssetAccount(
                              id: '', name: '', type: type, currentBalance: 0)
                          .iconData,
                      size: 20,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(type.name.capitalize()),
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
            validator: (value) {
              if (value == null) {
                return 'Please select an account type';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _initialBalanceController,
            decoration: InputDecoration(
                labelText: 'Initial Balance',
                border: const OutlineInputBorder(),
                prefixText: '$currencySymbol ', // Use dynamic symbol
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined)),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            // Allow negative numbers and decimal point/comma
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*[,.]?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an initial balance (can be 0)';
              }
              // Allow comma as decimal separator
              if (double.tryParse(value.replaceAll(',', '.')) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: Icon(widget.initialAccount == null ? Icons.add : Icons.save),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: theme.textTheme.titleMedium,
            ),
            onPressed: _submitForm,
            label: Text(widget.initialAccount == null
                ? 'Add Account'
                : 'Update Account'),
          ),
        ],
      ),
    );
  }
}

// Keep the capitalize extension here or move to a shared utils file
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
