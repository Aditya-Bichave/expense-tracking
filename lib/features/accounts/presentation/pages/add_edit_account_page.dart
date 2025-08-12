// lib/features/accounts/presentation/pages/add_edit_account_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/add_edit_account/add_edit_account_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_form.dart';
import 'package:expense_tracker/core/utils/enums.dart'; // Shared FormStatus
import 'package:expense_tracker/main.dart'; // Import logger

class AddEditAccountPage extends StatelessWidget {
  final String? accountId;
  final AssetAccount? account; // Received via route 'extra'

  const AddEditAccountPage({
    super.key,
    this.accountId,
    this.account,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEditing = account != null;
    log.info(
        "[AddEditAccountPage] Build called. Editing: $isEditing, AccountId: $accountId, InitialCurrentBalance: ${account?.currentBalance}");

    return BlocProvider(
      create: (context) => sl<AddEditAccountBloc>(param1: account),
      child: BlocListener<AddEditAccountBloc, AddEditAccountState>(
        listener: (context, state) {
          log.info(
              "[AddEditAccountPage] BlocListener received state: Status=${state.status}");
          if (state.status == FormStatus.success) {
            log.info(
                "[AddEditAccountPage] Form submission successful. Popping route.");
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                      'Account ${isEditing ? 'updated' : 'added'} successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            if (context.canPop()) {
              context.pop();
            } else {
              log.warning(
                  "[AddEditAccountPage] Cannot pop context after successful save.");
              context.goNamed('accounts'); // Navigate to accounts tab
            }
          } else if (state.status == FormStatus.error &&
              state.errorMessage != null) {
            log.warning(
                "[AddEditAccountPage] Form submission error: ${state.errorMessage}");
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.errorMessage}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            // Optionally clear the error message in the BLoC state here
            // context.read<AddEditAccountBloc>().add(ClearErrorMessageEvent());
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(isEditing ? 'Edit Account' : 'Add Account'),
          ),
          body: BlocBuilder<AddEditAccountBloc, AddEditAccountState>(
            builder: (context, state) {
              log.info(
                  "[AddEditAccountPage] BlocBuilder building for status: ${state.status}");

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: state.status == FormStatus.submitting
                    ? const Center(
                        key: ValueKey('loading'),
                        child: CircularProgressIndicator())
                    : AccountForm(
                        key: const ValueKey('form'),
                        initialAccount:
                            state.initialAccount, // Use state's account
                        // --- MODIFIED: Pass current balance ---
                        currentBalanceForDisplay:
                            state.initialAccount?.currentBalance,
                        // --- END MODIFIED ---
                        onSubmit: (name, type, initialBalanceFromForm) {
                          log.info(
                              "[AddEditAccountPage] Form submitted. Dispatching SaveAccountRequested. Balance value from form: $initialBalanceFromForm");
                          context.read<AddEditAccountBloc>().add(
                                SaveAccountRequested(
                                  name: name,
                                  type: type,
                                  // Pass the value from the form field as the 'initialBalance'
                                  initialBalance: initialBalanceFromForm,
                                  existingAccountId:
                                      accountId, // Use accountId from route param
                                ),
                              );
                        },
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}
