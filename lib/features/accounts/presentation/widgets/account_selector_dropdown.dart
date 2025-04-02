import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountSelectorDropdown extends StatefulWidget {
  final String? selectedAccountId;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator; // Optional validator

  const AccountSelectorDropdown({
    super.key,
    required this.onChanged,
    this.selectedAccountId,
    this.validator,
  });

  @override
  State<AccountSelectorDropdown> createState() =>
      _AccountSelectorDropdownState();
}

class _AccountSelectorDropdownState extends State<AccountSelectorDropdown> {
  // Use BlocProvider.of or context.read in build method if AccountListBloc is provided higher up.
  // Or get from sl if it's truly managed globally and needs to be accessed here.
  // Let's assume it's provided higher up or fetched via sl if necessary.

  // Keep track of the selection internally if needed, but often
  // relying on the widget's selectedAccountId is simpler if the parent manages state.
  // For simplicity here, we'll manage it internally based on the initial value.
  String? _internalSelectedId;

  @override
  void initState() {
    super.initState();
    _internalSelectedId = widget.selectedAccountId;

    // Optionally trigger load if needed and not provided/loaded higher up
    // Consider if this component should be responsible for loading.
    // final accountListBloc = sl<AccountListBloc>();
    // if (accountListBloc.state is AccountListInitial) {
    //   accountListBloc.add(LoadAccounts());
    // }
  }

  // Update internal state if the parent widget rebuilds with a different ID
  @override
  void didUpdateWidget(covariant AccountSelectorDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAccountId != oldWidget.selectedAccountId) {
      setState(() {
        _internalSelectedId = widget.selectedAccountId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read the bloc instance here. Make sure it's provided above this widget!
    // If using sl, you might fetch it directly: final state = sl<AccountListBloc>().state;
    // But using BlocBuilder/BlocProvider.of is generally preferred.
    return BlocBuilder<AccountListBloc, AccountListState>(
      // If Bloc is fetched via sl and not provided, specify 'bloc' instance:
      // bloc: sl<AccountListBloc>(),
      builder: (context, state) {
        List<AssetAccount> accounts = [];
        bool isLoading = false;
        String? errorMessage;

        if (state is AccountListLoading) {
          isLoading = true;
        } else if (state is AccountListLoaded) {
          accounts = state.accounts;
          // Ensure the *currently selected internal ID* is still valid within the new list.
          // If not, DropdownButtonFormField will handle it by showing no selection.
          if (_internalSelectedId != null &&
              !accounts.any((acc) => acc.id == _internalSelectedId)) {
            // The value is invalid, but we don't call setState here.
            // We might want to inform the parent via onChanged *after* the build.
            // Or reset the internal state in didUpdateWidget if the list changes drastically.
            // Simplest: Let DropdownButtonFormField handle display.
            // If we reset here, need addPostFrameCallback
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _internalSelectedId != null) {
                // Check if still mounted
                setState(() {
                  _internalSelectedId = null;
                });
                widget.onChanged(null);
              }
            });
          }
        } else if (state is AccountListError) {
          errorMessage = state.message;
        }

        // Handle error state display
        if (errorMessage != null) {
          return TextFormField(
            // Display error within a form field lookalike
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Account',
              border: const OutlineInputBorder(),
              errorText: 'Error: $errorMessage',
            ),
          );
        }

        // Handle loading state display
        if (isLoading && accounts.isEmpty) {
          // Show loading only if no accounts loaded yet
          return const InputDecorator(
            // Wrap loading in form field decoration
            decoration: InputDecoration(
              labelText: 'Account',
              border: OutlineInputBorder(),
            ),
            child: Center(
                child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ))),
          );
        }

        // Build the dropdown
        return DropdownButtonFormField<String>(
          value: _internalSelectedId, // Use internal state
          decoration: const InputDecoration(
            labelText: 'Account',
            border: OutlineInputBorder(),
            hintText: 'Select Account', // Hint text when value is null
          ),
          isExpanded: true,
          items: accounts.map((AssetAccount account) {
            return DropdownMenuItem<String>(
              value: account.id,
              child: Text(account.name),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _internalSelectedId = newValue; // Update internal state
            });
            widget.onChanged(newValue); // Notify parent
          },
          validator: widget.validator ?? // Use provided or default validator
              (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select an account';
                }
                return null;
              },
        );
      },
    );
  }
}
