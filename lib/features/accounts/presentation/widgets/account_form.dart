import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AccountForm extends StatefulWidget {
  final AssetAccount? initialAccount; // For editing
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
  AssetType _selectedType = AssetType.bank; // Default type

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
    return Form(
      key: _formKey,
      child: ListView(
        // Use ListView for scrollability on small screens
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
                child: Text(type
                    .name), // Assumes enum has a nice name getter or use extension
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
            decoration: const InputDecoration(
              labelText: 'Initial Balance',
              prefixText: '\$', // Or your currency symbol
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'^\d+\.?\d{0,2}')), // Allow decimals up to 2 places
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
            // Disable initial balance editing if account already exists?
            // Or clarify it only applies on creation. Let's assume it can be edited.
            // enabled: widget.initialAccount == null,
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
