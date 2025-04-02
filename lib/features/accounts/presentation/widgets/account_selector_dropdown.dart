import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/main.dart'; // Import logger

class AccountSelectorDropdown extends StatefulWidget {
  final String? selectedAccountId;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator; // Optional validator
  final String labelText; // Make label customizable
  final String hintText; // Make hint customizable

  const AccountSelectorDropdown({
    super.key,
    required this.onChanged,
    this.selectedAccountId,
    this.validator,
    this.labelText = 'Account', // Default label
    this.hintText = 'Select Account', // Default hint
  });

  @override
  State<AccountSelectorDropdown> createState() =>
      _AccountSelectorDropdownState();
}

class _AccountSelectorDropdownState extends State<AccountSelectorDropdown> {
  String? _internalSelectedId;

  @override
  void initState() {
    super.initState();
    _internalSelectedId = widget.selectedAccountId;
    log.info(
        "[AccountSelector] Initialized. Selected ID: $_internalSelectedId");

    // AccountListBloc is assumed to be loaded higher up.
    // If not, it might need a LoadAccounts dispatch here, but that's less ideal.
  }

  // Update internal state if the parent widget rebuilds with a different ID
  @override
  void didUpdateWidget(covariant AccountSelectorDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAccountId != oldWidget.selectedAccountId) {
      log.info(
          "[AccountSelector] didUpdateWidget: ID changed from ${oldWidget.selectedAccountId} to ${widget.selectedAccountId}");
      setState(() {
        _internalSelectedId = widget.selectedAccountId;
      });
    }
  }

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
          // Keep existing accounts if available during reload
          final previousState = context.read<AccountListBloc>().state;
          if (previousState is AccountListLoaded) {
            accounts = previousState.accounts;
          }
        } else if (state is AccountListLoaded) {
          accounts = state.accounts;
          // Ensure the *currently selected internal ID* is still valid within the new list.
          if (_internalSelectedId != null &&
              !accounts.any((acc) => acc.id == _internalSelectedId)) {
            log.warning(
                "[AccountSelector] Selected ID '$_internalSelectedId' is no longer valid in the updated list. Resetting selection.");
            // Reset the selection if the previously selected account is gone
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _internalSelectedId = null;
                });
                widget.onChanged(null); // Notify parent
              }
            });
          }
        } else if (state is AccountListError) {
          log.severe(
              "[AccountSelector] Error state detected: ${state.message}");
          errorMessage = "Error loading accounts: ${state.message}";
        } else if (state is AccountListInitial) {
          isLoading = true; // Treat initial as loading
        }

        // Build the dropdown or loading/error state
        return DropdownButtonFormField<String>(
          value: _internalSelectedId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText:
                isLoading && accounts.isEmpty ? 'Loading...' : widget.hintText,
            border: const OutlineInputBorder(),
            errorText: errorMessage, // Display error message here
            prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
            // Show progress indicator inside if loading and list is empty
            suffixIcon: isLoading && accounts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12.0), // Adjust padding
                    child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
          ),
          // Disable dropdown if loading or error
          onChanged: (isLoading || errorMessage != null)
              ? null
              : (String? newValue) {
                  log.info(
                      "[AccountSelector] Dropdown changed. New value: $newValue");
                  setState(() {
                    _internalSelectedId = newValue; // Update internal state
                  });
                  widget.onChanged(newValue); // Notify parent
                },
          // Create items, disable if loading/error
          items: (isLoading || errorMessage != null)
              ? [] // Return empty list if loading or error to prevent interaction
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
                        const SizedBox(width: 8),
                        // Optionally show balance in dropdown
                        // Text(
                        //    CurrencyFormatter.format(account.currentBalance, context.watch<SettingsBloc>().state.currencySymbol),
                        //    style: theme.textTheme.bodySmall,
                        // ),
                      ],
                    ),
                  );
                }).toList(),
          // Use provided or default validator
          validator: widget.validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select an account';
                }
                return null;
              },
          // Add a hint for empty list scenario
          hint: accounts.isEmpty && !isLoading && errorMessage == null
              ? const Text('No accounts available')
              : Text(widget.hintText),
        );
      },
    );
  }
}
