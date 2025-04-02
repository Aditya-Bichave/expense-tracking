import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/expense_list/expense_list_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_card.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart'; // Summary BLoC for SummaryCard
import 'package:expense_tracker/features/analytics/presentation/widgets/summary_card.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expenses/domain/entities/category.dart'
    as entity; // Use prefix
import 'package:expense_tracker/features/income/domain/entities/income_category.dart'; // Import for FilterDialog
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart'; // Import AccountSelectorDropdown
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart'; // Import AccountListBloc for filter

class ExpenseListPage extends StatelessWidget {
  const ExpenseListPage({super.key});

  // Method to handle manual pull-to-refresh
  Future<void> _refreshExpenses(BuildContext context) async {
    log.info("[ExpenseListPage] Pull-to-refresh triggered.");
    // Refresh expense list and summary
    try {
      context
          .read<ExpenseListBloc>()
          .add(const LoadExpenses(forceReload: true));
      // Trigger summary load with current expense filters (if any)
      final expenseState = context.read<ExpenseListBloc>().state;
      context.read<SummaryBloc>().add(LoadSummary(
            startDate: expenseState is ExpenseListLoaded
                ? expenseState.filterStartDate
                : null,
            endDate: expenseState is ExpenseListLoaded
                ? expenseState.filterEndDate
                : null,
            forceReload: true,
            updateFilters: false, // Don't update summary filters, just reload
          ));

      // Wait for expense list to finish
      await context
          .read<ExpenseListBloc>()
          .stream
          .firstWhere((state) =>
              state is ExpenseListLoaded || state is ExpenseListError)
          .timeout(const Duration(seconds: 5));
      log.info("[ExpenseListPage] Refresh stream finished or timed out.");
    } catch (e) {
      log.warning("[ExpenseListPage] Error during refresh: $e");
    }
  }

