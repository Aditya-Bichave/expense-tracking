import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import SettingsBloc
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc

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
  AssetType _selectedType = AssetType.bank;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialAccount?.name ?? '');
    _initialBalanceController = TextEditingController(
      text: widget.initialAccount?.initialBalance.toStringAsFixed(2) ?? '0.00',
    );
    _selectedType = widget.initialAccount?.type ?? AssetType.bank;
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
      final initialBalance =
          double.tryParse(_initialBalanceController.text) ?? 0.0;
      widget.onSubmit(name, _selectedType, initialBalance);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get currency symbol from SettingsBloc
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol =
        settingsState.currencySymbol ?? '\$'; // Default if null

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Account Name'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an account name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<AssetType>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Account Type',
              border: OutlineInputBorder(),
            ),
            items: AssetType.values.map((AssetType type) {
              return DropdownMenuItem<AssetType>(
                value: type,
                child: Text(type.name.capitalize()), // Use capitalize extension
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
              // Use InputDecoration to set prefix
              labelText: 'Initial Balance',
              prefixText: '$currencySymbol ', // Use dynamic symbol
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an initial balance (can be 0)';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _submitForm,
            child: Text(widget.initialAccount == null
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
