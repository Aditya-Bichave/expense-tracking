import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/add_edit_account/add_edit_account_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_form.dart';
// Keep this import as it provides the intended FormStatus
import 'package:expense_tracker/features/expenses/presentation/bloc/add_edit_expense/add_edit_expense_bloc.dart';
// Removed explicit Bloc imports for refresh

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

    return BlocProvider(
      create: (context) => sl<AddEditAccountBloc>(param1: account),
      child: BlocListener<AddEditAccountBloc, AddEditAccountState>(
        listener: (context, state) {
          if (state.status == FormStatus.success) {
            // No explicit refreshes needed here anymore
            debugPrint(
                "Account save successful, relying on stream for refresh.");

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
              if (state.status == FormStatus.submitting) {
                return const Center(child: CircularProgressIndicator());
              }

              return AccountForm(
                initialAccount: state.initialAccount ?? account,
                onSubmit: (name, type, initialBalance) {
                  context.read<AddEditAccountBloc>().add(
                        SaveAccountRequested(
                          name: name,
                          type: type,
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
