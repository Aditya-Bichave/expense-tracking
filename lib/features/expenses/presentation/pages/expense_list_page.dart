import 'package:expense_tracker/core/theme/app_mode_theme.dart'; // Import Theme Extension & helper
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import Settings Bloc & UIMode
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/expense_list/expense_list_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_card.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart'; // For SummaryCard trigger
import 'package:expense_tracker/features/analytics/presentation/widgets/summary_card.dart'; // Summary Card Widget
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/expenses/domain/entities/category.dart'
    as entity; // Use prefix for Category entity
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart'; // Import AccountSelectorDropdown
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart'; // Import AccountListBloc for filter
import 'package:flutter_svg/flutter_svg.dart'; // Import SVG picture

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  _ExpenseListPageState createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  // --- Lifecycle & Refresh ---
  @override
  void initState() {
    super.initState();
    // Initial load is handled by Bloc creation in main.dart or MultiBlocProvider
    // Ensure dependent Blocs are loaded if necessary (e.g., AccountListBloc)
    final accountBloc = sl<AccountListBloc>();
    if (accountBloc.state is AccountListInitial) {
      log.info(
          "[ExpenseListPage] AccountListBloc is initial, dispatching LoadAccounts.");
      accountBloc.add(const LoadAccounts());
    }
  }

  Future<void> _refreshExpenses(BuildContext context) async {
    log.info("[ExpenseListPage] Pull-to-refresh triggered.");
    try {
      // Use context.read safely within async gap IF BuildContext is still valid
      if (!mounted) return;
      context
          .read<ExpenseListBloc>()
          .add(const LoadExpenses(forceReload: true));

      // Trigger summary reload based on current expense filters
      final expenseState = context.read<ExpenseListBloc>().state;
      if (mounted) {
        // Check mount again before reading SummaryBloc
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
      }

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

  // --- Navigation & Dialogs ---

  void _navigateToAdd(BuildContext context) {
    log.info("[ExpenseListPage] FAB tapped. Navigating to add expense.");
    context.pushNamed('add_expense');
  }

  void _navigateToEdit(BuildContext context, Expense expense) {
    log.info(
        "[ExpenseListPage] Tapped expense '${expense.title}'. Navigating to edit.");
    context.pushNamed('edit_expense',
        pathParameters: {'id': expense.id}, extra: expense);
  }

  Future<bool> _confirmDeletion(BuildContext context, Expense expense) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: const Text("Confirm Deletion"),
            content: Text(
                'Are you sure you want to delete the expense "${expense.title}"?',
                style: Theme.of(ctx).textTheme.bodyMedium),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text("Cancel")),
              TextButton(
                  style: TextButton.styleFrom(
                      foregroundColor: Theme.of(ctx).colorScheme.error),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text("Delete")),
            ],
          ),
        ) ??
        false;
  }

  // --- UI Builders ---

  // Builder for Quantum Data Table View
  Widget _buildQuantumExpenseTable(
      BuildContext context, List<Expense> expenses) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    // Account names are needed, watch AccountListBloc
    final accountState = context.watch<AccountListBloc>().state;

    final rows = expenses.map((exp) {
      String accountName = '...'; // Placeholder while loading/error
      if (accountState is AccountListLoaded) {
        try {
          accountName = accountState.accounts
              .firstWhere((acc) => acc.id == exp.accountId)
              .name;
        } catch (_) {
          accountName = 'N/A';
        }
      } else if (accountState is AccountListError) {
        accountName = 'Err';
      }

      return DataRow(cells: [
        DataCell(Text(DateFormatter.formatDate(exp.date),
            style: theme.textTheme.bodySmall)), // Date
        DataCell(Tooltip(
            message: exp.title,
            child: Text(exp.title, overflow: TextOverflow.ellipsis))), // Title
        DataCell(Tooltip(
            message: exp.category.displayName,
            child: Text(exp.category.displayName,
                overflow: TextOverflow.ellipsis))), // Category
        DataCell(Tooltip(
            message: accountName,
            child:
                Text(accountName, overflow: TextOverflow.ellipsis))), // Account
        DataCell(Text(
          CurrencyFormatter.format(exp.amount, currencySymbol),
          style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w500), // Use Quantum error color
          textAlign: TextAlign.end,
        )), // Amount
      ]);
    }).toList();

    // Wrap in a Card for consistent Quantum look
    return Card(
      margin: EdgeInsets.zero, // No margin, let parent handle padding
      shape: theme.cardTheme.shape, // Use theme shape
      elevation: theme.cardTheme.elevation, // Use theme elevation
      child: SingleChildScrollView(
        // Make table horizontally scrollable
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: theme.dataTableTheme.columnSpacing ?? 12,
          headingRowHeight: theme.dataTableTheme.headingRowHeight ?? 36,
          dataRowMinHeight: theme.dataTableTheme.dataRowMinHeight ?? 36,
          dataRowMaxHeight: theme.dataTableTheme.dataRowMaxHeight ?? 40,
          headingTextStyle: theme.dataTableTheme.headingTextStyle ??
              theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
          dataTextStyle:
              theme.dataTableTheme.dataTextStyle ?? theme.textTheme.bodySmall,
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Account')),
            DataColumn(label: Text('Amount'), numeric: true),
          ],
          rows: rows,
        ),
      ),
    );
  }

  // Builder for Standard (Elemental/Aether) List View
  Widget _buildStandardExpenseList(
      BuildContext context, List<Expense> expenses) {
    // Need AccountListBloc access for ExpenseCard to display names correctly
    return BlocBuilder<AccountListBloc, AccountListState>(
      builder: (context, accountState) {
        if (accountState is AccountListLoading && expenses.isNotEmpty) {
          // Optionally show a loading indicator overlay or just let cards show '...'
        } else if (accountState is AccountListError) {
          log.warning(
              "[ExpenseListPage] Account list error state: ${accountState.message}. Cards may show 'Deleted Account'.");
        }
        return ListView.builder(
          // Important: Let the parent RefreshIndicator handle scroll physics
          // physics: const AlwaysScrollableScrollPhysics(), // REMOVE if inside RefreshIndicator column
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return Dismissible(
              key: Key('expense_${expense.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Theme.of(context).colorScheme.errorContainer,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text("Delete",
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Icon(Icons.delete_sweep_outlined,
                        color: Theme.of(context).colorScheme.onErrorContainer),
                  ],
                ),
              ),
              confirmDismiss: (direction) => _confirmDeletion(context, expense),
              onDismissed: (direction) {
                log.info(
                    "[ExpenseListPage] Dismissed expense '${expense.title}'. Dispatching delete request.");
                context
                    .read<ExpenseListBloc>()
                    .add(DeleteExpenseRequested(expense.id));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Text('Expense "${expense.title}" deleted.'),
                    backgroundColor: Colors.orange,
                  ));
              },
              // ExpenseCard internally uses AccountListBloc state via context.watch
              child: ExpenseCard(
                expense: expense,
                onTap: () => _navigateToEdit(context, expense),
              ),
            );
          },
        );
      },
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    log.info("[ExpenseListPage] Build method called.");
    final theme = Theme.of(context);
    // Get theme extension and UI mode state
    final modeTheme = context.modeTheme;
    final uiMode = context.watch<SettingsBloc>().state.uiMode;
    final bool useTables = modeTheme?.preferDataTableForLists ?? false;

    // Provide AccountListBloc for both standard list (for cards) and filter dialog
    return BlocProvider.value(
      value: sl<AccountListBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expenses'),
          actions: [
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
            // Use Column to stack SummaryCard and the list/table
            children: [
              // Summary Card reacts to ExpenseList changes via its own listener to SummaryBloc
              const SummaryCard(),
              Divider(
                  height: theme.dividerTheme.thickness ?? 1,
                  thickness: theme.dividerTheme.thickness ?? 1,
                  color: theme.dividerTheme.color),
              Expanded(
                // List/Table takes remaining space
                child: BlocConsumer<ExpenseListBloc, ExpenseListState>(
                  listener: (context, state) {
                    // log.info("[ExpenseListPage] BlocListener received state: ${state.runtimeType}"); // Less verbose
                    if (state is ExpenseListError) {
                      log.warning(
                          "[ExpenseListPage] Error state detected: ${state.message}");
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                            content: Text(state.message),
                            backgroundColor: theme.colorScheme.error));
                    }
                  },
                  builder: (context, state) {
                    // log.info("[ExpenseListPage] BlocBuilder building for state: ${state.runtimeType}"); // Less verbose
                    Widget listContent;

                    if (state is ExpenseListLoading && !state.isReloading) {
                      listContent =
                          const Center(child: CircularProgressIndicator());
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
                        // Empty State Logic
                        String emptyText = filtersActive
                            ? 'No expenses match filters.'
                            : 'No expenses yet.';
                        String buttonText =
                            filtersActive ? 'Clear Filters' : '';
                        VoidCallback? buttonAction = filtersActive
                            ? () {
                                log.info("[ExpenseListPage] Clearing filters.");
                                context
                                    .read<ExpenseListBloc>()
                                    .add(const FilterExpenses());
                                context.read<SummaryBloc>().add(
                                    const LoadSummary(
                                        forceReload: true,
                                        updateFilters: true));
                              }
                            : null;
                        String illustrationKey = filtersActive
                            ? 'empty_filter'
                            : 'empty_transactions';
                        String defaultIllustration = filtersActive
                            ? 'assets/elemental/illustrations/empty_calendar.svg'
                            : 'assets/elemental/illustrations/empty_add_transaction.svg';

                        listContent = Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Use SVG from theme extension
                                SvgPicture.asset(
                                    modeTheme?.assets.getIllustration(
                                            illustrationKey,
                                            defaultPath: defaultIllustration) ??
                                        defaultIllustration,
                                    height: 100,
                                    colorFilter: ColorFilter.mode(
                                        theme.colorScheme.secondary,
                                        BlendMode.srcIn)),
                                const SizedBox(height: 16),
                                Text(emptyText,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                            color: theme.colorScheme.secondary),
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 8),
                                if (filtersActive)
                                  ElevatedButton.icon(
                                      icon:
                                          const Icon(Icons.clear_all, size: 18),
                                      label: Text(buttonText),
                                      style: ElevatedButton.styleFrom(
                                          visualDensity: VisualDensity.compact),
                                      onPressed: buttonAction)
                                else
                                  Text('Tap "+" to add your first expense!',
                                      style: theme.textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        );
                      } else {
                        // Choose list or table based on UI mode flag
                        listContent = (uiMode == UIMode.quantum && useTables)
                            ? _buildQuantumExpenseTable(context, expenses)
                            : _buildStandardExpenseList(context, expenses);
                      }
                    } else if (state is ExpenseListError) {
                      // Error State UI
                      listContent = Center(
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
                      // Initial State
                      listContent =
                          const Center(child: CircularProgressIndicator());
                    }
                    // Animate between list/table/empty/error states
                    return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: listContent);
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_expenses',
          onPressed: () => _navigateToAdd(context),
          tooltip: 'Add Expense',
          child: modeTheme != null
              // Use SVG icon from theme extension, providing a fallback path
              ? SvgPicture.asset(
                  modeTheme.assets.getCommonIcon(AppModeTheme.iconAdd,
                      defaultPath:
                          'assets/elemental/icons/common/ic_add.svg'), // Ensure default exists
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                      theme.floatingActionButtonTheme.foregroundColor ??
                          Colors.white,
                      BlendMode.srcIn))
              : const Icon(Icons.add), // Fallback if extension is null
        ),
      ),
    );
  }

  // --- Filter Dialog ---
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
    // Get category names from the *entity* definition
    final List<String> expenseCategoryNames = entity.PredefinedCategory.values
        .map<String>((e) => entity.Category.fromPredefined(e).name)
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Use the existing FilterDialogContent (needs AccountListBloc provided)
        // It's already provided by the main Scaffold's MultiBlocProvider in this setup.
        return FilterDialogContent(
          isIncomeFilter: false,
          expenseCategoryNames: expenseCategoryNames,
          incomeCategoryNames: const [],
          initialStartDate: currentStart,
          initialEndDate: currentEnd,
          initialCategoryName: currentCategoryName,
          initialAccountId: currentAccountId,
          onApplyFilter: (startDate, endDate, categoryName, accountId) {
            log.info(
                "[ExpenseListPage] Filter dialog applied. Start=$startDate, End=$endDate, Cat=$categoryName, AccID=$accountId");
            // Read Blocs using the *original* context (from the page build method), not dialogContext
            context.read<ExpenseListBloc>().add(FilterExpenses(
                startDate: startDate,
                endDate: endDate,
                category: categoryName,
                accountId: accountId));
            context.read<SummaryBloc>().add(LoadSummary(
                startDate: startDate,
                endDate: endDate,
                forceReload: true,
                updateFilters: true));
            Navigator.of(dialogContext).pop(); // Close dialog
          },
          onClearFilter: () {
            log.info("[ExpenseListPage] Filter dialog cleared.");
            // Read Blocs using the *original* context
            context.read<ExpenseListBloc>().add(const FilterExpenses());
            context
                .read<SummaryBloc>()
                .add(const LoadSummary(forceReload: true, updateFilters: true));
            Navigator.of(dialogContext).pop(); // Close dialog
          },
        );
      },
    );
  }
} // End of _ExpenseListPageState

