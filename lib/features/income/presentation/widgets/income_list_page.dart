import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/income/presentation/bloc/income_list/income_list_bloc.dart';
import 'package:expense_tracker/features/income/presentation/widgets/income_card.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/entities/income_category.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/features/expenses/presentation/pages/expense_list_page.dart'; // Import shared FilterDialogContent
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import SettingsBloc

class IncomeListPage extends StatefulWidget {
  // Changed to StatefulWidget
  const IncomeListPage({super.key});

  @override
  State<IncomeListPage> createState() => _IncomeListPageState();
}

class _IncomeListPageState extends State<IncomeListPage> {
  // Added State
  late IncomeListBloc _incomeListBloc;
  // AccountListBloc is assumed to be provided globally

  // --- State for Table View Toggle ---
  bool _isTableView = false;

  @override
  void initState() {
    super.initState();
    log.info("[IncomeListPage] initState called.");
    _incomeListBloc = sl<IncomeListBloc>();
    if (_incomeListBloc.state is IncomeListInitial) {
      log.info(
          "[IncomeListPage] Initial state detected, dispatching LoadIncomes.");
      _incomeListBloc.add(const LoadIncomes());
    }
    // Ensure AccountListBloc is loaded if needed for names (usually loaded by Accounts tab)
    final accountBloc = sl<AccountListBloc>();
    if (accountBloc.state is AccountListInitial) {
      log.info(
          "[IncomeListPage] AccountListBloc is initial, dispatching LoadAccounts.");
      accountBloc.add(const LoadAccounts());
    }
  }

  void _navigateToAddIncome() {
    log.info("[IncomeListPage] Navigating to add income.");
    context.pushNamed('add_income');
  }

  void _navigateToEditIncome(Income incomeToEdit) {
    log.info(
        "[IncomeListPage] Navigating to edit income '${incomeToEdit.title}' (ID: ${incomeToEdit.id}).");
    context.pushNamed('edit_income',
        pathParameters: {'id': incomeToEdit.id}, extra: incomeToEdit);
  }

  Future<void> _refreshIncome() async {
    log.info("[IncomeListPage] Pull-to-refresh triggered.");
    // Refresh this list's BLoC and account names
    try {
      context.read<IncomeListBloc>().add(const LoadIncomes(forceReload: true));
      context
          .read<AccountListBloc>()
          .add(const LoadAccounts(forceReload: true));

      // Wait for both Blocs to finish loading
      await Future.wait([
        context.read<IncomeListBloc>().stream.firstWhere(
            (state) => state is IncomeListLoaded || state is IncomeListError),
        context.read<AccountListBloc>().stream.firstWhere(
            (state) => state is AccountListLoaded || state is AccountListError),
      ]).timeout(const Duration(seconds: 5)); // Add timeout
      log.info("[IncomeListPage] Refresh streams finished or timed out.");
    } catch (e) {
      log.warning("[IncomeListPage] Error during refresh: $e");
    }
  }

  // Show confirmation dialog for deletion
  Future<bool> _confirmDeletion(BuildContext context, Income income) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: const Text("Confirm Deletion"),
            content: Text(
              'Are you sure you want to delete the income "${income.title}"?',
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
        false;
  }

