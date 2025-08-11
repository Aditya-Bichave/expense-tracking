import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/main.dart'; // Import logger

class AccountSelectorDropdown extends StatelessWidget {
  final String? selectedAccountId;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;
  final String labelText;
  final String hintText;

  const AccountSelectorDropdown({
    super.key,
    required this.onChanged,
    this.selectedAccountId,
    this.validator,
    this.labelText = 'Account',
    this.hintText = 'Select Account',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AccountListBloc, AccountListState>(
      builder: (context, state) {
        log.info(
            "[AccountSelector] BlocBuilder running for state: ${state.runtimeType}");
        List<AssetAccount> accounts = [];
        bool isLoading = false;
        String? errorMessage;

        if (state is AccountListLoading) {
          isLoading = true;
          final previousState = context.read<AccountListBloc>().state;
          if (previousState is AccountListLoaded) {
            accounts = previousState.accounts;
          }
        } else if (state is AccountListLoaded) {
          accounts = state.accounts;
        } else if (state is AccountListError) {
          log.severe(
              "[AccountSelector] Error state detected: ${state.message}");
          errorMessage = "Error loading accounts: ${state.message}";
        } else if (state is AccountListInitial) {
          isLoading = true;
        }

        // Safeguard: Ensure the selected value exists in the list.
        String? displayValue = selectedAccountId;
        if (selectedAccountId != null &&
            !accounts.any((acc) => acc.id == selectedAccountId)) {
          log.warning(
              "[AccountSelector] Selected ID '$selectedAccountId' is not in the current list of accounts. Displaying as null.");
          displayValue = null;
        }

        return DropdownButtonFormField<String>(
          value: displayValue,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: labelText,
            hintText:
                isLoading && accounts.isEmpty ? 'Loading...' : hintText,
            border: const OutlineInputBorder(),
            errorText: errorMessage,
            prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
            suffixIcon: isLoading && accounts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
          ),
          onChanged: (isLoading || errorMessage != null)
              ? null
              : (String? newValue) {
                  log.info(
                      "[AccountSelector] Dropdown changed. New value: $newValue");
                  onChanged(newValue);
                },
          items: (isLoading || errorMessage != null)
              ? []
              : accounts.map((AssetAccount account) {
                  return DropdownMenuItem<String>(
                    value: account.id,
                    child: Row(
                      children: [
                        Icon(account.iconData,
                            size: 20, color: theme.colorScheme.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(account.name,
                                overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  );
                }).toList(),
          validator: validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select an account';
                }
                return null;
              },
          hint: accounts.isEmpty && !isLoading && errorMessage == null
              ? const Text('No accounts available')
              : Text(hintText),
        );
      },
    );
  }
}