// --- FilterDialogContent Widget (Keep as defined previously) ---
class FilterDialogContent extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String? initialCategoryName;
  final String? initialAccountId;
  final Function(DateTime?, DateTime?, String?, String?) onApplyFilter;
  final VoidCallback onClearFilter;
  final bool isIncomeFilter;
  final List<String> expenseCategoryNames;
  final List<String> incomeCategoryNames;

  const FilterDialogContent(
      {super.key,
      this.initialStartDate,
      this.initialEndDate,
      this.initialCategoryName,
      this.initialAccountId,
      required this.onApplyFilter,
      required this.onClearFilter,
      required this.isIncomeFilter,
      required this.expenseCategoryNames,
      required this.incomeCategoryNames});
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
    // log.info("[FilterDialog] InitState. isIncome: ${widget.isIncomeFilter}. Initial Filters: Start=$_selectedStartDate, End=$_selectedEndDate, Cat=$_selectedCategoryName, AccID=$_selectedAccountId");
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: (isStartDate ? _selectedStartDate : _selectedEndDate) ??
            DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101));
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
        } /*log.info("[FilterDialog] Date selected. Start=$_selectedStartDate, End=$_selectedEndDate");*/
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Filter ${widget.isIncomeFilter ? "Income" : "Expenses"}'),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
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
                onTap: () => _selectDate(context, true)),
            ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.date_range),
                title: Text(_selectedEndDate == null
                    ? 'End Date (Optional)'
                    : 'End: ${DateFormatter.formatDate(_selectedEndDate!)}'),
                trailing: _selectedEndDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () =>
                            setState(() => _selectedEndDate = null),
                        tooltip: "Clear End Date")
                    : null,
                onTap: () => _selectDate(context, false)),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _selectedCategoryName,
              hint: const Text('All Categories'),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                    value: null, child: Text('All Categories')),
                ..._categoryNames.map((String name) =>
                    DropdownMenuItem<String>(value: name, child: Text(name)))
              ],
              onChanged: (String? newValue) {
                setState(() => _selectedCategoryName =
                    newValue); /*log.info("[FilterDialog] Category selected: $_selectedCategoryName");*/
              },
              decoration: InputDecoration(
                  labelText: 'Category',
                  border: theme.inputDecorationTheme.border,
                  enabledBorder: theme.inputDecorationTheme.enabledBorder,
                  prefixIcon: const Icon(Icons.category_outlined),
                  contentPadding: theme.inputDecorationTheme.contentPadding),
            ),
            const SizedBox(height: 15),
            // AccountSelectorDropdown requires AccountListBloc to be provided above it
            AccountSelectorDropdown(
              selectedAccountId: _selectedAccountId,
              labelText: 'Account (Optional)',
              hintText: 'All Accounts',
              validator: null,
              onChanged: (String? newAccountId) {
                setState(() => _selectedAccountId =
                    newAccountId); /*log.info("[FilterDialog] Account selected: $_selectedAccountId");*/
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
            child: const Text('Clear Filters'),
            onPressed: widget.onClearFilter),
        TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop()),
        ElevatedButton(
            child: const Text('Apply'),
            onPressed: () => widget.onApplyFilter(_selectedStartDate,
                _selectedEndDate, _selectedCategoryName, _selectedAccountId)),
      ],
    );
  }
}
