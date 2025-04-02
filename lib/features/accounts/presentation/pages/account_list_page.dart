import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import '../bloc/account_list/account_list_bloc.dart';
import '../widgets/account_card.dart';
import '../../domain/entities/asset_account.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

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
    _accountListBloc = sl<AccountListBloc>();
    if (_accountListBloc == null) {
      debugPrint(
          "[AccountListPage] !!! CRITICAL: _accountListBloc is NULL after sl retrieval !!!");
    } else {
      debugPrint(
          "[AccountListPage] _accountListBloc retrieved successfully from sl.");
    }
    // Initial load triggered by BlocProvider in main.dart
  }

  void _navigateToAddAccount() {
    context.pushNamed('add_account');
  }

  void _navigateToEditAccount(AssetAccount account) {
    context.pushNamed('edit_account',
        pathParameters: {'id': account.id}, extra: account);
  }

  Future<void> _refreshAccounts() async {
    debugPrint("[AccountListPage] _refreshAccounts called.");
    _accountListBloc.add(LoadAccounts());
    try {
      await _accountListBloc.stream.firstWhere(
          (state) => state is AccountListLoaded || state is AccountListError);
      debugPrint("[AccountListPage] Refresh stream finished.");
    } catch (e) {
      debugPrint("[AccountListPage] Error waiting for refresh stream: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("[AccountListPage] build method called.");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts'),
      ),
      body: BlocProvider.value(
        value: _accountListBloc,
        child: BlocConsumer<AccountListBloc, AccountListState>(
          listener: (context, state) {
            debugPrint(
                "[AccountListPage] BlocListener received state: ${state.runtimeType}");
            if (state is AccountListError) {
              bool isDeletionError =
                  state.message.contains("Failed to delete account");
              if (!isDeletionError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error loading accounts: ${state.message}'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            }
          },
          builder: (context, state) {
            debugPrint(
                "[AccountListPage] BlocBuilder building for state: ${state.runtimeType}");
            try {
              if (state is AccountListLoading) {
                debugPrint(
                    "[AccountListPage UI] State is AccountListLoading. Showing empty space (no indicator).");
                // --- REMOVED CircularProgressIndicator ---
                return const SizedBox.shrink(); // Return an empty widget
                // -----------------------------------------
              } else if (state is AccountListLoaded) {
                debugPrint(
                    "[AccountListPage UI] State is AccountListLoaded with ${state.accounts.length} accounts. Building list.");
                final accounts = state.accounts;
                if (accounts.isEmpty) {
                  debugPrint(
                      "[AccountListPage UI] Account list is empty. Showing empty state.");
                  // Empty state UI
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
                debugPrint(
                    "[AccountListPage UI] Account list has items. Building ListView.");
                // List View Builder
                return RefreshIndicator(
                  onRefresh: _refreshAccounts,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      return Dismissible(
                        key: Key(account.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
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
                              false;
                        },
                        onDismissed: (direction) {
                          context
                              .read<AccountListBloc>()
                              .add(DeleteAccountRequested(account.id));
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Account "${account.name}" deleted.'),
                            backgroundColor: Colors.orange,
                          ));
                        },
                        child: AccountCard(
                          account: account,
                          onTap: () => _navigateToEditAccount(account),
                        ),
                      );
                    },
                  ),
                );
              } else if (state is AccountListError) {
                debugPrint(
                    "[AccountListPage UI] State is AccountListError: ${state.message}. Showing error UI.");
                // Error UI
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
                          onPressed: () => _accountListBloc.add(LoadAccounts()),
                        )
                      ],
                    ),
                  ),
                );
              }
              // Fallback for Initial state (or any other unhandled state)
              debugPrint(
                  "[AccountListPage UI] State is Initial or Unknown (${state.runtimeType}). Showing empty space (no indicator).");
              // --- REMOVED CircularProgressIndicator ---
              return const SizedBox.shrink(); // Return an empty widget
              // -----------------------------------------
            } catch (e, s) {
              debugPrint(
                  "[AccountListPage UI] *** CRITICAL: Exception during UI build for state ${state.runtimeType}: $e\n$s");
              // Return a safe fallback UI in case of build error
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error building UI for state ${state.runtimeType}.\nCheck logs for details.\n$e',
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
        heroTag: 'fab_accounts',
        onPressed: _navigateToAddAccount,
        tooltip: 'Add Account',
        child: const Icon(Icons.add),
      ),
    );
  }
}