  // --- Build DataTable View ---
  Widget _buildDataTable(BuildContext context, List<Income> incomes,
      AccountListState accountState) {
    final theme = Theme.of(context);
    final currencySymbol = context.read<SettingsBloc>().state.currencySymbol;
    final bool isQuantum =
        context.read<SettingsBloc>().state.uiMode == UIMode.quantum;

    Map<String, String> accountNames = {};
    if (accountState is AccountListLoaded) {
      accountNames = {for (var acc in accountState.accounts) acc.id: acc.name};
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: isQuantum ? 10 : 15,
        horizontalMargin: isQuantum ? 8 : 12,
        headingRowHeight: isQuantum ? 28 : 35,
        dataRowMinHeight: isQuantum ? 30 : 35,
        dataRowMaxHeight: isQuantum ? 35 : 40,
        showCheckboxColumn: false,
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Title')),
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Account')),
          DataColumn(label: Text('Amount'), numeric: true),
        ],
        rows: incomes.map((income) {
          final accountName = accountNames[income.accountId] ?? 'Unknown';
          return DataRow(
            onSelectChanged: (_) => _navigateToEditIncome(income),
            cells: [
              DataCell(Text(DateFormatter.formatDate(income.date))),
              DataCell(Text(income.title, overflow: TextOverflow.ellipsis)),
              DataCell(
                  Text(income.category.name, overflow: TextOverflow.ellipsis)),
              DataCell(Text(accountName, overflow: TextOverflow.ellipsis)),
              DataCell(Text(
                  CurrencyFormatter.format(income.amount, currencySymbol))),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    log.info("[IncomeListPage] Build method called.");
    final theme = Theme.of(context);
    final uiMode = context.watch<SettingsBloc>().state.uiMode;
    final bool showTableViewToggle = uiMode == UIMode.quantum;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
        actions: [
          // --- View Toggle Button (Quantum Mode Only) ---
          if (showTableViewToggle)
            IconButton(
              icon: Icon(_isTableView
                  ? Icons.view_list_outlined
                  : Icons.table_rows_outlined),
              tooltip:
                  _isTableView ? 'Switch to Card View' : 'Switch to Table View',
              onPressed: () => setState(() => _isTableView = !_isTableView),
            ),
          // Filter button
          BlocBuilder<IncomeListBloc, IncomeListState>(
            builder: (context, state) {
              bool filtersApplied = false;
              if (state is IncomeListLoaded) {
                filtersApplied = state.filterStartDate != null ||
                    state.filterEndDate != null ||
                    state.filterCategory != null ||
                    state.filterAccountId != null;
              }
              return IconButton(
                icon: Icon(filtersApplied
                    ? Icons.filter_list
                    : Icons.filter_list_off_outlined),
                tooltip: 'Filter Income',
                onPressed: () =>
                    _showFilterDialog(context, state), // Pass current state
              );
            },
          ),
        ],
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _incomeListBloc),
          BlocProvider.value(value: sl<AccountListBloc>()),
        ],
        child: BlocConsumer<IncomeListBloc, IncomeListState>(
          listener: (context, incomeState) {
            log.info(
                "[IncomeListPage] BlocListener received state: ${incomeState.runtimeType}");
            if (incomeState is IncomeListError) {
              log.warning(
                  "[IncomeListPage] Error state detected: ${incomeState.message}");
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(incomeState.message),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
            }
          },
          builder: (context, incomeState) {
            log.info(
                "[IncomeListPage] BlocBuilder building for income state: ${incomeState.runtimeType}");
            Widget listContent;

            if (incomeState is IncomeListLoading && !incomeState.isReloading) {
              log.info(
                  "[IncomeListPage UI] State is initial IncomeListLoading. Showing CircularProgressIndicator.");
              listContent = const Center(child: CircularProgressIndicator());
            } else if (incomeState is IncomeListLoaded ||
                (incomeState is IncomeListLoading && incomeState.isReloading)) {
              final incomes = (incomeState is IncomeListLoaded)
                  ? incomeState.incomes
                  : (context.read<IncomeListBloc>().state as IncomeListLoaded?)
                          ?.incomes ??
                      [];
              final bool filtersActive = incomeState is IncomeListLoaded &&
                  (incomeState.filterStartDate != null ||
                      incomeState.filterEndDate != null ||
                      incomeState.filterCategory != null ||
                      incomeState.filterAccountId != null);

              if (incomes.isEmpty) {
                log.info("[IncomeListPage UI] Income list is empty.");
                listContent = Center(
                  // Same empty state for now
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            filtersActive
                                ? Icons.filter_alt_off_outlined
                                : Icons.attach_money_outlined,
                            size: 60,
                            color: theme.colorScheme.secondary),
                        const SizedBox(height: 16),
                        Text(
                          filtersActive
                              ? 'No income matches the current filters.'
                              : 'No income recorded yet.',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(color: theme.colorScheme.secondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        if (filtersActive)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.clear_all, size: 18),
                            label: const Text('Clear Filters'),
                            style: ElevatedButton.styleFrom(
                                visualDensity: VisualDensity.compact),
                            onPressed: () {
                              log.info("[IncomeListPage] Clearing filters.");
                              context
                                  .read<IncomeListBloc>()
                                  .add(const FilterIncomes()); // Clear filters
                            },
                          )
                        else
                          Text(
                            'Tap "+" to add your first income!',
                            style: theme.textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                );
              } else {
                log.info(
                    "[IncomeListPage UI] Income list has ${incomes.length} items. Building List/Table view. isTable: $_isTableView");
                // --- CONDITIONAL LIST VIEW / TABLE VIEW ---
                if (_isTableView && showTableViewToggle) {
                  listContent = BlocBuilder<AccountListBloc, AccountListState>(
                      builder: (context, accountState) {
                    return _buildDataTable(context, incomes, accountState);
                  });
                } else {
                  listContent = BlocBuilder<AccountListBloc, AccountListState>(
                    // Key helps AnimatedSwitcher differentiate
                    key: const ValueKey('income_list_cards'),
                    builder: (context, accountState) {
                      log.info(
                          "[IncomeListPage UI] Nested AccountListBloc state: ${accountState.runtimeType}");
                      if (accountState is AccountListLoading) {
                        // Optionally show indicator while loading names
                        // return const Center(child: Text("Loading account names..."));
                      }

                      return RefreshIndicator(
                        onRefresh: _refreshIncome,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: incomes.length,
                          itemBuilder: (context, index) {
                            final income = incomes[index];
                            return Dismissible(
                              key:
                                  Key('income_card_${income.id}'), // Unique key
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: theme.colorScheme.errorContainer,
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text("Delete",
                                        style: TextStyle(
                                            color: theme
                                                .colorScheme.onErrorContainer,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Icon(Icons.delete_sweep_outlined,
                                        color:
                                            theme.colorScheme.onErrorContainer),
                                  ],
                                ),
                              ),
                              confirmDismiss: (direction) =>
                                  _confirmDeletion(context, income),
                              onDismissed: (direction) {
                                log.info(
                                    "[IncomeListPage] Dismissed income '${income.title}'. Dispatching delete request.");
                                context
                                    .read<IncomeListBloc>()
                                    .add(DeleteIncomeRequested(income.id));
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(SnackBar(
                                    content: Text(
                                        'Income "${income.title}" deleted.'),
                                    backgroundColor: Colors.orange,
                                  ));
                              },
                              child: IncomeCard(
                                income: income,
                                onTap: () => _navigateToEditIncome(income),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }
                // --- END CONDITIONAL VIEW ---
              }
            } else if (incomeState is IncomeListError) {
              log.info(
                  "[IncomeListPage UI] State is IncomeListError: ${incomeState.message}. Showing error UI.");
              listContent = Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          color: theme.colorScheme.error, size: 50),
                      const SizedBox(height: 16),
                      Text('Failed to load income',
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(incomeState.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.colorScheme.error)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: () => context
                            .read<IncomeListBloc>()
                            .add(const LoadIncomes(forceReload: true)),
                      )
                    ],
                  ),
                ),
              );
            } else {
              log.info(
                  "[IncomeListPage UI] State is Initial or Unknown. Showing loading indicator.");
              listContent = const Center(child: CircularProgressIndicator());
            }

            // Animate state changes
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: listContent,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_income', // Unique HeroTag
        onPressed: _navigateToAddIncome,
        tooltip: 'Add Income',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Filter Dialog Logic (Adapted for Income)
  void _showFilterDialog(BuildContext context, IncomeListState currentState) {
    log.info("[IncomeListPage] Showing filter dialog for income.");
    DateTime? currentStart;
    DateTime? currentEnd;
    String? currentCategoryName;
    String? currentAccountId;
    if (currentState is IncomeListLoaded) {
      currentStart = currentState.filterStartDate;
      currentEnd = currentState.filterEndDate;
      currentCategoryName = currentState.filterCategory;
      currentAccountId = currentState.filterAccountId;
    }

    // Get Income Category Names
    final List<String> incomeCategoryNames = PredefinedIncomeCategory.values
        .map<String>((e) => IncomeCategory.fromPredefined(e).name)
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Use the shared FilterDialogContent widget from expense_list_page
        return FilterDialogContent(
          isIncomeFilter: true, // Set flag
          incomeCategoryNames: incomeCategoryNames,
          expenseCategoryNames: const [], // Pass empty list
          initialStartDate: currentStart,
          initialEndDate: currentEnd,
          initialCategoryName: currentCategoryName,
          initialAccountId: currentAccountId,
          onApplyFilter: (startDate, endDate, categoryName, accountId) {
            log.info(
                "[IncomeListPage] Filter dialog applied. Start=$startDate, End=$endDate, Cat=$categoryName, AccID=$accountId");
            context.read<IncomeListBloc>().add(FilterIncomes(
                  startDate: startDate,
                  endDate: endDate,
                  category: categoryName,
                  accountId: accountId,
                ));
            Navigator.of(dialogContext).pop();
          },
          onClearFilter: () {
            log.info("[IncomeListPage] Filter dialog cleared.");
            context.read<IncomeListBloc>().add(const FilterIncomes());
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }
}
