import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_card.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

// No explicit imports needed for DashboardBloc etc. as refresh is handled by stream

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
    debugPrint("[AccountListPage] initState called.");
    // Get the singleton instance from Service Locator
    _accountListBloc = sl<AccountListBloc>();
    if (_accountListBloc == null) {
      debugPrint(
          "[AccountListPage] !!! CRITICAL: _accountListBloc is NULL after sl retrieval !!!");
    } else {
      debugPrint(
          "[AccountListPage] _accountListBloc retrieved successfully from sl.");
      // Trigger initial load only if the state is initial
      // This prevents unnecessary reloads if the page is revisited
      if (_accountListBloc.state is AccountListInitial) {
        debugPrint(
            "[AccountListPage] Initial state detected, dispatching LoadAccounts.");
        _accountListBloc.add(const LoadAccounts());
      }
    }
  }

  void _navigateToAddAccount() {
    context.pushNamed('add_account');
  }

  void _navigateToEditAccount(AssetAccount account) {
    context.pushNamed('edit_account',
        pathParameters: {'id': account.id}, extra: account);
  }

  // Handles manual pull-to-refresh
  Future<void> _refreshAccounts() async {
    debugPrint("[AccountListPage] _refreshAccounts called.");
    // Trigger load event for this page's BLoC
    // The stream subscription will handle refreshing other necessary BLoCs (like Dashboard)
    try {
      // Force reload to ensure fresh data even if state didn't change
      context
          .read<AccountListBloc>()
          .add(const LoadAccounts(forceReload: true));
    } catch (e) {
      debugPrint("Error reading AccountListBloc for refresh: $e");
      return;
    }

    // Optionally wait for the state update if needed for UI feedback before ending refresh indicator
    try {
      await context.read<AccountListBloc>().stream.firstWhere(
          (state) => state is AccountListLoaded || state is AccountListError,
          orElse: () => AccountListInitial() // Provide a fallback value
          );
      debugPrint("[AccountListPage] Refresh stream finished.");
    } catch (e) {
      // Don't block indefinitely if stream has error or closes unexpectedly
      debugPrint("[AccountListPage] Error waiting for refresh stream: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("[AccountListPage] build method called.");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
        // Optional: Add refresh button if pull-to-refresh isn't sufficient
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.refresh),
        //     onPressed: () => _refreshAccounts(),
        //     tooltip: 'Refresh Accounts',
        //   )
        // ],
      ),
      body: BlocProvider.value(
        // Use .value as sl manages the BLoC lifecycle
        value: _accountListBloc,
        child: BlocConsumer<AccountListBloc, AccountListState>(
          listener: (context, state) {
            debugPrint(
                "[AccountListPage] BlocListener received state: ${state.runtimeType}");
            // Display errors via SnackBar ONLY if they are not deletion errors
            // (as the builder handles general errors and deletion might revert UI)
            if (state is AccountListError &&
                !state.message.contains("Failed to delete")) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            debugPrint(
                "[AccountListPage] BlocBuilder building for state: ${state.runtimeType}");
            try {
              // Show loading indicator only on initial load or forced reload
              if (state is AccountListLoading && state is! AccountListLoaded) {
                debugPrint(
                    "[AccountListPage UI] State is AccountListLoading. Showing CircularProgressIndicator.");
                return const Center(child: CircularProgressIndicator());
              } else if (state is AccountListLoaded) {
                debugPrint(
                    "[AccountListPage UI] State is AccountListLoaded with ${state.accounts.length} accounts. Building list.");
                final accounts = state.accounts;
                if (accounts.isEmpty) {
                  // Display empty state UI
                  debugPrint(
                      "[AccountListPage UI] Account list is empty. Showing empty state.");
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined,
                            size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No accounts yet.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Account'),
                          onPressed: _navigateToAddAccount,
                        )
                      ],
                    ),
                  );
                }
                // Display the list
                debugPrint(
                    "[AccountListPage UI] Account list has items. Building ListView.");
                return RefreshIndicator(
                  onRefresh: () =>
                      _refreshAccounts(), // Use the refresh method here
                  child: ListView.builder(
                    // Ensure scrolling works for RefreshIndicator
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      return Dismissible(
                        key: Key(account.id), // Unique key for Dismissible
                        direction:
                            DismissDirection.endToStart, // Swipe direction
                        background: Container(
                          // Background shown during swipe
                          color: Colors.red[700],
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text("Delete",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Icon(Icons.delete_sweep_outlined,
                                  color: Colors.white),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          // Show confirmation dialog before deleting
                          return await showDialog<bool>(
                                context: context,
                                builder: (BuildContext ctx) => AlertDialog(
                                  title: const Text("Confirm Deletion"),
                                  content: Text(
                                      'Delete account "${account.name}"? Check linked transactions first.'),
                                  actions: <Widget>[
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text("Cancel")),
                                    TextButton(
                                        style: TextButton.styleFrom(
                                            foregroundColor: Colors.red),
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text("Delete")),
                                  ],
                                ),
                              ) ??
                              false; // Return false if dialog is dismissed
                        },
                        onDismissed: (direction) {
                          // Only dispatch the delete request here
                          // The BLoC will publish an event, triggering other BLoCs
                          context
                              .read<AccountListBloc>()
                              .add(DeleteAccountRequested(account.id));

                          // Show a confirmation SnackBar
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Account "${account.name}" deleted.'),
                            backgroundColor: Colors.orange,
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
              } else if (state is AccountListError) {
                // Display error UI
                debugPrint(
                    "[AccountListPage UI] State is AccountListError: ${state.message}. Showing error UI.");
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: 50),
                        const SizedBox(height: 16),
                        Text('Failed to load accounts:',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          // Use context.read inside callbacks
                          onPressed: () => context
                              .read<AccountListBloc>()
                              .add(const LoadAccounts()),
                        )
                      ],
                    ),
                  ),
                );
              }
              // Fallback for Initial state (or other unhandled states)
              debugPrint(
                  "[AccountListPage UI] State is Initial or Unknown (${state.runtimeType}). Showing loading indicator.");
              return const Center(child: CircularProgressIndicator());
            } catch (e, s) {
              // Catch potential errors during UI build
              debugPrint(
                  "[AccountListPage UI] *** CRITICAL: Exception during UI build for state ${state.runtimeType}: $e\n$s");
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error building UI.\nCheck logs for details.',
                    style: TextStyle(color: Colors.red[900]),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
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