  // Show confirmation dialog for deletion
  Future<bool> _confirmDeletion(BuildContext context, Expense expense) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: const Text("Confirm Deletion"),
            content: Text(
              'Are you sure you want to delete the expense "${expense.title}"?',
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

  @override
  Widget build(BuildContext context) {
    log.info("[ExpenseListPage] Build method called.");
    final theme = Theme.of(context);
    // Ensure AccountListBloc is available for the filter dialog
    return BlocProvider.value(
      value:
          sl<AccountListBloc>(), // Provide AccountListBloc if not already above
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expenses'),
          actions: [
            // Filter button
            BlocBuilder<ExpenseListBloc, ExpenseListState>(
              builder: (context, state) {
                bool filtersApplied = false;
                if (state is ExpenseListLoaded) {
                  filtersApplied = state.filterStartDate != null ||
                      state.filterEndDate != null ||
                      state.filterCategory != null ||
                      state.filterAccountId != null;
                }
                return IconButton(
                  icon: Icon(filtersApplied
                      ? Icons.filter_list
                      : Icons.filter_list_off_outlined),
                  tooltip: 'Filter Expenses',
                  onPressed: () =>
                      _showFilterDialog(context, state), // Pass current state
                );
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => _refreshExpenses(context),
          child: Column(
            children: [
              // Summary Card (reacts to ExpenseList changes via its own listener)
              const SummaryCard(),
              const Divider(height: 1, thickness: 1),
              Expanded(
                child: BlocConsumer<ExpenseListBloc, ExpenseListState>(
                  listener: (context, state) {
                    log.info(
                        "[ExpenseListPage] BlocListener received state: ${state.runtimeType}");
                    if (state is ExpenseListError) {
                      log.warning(
                          "[ExpenseListPage] Error state detected: ${state.message}");
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: theme.colorScheme.error,
                          ),
                        );
                    }
                  },
                  builder: (context, state) {
                    log.info(
                        "[ExpenseListPage] BlocBuilder building for state: ${state.runtimeType}");
                    Widget child;

                    if (state is ExpenseListLoading && !state.isReloading) {
                      log.info(
                          "[ExpenseListPage UI] State is initial ExpenseListLoading. Showing CircularProgressIndicator.");
                      child = const Center(child: CircularProgressIndicator());
                    } else if (state is ExpenseListLoaded ||
                        (state is ExpenseListLoading && state.isReloading)) {
                      final expenses = (state is ExpenseListLoaded)
                          ? state.expenses
                          : (context.read<ExpenseListBloc>().state
                                      as ExpenseListLoaded?)
                                  ?.expenses ??
                              [];
                      final bool filtersActive = state is ExpenseListLoaded &&
                          (state.filterStartDate != null ||
                              state.filterEndDate != null ||
                              state.filterCategory != null ||
                              state.filterAccountId != null);

                      if (expenses.isEmpty) {
                        log.info("[ExpenseListPage UI] Expense list is empty.");
                        child = Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                    filtersActive
                                        ? Icons.filter_alt_off_outlined
                                        : Icons.money_off,
                                    size: 60,
                                    color: theme.colorScheme.secondary),
                                const SizedBox(height: 16),
                                Text(
                                  filtersActive
                                      ? 'No expenses match the current filters.'
                                      : 'No expenses recorded yet.',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                          color: theme.colorScheme.secondary),
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
                                      log.info(
                                          "[ExpenseListPage] Clearing filters.");
                                      context.read<ExpenseListBloc>().add(
                                          const FilterExpenses()); // Clear expense filters
                                      context.read<SummaryBloc>().add(
                                          const LoadSummary(
                                              forceReload: true,
                                              updateFilters:
                                                  true)); // Clear summary filters & reload
                                    },
                                  )
                                else
                                  Text(
                                    'Tap "+" to add your first expense!',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        log.info(
                            "[ExpenseListPage UI] Expense list has ${expenses.length} items. Building ListView.");
                        child = ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: expenses.length,
                          itemBuilder: (context, index) {
                            final expense = expenses[index];
                            return Dismissible(
                              key: Key('expense_${expense.id}'),
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
                                  _confirmDeletion(context, expense),
                              onDismissed: (direction) {
                                log.info(
                                    "[ExpenseListPage] Dismissed expense '${expense.title}'. Dispatching delete request.");
                                context
                                    .read<ExpenseListBloc>()
                                    .add(DeleteExpenseRequested(expense.id));
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(SnackBar(
                                    content: Text(
                                        'Expense "${expense.title}" deleted.'),
                                    backgroundColor: Colors.orange,
                                  ));
                              },
                              child: ExpenseCard(
                                expense: expense,
                                onTap: () {
                                  log.info(
                                      "[ExpenseListPage] Tapped expense '${expense.title}'. Navigating to edit.");
                                  context.pushNamed('edit_expense',
                                      pathParameters: {'id': expense.id},
                                      extra: expense);
                                },
                              ),
                            );
                          },
                        );
                      }
                    } else if (state is ExpenseListError) {
                      log.info(
                          "[ExpenseListPage UI] State is ExpenseListError: ${state.message}. Showing error UI.");
                      child = Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  color: theme.colorScheme.error, size: 50),
                              const SizedBox(height: 16),
                              Text('Error Loading Expenses',
                                  style: theme.textTheme.titleLarge),
                              const SizedBox(height: 8),
                              Text(state.message,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: theme.colorScheme.error)),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                onPressed: () => context
                                    .read<ExpenseListBloc>()
                                    .add(const LoadExpenses(forceReload: true)),
                              )
                            ],
                          ),
                        ),
                      );
                    } else {
                      // Fallback for Initial state
                      log.info(
                          "[ExpenseListPage UI] State is Initial or Unknown. Showing loading indicator.");
                      child = const Center(child: CircularProgressIndicator());
                    }

                    // Animate state changes
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: child,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_expenses', // Unique heroTag
          onPressed: () {
            log.info(
                "[ExpenseListPage] FAB tapped. Navigating to add expense.");
            context.pushNamed('add_expense');
          },
          tooltip: 'Add Expense',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // Filter Dialog Logic
  void _showFilterDialog(BuildContext context, ExpenseListState currentState) {
    log.info("[ExpenseListPage] Showing filter dialog.");
    DateTime? currentStart;
    DateTime? currentEnd;
    String? currentCategoryName;
    String? currentAccountId;
    if (currentState is ExpenseListLoaded) {
      currentStart = currentState.filterStartDate;
      currentEnd = currentState.filterEndDate;
      currentCategoryName = currentState.filterCategory;
      currentAccountId = currentState.filterAccountId;
    }

    // Get Expense Category Names
    final List<String> expenseCategoryNames = entity.PredefinedCategory.values
        .map<String>((e) => entity.Category.fromPredefined(e).name)
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return FilterDialogContent(
          isIncomeFilter: false, // It's for expenses
          expenseCategoryNames: expenseCategoryNames, // Pass expense categories
          incomeCategoryNames: const [], // Pass empty list for income
          initialStartDate: currentStart,
          initialEndDate: currentEnd,
          initialCategoryName: currentCategoryName,
          initialAccountId: currentAccountId,
          onApplyFilter: (startDate, endDate, categoryName, accountId) {
            log.info(
                "[ExpenseListPage] Filter dialog applied. Start=$startDate, End=$endDate, Cat=$categoryName, AccID=$accountId");
            context.read<ExpenseListBloc>().add(FilterExpenses(
                  startDate: startDate,
                  endDate: endDate,
                  category: categoryName,
                  accountId: accountId,
                ));
            context.read<SummaryBloc>().add(LoadSummary(
                  startDate: startDate,
                  endDate: endDate,
                  forceReload: true,
                  updateFilters: true, // Update summary filters
                ));
            Navigator.of(dialogContext).pop();
          },
          onClearFilter: () {
            log.info("[ExpenseListPage] Filter dialog cleared.");
            context.read<ExpenseListBloc>().add(const FilterExpenses());
            context
                .read<SummaryBloc>()
                .add(const LoadSummary(forceReload: true, updateFilters: true));
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }
}

// --- FilterDialogContent Widget (Shared between Expense and Income) ---
class FilterDialogContent extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String? initialCategoryName;
  final String? initialAccountId;
  final Function(DateTime?, DateTime?, String?, String?) onApplyFilter;
  final VoidCallback onClearFilter;
  final bool isIncomeFilter; // Flag to determine context
  final List<String> expenseCategoryNames;
  final List<String> incomeCategoryNames;

  const FilterDialogContent({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.initialCategoryName,
    this.initialAccountId,
    required this.onApplyFilter,
    required this.onClearFilter,
    required this.isIncomeFilter,
    required this.expenseCategoryNames,
    required this.incomeCategoryNames,
  });

  @override
  _FilterDialogContentState createState() => _FilterDialogContentState();
}

