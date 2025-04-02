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
  final AssetAccount? account;

  const AddEditAccountPage({
    super.key,
    this.accountId,
    this.account,
  });

  @override
  Widget build(BuildContext context) {
    final isEditing = account != null;
    log.info(
        "[AddEditAccountPage] Build called. Editing: $isEditing, AccountId: $accountId");

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
              // Handle case where page can't be popped (e.g., deep linking)
              // Maybe navigate back to the list explicitly
              log.warning(
                  "[AddEditAccountPage] Cannot pop context after successful save.");
              context.goNamed('accounts_list'); // Example fallback
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
              // Use AnimatedSwitcher for smooth transition during submission
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: state.status == FormStatus.submitting
                    ? const Center(
                        key: ValueKey('loading'),
                        child: CircularProgressIndicator())
                    : AccountForm(
                        key: const ValueKey('form'), // Key for AnimatedSwitcher
                        initialAccount:
                            state.initialAccount, // Use state's account
                        onSubmit: (name, type, initialBalance) {
                          log.info(
                              "[AddEditAccountPage] Form submitted. Dispatching SaveAccountRequested.");
                          context.read<AddEditAccountBloc>().add(
                                SaveAccountRequested(
                                  name: name,
                                  type: type,
                                  initialBalance: initialBalance,
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
