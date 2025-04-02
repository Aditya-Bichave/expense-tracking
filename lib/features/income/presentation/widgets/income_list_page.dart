import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/income/presentation/bloc/income_list/income_list_bloc.dart';
import 'package:expense_tracker/features/income/presentation/widgets/income_card.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart'; // Needed for names
import 'package:flutter/foundation.dart'; // For debugPrint
// Removed explicit Bloc imports for refresh

class IncomeListPage extends StatefulWidget {
  const IncomeListPage({super.key});

  @override
  State<IncomeListPage> createState() => _IncomeListPageState();
}

class _IncomeListPageState extends State<IncomeListPage> {
  late IncomeListBloc _incomeListBloc;
  // AccountListBloc is likely provided globally or via MultiBlocProvider higher up

  @override
  void initState() {
    super.initState();
    debugPrint("[IncomeListPage] initState called.");
    _incomeListBloc = sl<IncomeListBloc>();
    if (_incomeListBloc.state is IncomeListInitial) {
      debugPrint(
          "[IncomeListPage] Initial state detected, dispatching LoadIncomes.");
      _incomeListBloc.add(const LoadIncomes());
    }
    // Assuming AccountListBloc is already loaded or handled elsewhere
  }

  void _navigateToAddIncome() {
    context.pushNamed('add_income');
  }

  void _navigateToEditIncome(Income incomeToEdit) {
    context.pushNamed('edit_income',
        pathParameters: {'id': incomeToEdit.id}, extra: incomeToEdit);
  }

  Future<void> _refreshIncome() async {
    debugPrint("[IncomeListPage] _refreshIncome called.");
    // Refresh this list's BLoC and potentially account names
    try {
      context.read<IncomeListBloc>().add(const LoadIncomes(forceReload: true));
      context
          .read<AccountListBloc>()
          .add(const LoadAccounts(forceReload: true)); // Refresh names
    } catch (e) {
      debugPrint("Error reading Blocs for refresh: $e");
      return;
    }

    // Wait for states if needed
    try {
      await Future.wait([
        context.read<IncomeListBloc>().stream.firstWhere(
            (state) => state is IncomeListLoaded || state is IncomeListError,
            orElse: () => IncomeListInitial() // Fallback
            ),
        context.read<AccountListBloc>().stream.firstWhere(
            (state) => state is AccountListLoaded || state is AccountListError,
            orElse: () => AccountListInitial() // Fallback
            )
      ]);
      debugPrint("[IncomeListPage] Refresh streams finished.");
    } catch (e) {
      debugPrint("[IncomeListPage] Error waiting for refresh streams: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("[IncomeListPage] build method called.");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
      ),
      body: MultiBlocProvider(
        // Provide necessary Blocs if not already available above
        providers: [
          BlocProvider.value(value: _incomeListBloc),
          // Assuming AccountListBloc is provided above, otherwise:
          // BlocProvider.value(value: sl<AccountListBloc>()),
        ],
        child: BlocConsumer<IncomeListBloc, IncomeListState>(
          listener: (context, incomeState) {
            debugPrint(
                "[IncomeListPage] BlocListener received state: ${incomeState.runtimeType}");
            if (incomeState is IncomeListError) {
              bool isDeletionError =
                  incomeState.message.contains("Failed to delete income");
              if (!isDeletionError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Error loading income: ${incomeState.message}'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            }
          },
          builder: (context, incomeState) {
            debugPrint(
                "[IncomeListPage] BlocBuilder building for state: ${incomeState.runtimeType}");
            try {
              if (incomeState is IncomeListLoading) {
                debugPrint(
                    "[IncomeListPage UI] State is IncomeListLoading. Showing empty space (no indicator).");
                // --- REMOVED CircularProgressIndicator ---
                return const SizedBox.shrink(); // Return an empty widget
                // -----------------------------------------
              } else if (incomeState is IncomeListLoaded) {
                final incomes = incomeState.incomes;
                if (incomes.isEmpty) {
                  debugPrint(
                      "[IncomeListPage UI] Income list is empty. Showing empty state.");
                  // Empty state UI
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.attach_money_outlined,
                            size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No income recorded yet.',
                            style: TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Income'),
                          onPressed: _navigateToAddIncome,
                        )
                      ],
                    ),
                  );
                }

                // Use BlocBuilder for AccountListBloc to get names
                return BlocBuilder<AccountListBloc, AccountListState>(
                  builder: (context, accountState) {
                    debugPrint(
                        "[IncomeListPage UI] Nested AccountListBloc state: ${accountState.runtimeType}");
                    // Show loading/error text for accounts only if necessary
                    if (accountState is AccountListLoading &&
                        incomes.isNotEmpty) {
                      debugPrint(
                          "[IncomeListPage UI] Accounts loading. Showing 'Loading account names...'.");
                      return const Center(
                          child: Text("Loading account names..."));
                    }
                    if (accountState is AccountListError &&
                        incomes.isNotEmpty) {
                      debugPrint(
                          "[IncomeListPage UI] Accounts error: ${accountState.message}. Showing error text.");
                      return Center(
                          child: Text(
                              "Error loading account names: ${accountState.message}"));
                    }

                    Map<String, String> accountNames = {};
                    if (accountState is AccountListLoaded) {
                      accountNames = {
                        for (var acc in accountState.accounts) acc.id: acc.name
                      };
                    }

                    debugPrint("[IncomeListPage UI] Building income ListView.");
                    // List View Builder
                    return RefreshIndicator(
                      onRefresh: _refreshIncome,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: incomes.length,
                        itemBuilder: (context, index) {
                          final income = incomes[index];
                          final accountName =
                              accountNames[income.accountId] ?? 'Unknown';
                          final categoryName = income.category.name;
                          return Dismissible(
                            key: Key(income.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red[700],
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
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
                                          'Delete income "${income.title}"?'),
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
                              // Only dispatch the delete request here
                              context
                                  .read<IncomeListBloc>()
                                  .add(DeleteIncomeRequested(income.id));
                              // No need to manually refresh other Blocs
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content:
                                    Text('Income "${income.title}" deleted.'),
                                backgroundColor: Colors.orange,
                              ));
                            },
                            child: IncomeCard(
                              income: income,
                              accountName: accountName,
                              categoryName: categoryName,
                              onTap: () => _navigateToEditIncome(income),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              } else if (incomeState is IncomeListError) {
                debugPrint(
                    "[IncomeListPage UI] State is IncomeListError: ${incomeState.message}. Showing error UI.");
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
                        Text('Failed to load income:',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(incomeState.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          onPressed: () => _incomeListBloc.add(LoadIncomes()),
                        )
                      ],
                    ),
                  ),
                );
              }
              // Fallback for Initial state
              debugPrint(
                  "[IncomeListPage UI] State is Initial or Unknown (${incomeState.runtimeType}). Showing empty space (no indicator).");
              // --- REMOVED CircularProgressIndicator ---
              return const SizedBox.shrink(); // Return an empty widget
              // -----------------------------------------
            } catch (e, s) {
              debugPrint(
                  "[IncomeListPage UI] *** CRITICAL: Exception during UI build for state ${incomeState.runtimeType}: $e\n$s");
              // Return a safe fallback UI
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error building UI for state ${incomeState.runtimeType}.\nCheck logs for details.\n$e',
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
        heroTag: 'fab_income',
        onPressed: _navigateToAddIncome,
        tooltip: 'Add Income',
        child: const Icon(Icons.add),
      ),
    );
  }
}
