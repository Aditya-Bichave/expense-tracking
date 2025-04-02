import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/add_edit_account/add_edit_account_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_form.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
// Keep this import as it provides the intended FormStatus
import 'package:expense_tracker/features/expenses/presentation/bloc/add_edit_expense/add_edit_expense_bloc.dart';
// --- HIDE FormStatus from this import ---

// --- OR if AssetAccountType is defined elsewhere (e.g., in asset_account.dart), you might not need the enums.dart import at all here. ---
// If AssetAccountType is defined in asset_account.dart, you can remove the enums.dart import entirely.
// import 'package:expense_tracker/core/utils/enums.dart'; // Remove if AssetAccountType is elsewhere

class AddEditAccountPage extends StatelessWidget {
  // ... (rest of the code remains the same) ...
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

    return BlocProvider(
      create: (context) => sl<AddEditAccountBloc>(param1: account),
      child: BlocListener<AddEditAccountBloc, AddEditAccountState>(
        listener: (context, state) {
          // Now FormStatus unambiguously refers to the one from add_edit_expense_bloc.dart
          if (state.status == FormStatus.success) {
            try {
              sl<AccountListBloc>().add(LoadAccounts());
            } catch (e) {
              debugPrint("Could not refresh account list: $e");
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Account ${isEditing ? 'updated' : 'added'} successfully!')),
            );
            if (context.canPop()) {
              context.pop();
            }
          } else if (state.status == FormStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
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
              // Now FormStatus unambiguously refers to the one from add_edit_expense_bloc.dart
              if (state.status == FormStatus.submitting) {
                return const Center(child: CircularProgressIndicator());
              }

              return AccountForm(
                initialAccount: state.initialAccount ?? account,
                onSubmit: (name, type, initialBalance) {
                  // AssetAccountType is hopefully defined in enums.dart or AssetAccount itself
                  context.read<AddEditAccountBloc>().add(
                        SaveAccountRequested(
                          name: name,
                          type:
                              type, // Ensure this 'type' matches AssetAccountType from event
                          initialBalance: initialBalance,
                          existingAccountId: isEditing ? account!.id : null,
                        ),
                      );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