class _FilterDialogContentState extends State<FilterDialogContent> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedCategoryName;
  String? _selectedAccountId;

  List<String> get _categoryNames => widget.isIncomeFilter
      ? widget.incomeCategoryNames
      : widget.expenseCategoryNames;

  @override
  void initState() {
    super.initState();
    _selectedStartDate = widget.initialStartDate;
    _selectedEndDate = widget.initialEndDate;
    _selectedCategoryName = widget.initialCategoryName;
    _selectedAccountId = widget.initialAccountId;
    log.info(
        "[FilterDialog] InitState. isIncome: ${widget.isIncomeFilter}. Initial Filters: Start=$_selectedStartDate, End=$_selectedEndDate, Cat=$_selectedCategoryName, AccID=$_selectedAccountId");
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _selectedStartDate : _selectedEndDate) ??
          DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = picked;
          if (_selectedEndDate != null &&
              _selectedEndDate!.isBefore(_selectedStartDate!)) {
            _selectedEndDate = _selectedStartDate;
          }
        } else {
          _selectedEndDate = picked;
          if (_selectedStartDate != null &&
              _selectedStartDate!.isAfter(_selectedEndDate!)) {
            _selectedStartDate = _selectedEndDate;
          }
        }
        log.info(
            "[FilterDialog] Date selected. Start=$_selectedStartDate, End=$_selectedEndDate");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Filter ${widget.isIncomeFilter ? "Income" : "Expenses"}'),
      contentPadding:
          const EdgeInsets.fromLTRB(20, 20, 20, 0), // Adjust padding
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children
          children: <Widget>[
            // Start Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.date_range_outlined),
              title: Text(_selectedStartDate == null
                  ? 'Start Date (Optional)'
                  : 'Start: ${DateFormatter.formatDate(_selectedStartDate!)}'),
              trailing: _selectedStartDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () =>
                          setState(() => _selectedStartDate = null),
                      tooltip: "Clear Start Date")
                  : null,
              onTap: () => _selectDate(context, true),
            ),
            // End Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.date_range),
              title: Text(_selectedEndDate == null
                  ? 'End Date (Optional)'
                  : 'End: ${DateFormatter.formatDate(_selectedEndDate!)}'),
              trailing: _selectedEndDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _selectedEndDate = null),
                      tooltip: "Clear End Date")
                  : null,
              onTap: () => _selectDate(context, false),
            ),
            const SizedBox(height: 15),
            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategoryName,
              hint: const Text('All Categories'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                    value: null, child: Text('All Categories')),
                ..._categoryNames.map((String name) =>
                    DropdownMenuItem<String>(value: name, child: Text(name))),
              ],
              onChanged: (String? newValue) {
                setState(() => _selectedCategoryName = newValue);
                log.info(
                    "[FilterDialog] Category selected: $_selectedCategoryName");
              },
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              ),
            ),
            const SizedBox(height: 15),
            // Account Dropdown
            AccountSelectorDropdown(
              selectedAccountId: _selectedAccountId,
              labelText: 'Account (Optional)',
              hintText: 'All Accounts',
              validator: null, // Validation not needed for filtering
              onChanged: (String? newAccountId) {
                setState(() => _selectedAccountId = newAccountId);
                log.info(
                    "[FilterDialog] Account selected: $_selectedAccountId");
              },
            ),
            const SizedBox(height: 20), // Add padding at the bottom
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Clear Filters'),
          onPressed: widget.onClearFilter,
        ),
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('Apply'),
          onPressed: () => widget.onApplyFilter(_selectedStartDate,
              _selectedEndDate, _selectedCategoryName, _selectedAccountId),
        ),
      ],
    );
  }
}
