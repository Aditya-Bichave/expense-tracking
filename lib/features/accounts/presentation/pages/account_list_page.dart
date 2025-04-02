import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_card.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/main.dart'; // Import logger

class AccountListPage extends StatefulWidget {
  const AccountListPage({super.key});

  @override
  State<AccountListPage> createState() => _AccountListPageState();
}

class _AccountListPageState extends State<AccountListPage> {
  late AccountListBloc _accountListBloc;

  @override
  void initState() {
    super.initState();
    log.info("[AccountListPage] initState called.");
    _accountListBloc = sl<AccountListBloc>();
    // Trigger initial load only if the state is initial
    if (_accountListBloc.state is AccountListInitial) {
      log.info(
          "[AccountListPage] Initial state detected, dispatching LoadAccounts.");
      _accountListBloc.add(const LoadAccounts());
    }
  }

  void _navigateToAddAccount() {
    log.info("[AccountListPage] Navigating to add account.");
    context.pushNamed('add_account');
  }

  void _navigateToEditAccount(AssetAccount account) {
    log.info(
        "[AccountListPage] Navigating to edit account '${account.name}' (ID: ${account.id}).");
    context.pushNamed('edit_account',
        pathParameters: {'id': account.id}, extra: account);
  }

  // Handles manual pull-to-refresh
  Future<void> _refreshAccounts() async {
    log.info("[AccountListPage] Pull-to-refresh triggered.");
    // The stream subscription in the BLoC handles triggering reloads automatically,
    // but pull-to-refresh should force it.
    _accountListBloc.add(const LoadAccounts(forceReload: true));

    // Wait for the BLoC to finish loading (either Loaded or Error state)
    // Add a timeout to prevent waiting indefinitely
    try {
      await _accountListBloc.stream
          .firstWhere((state) =>
              state is AccountListLoaded || state is AccountListError)
          .timeout(const Duration(seconds: 5)); // Example timeout
      log.info("[AccountListPage] Refresh stream finished or timed out.");
    } catch (e) {
      log.warning(
          "[AccountListPage] Error or timeout waiting for refresh stream: $e");
    }
  }

  // Show confirmation dialog for deletion
  Future<bool> _confirmDeletion(
      BuildContext context, AssetAccount account) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: const Text("Confirm Deletion"),
            content: Text(
              'Are you sure you want to delete the account "${account.name}"?\n\nThis action cannot be undone. Ensure no transactions are linked if your logic prevents deletion.', // Updated message
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Theme.of(ctx).colorScheme.error),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text("Delete"),
              ),
            ],
          ),
        ) ??
        false; // Return false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    log.info("[AccountListPage] build method called.");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        // Refresh button kept for explicit action if needed
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshAccounts(),
            tooltip: 'Refresh Accounts',
          )
        ],
      ),
      body: BlocProvider.value(
        value: _accountListBloc,
        child: BlocConsumer<AccountListBloc, AccountListState>(
          listener: (context, state) {
            log.info(
                "[AccountListPage] BlocListener received state: ${state.runtimeType}");
            // Show deletion error messages specifically
            if (state is AccountListError) {
              log.warning(
                  "[AccountListPage] Error state detected: ${state.message}");
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.message), // Show mapped error message
                    backgroundColor: Theme.of(context).colorScheme.error,
                    duration: const Duration(seconds: 4),
                  ),
                );
              // After showing error, transition back to loaded state if possible
              // This prevents the error UI from persisting indefinitely after a failed delete
              // We need the previous loaded state for this.
              // A better approach might be to have error as part of the Loaded state.
              // For now, let's trigger a reload to potentially clear the error UI.
              // Future.delayed(const Duration(milliseconds: 100), () {
              //    if (state is AccountListError) { // Check again in case state changed rapidly
              //      _accountListBloc.add(const LoadAccounts(forceReload: true));
              //    }
              // });
            }
          },
          builder: (context, state) {
            log.info(
                "[AccountListPage] BlocBuilder building for state: ${state.runtimeType}");

            Widget child; // Widget to be animated

            // Handle different states
            if (state is AccountListLoading && !state.isReloading) {
              log.info(
                  "[AccountListPage UI] State is initial AccountListLoading. Showing CircularProgressIndicator.");
              child = const Center(child: CircularProgressIndicator());
            } else if (state is AccountListLoaded ||
                (state is AccountListLoading && state.isReloading)) {
              // Show list even during reload, potentially with a subtle indicator if needed
              final accounts = (state is AccountListLoaded)
                  ? state.accounts
                  : (_accountListBloc.state as AccountListLoaded?)?.accounts ??
                      []; // Use previous accounts if reloading

              if (accounts.isEmpty) {
                log.info(
                    "[AccountListPage UI] Account list is empty. Showing empty state.");
                child = Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 60,
                          color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(height: 16),
                      Text('No accounts yet.',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary)),
                      const SizedBox(height: 10),
                      Text('Tap "+" to add your first account.',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Account'),
                        onPressed: _navigateToAddAccount,
                      )
                    ],
                  ),
                );
              } else {
                log.info(
                    "[AccountListPage UI] Account list has ${accounts.length} items. Building ListView.");
                child = RefreshIndicator(
                  onRefresh: _refreshAccounts,
                  child: ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(), // Ensure scroll for refresh
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      return Dismissible(
                        key: Key('account_${account.id}'), // Unique key
                        direction:
                            DismissDirection.endToStart, // Swipe direction
                        background: Container(
                          // Background shown during swipe
                          color: Theme.of(context).colorScheme.errorContainer,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("Delete",
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Icon(Icons.delete_sweep_outlined,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) =>
                            _confirmDeletion(context, account), // Use helper
                        onDismissed: (direction) {
                          log.info(
                              "[AccountListPage] Dismissed account '${account.name}'. Dispatching delete request.");
                          _accountListBloc
                              .add(DeleteAccountRequested(account.id));
                          // Show a confirmation SnackBar (optional, listener handles errors)
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(
                              content:
                                  Text('Account "${account.name}" deleted.'),
                              backgroundColor:
                                  Colors.orange, // Use theme color?
                            ));
                        },
                        child: AccountCard(
                          // The actual list item widget
                          account: account,
                          onTap: () => _navigateToEditAccount(account),
                        ),
                      );
                    },
                  ),
                );
              }
            } else if (state is AccountListError) {
              log.info(
                  "[AccountListPage UI] State is AccountListError: ${state.message}. Showing error UI.");
              child = Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          color: Theme.of(context).colorScheme.error, size: 50),
                      const SizedBox(height: 16),
                      Text('Failed to load accounts',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: () => _accountListBloc
                            .add(const LoadAccounts(forceReload: true)),
                      )
                    ],
                  ),
                ),
              );
            } else {
              // Fallback for Initial state
              log.info(
                  "[AccountListPage UI] State is Initial or Unknown (${state.runtimeType}). Showing loading indicator.");
              child = const Center(child: CircularProgressIndicator());
            }

            // Animate between states
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: child,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_accounts', // Ensure unique HeroTag
        onPressed: _navigateToAddAccount,
        tooltip: 'Add Account',
        child: const Icon(Icons.add),
      ),
    );
  }
}
