// lib/features/expenses/presentation/pages/expense_list_page.dart
import 'package:expense_tracker/core/common/generic_list_page.dart'; // Import Generic List Page
import 'package:expense_tracker/core/common/base_list_state.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart'; // Import AssetKeys
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart'; // For Filter Dialog
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart'; // For triggering summary reload
import 'package:expense_tracker/features/expenses/domain/entities/category.dart'
    as entityCategory; // Use prefix
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/expense_list/expense_list_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_card.dart';
import 'package:expense_tracker/features/income/domain/entities/income_category.dart'; // For filter dialog argument
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart'; // logger
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:expense_tracker/core/assets/app_assets.dart'; // Default assets
import 'package:expense_tracker/core/utils/app_dialogs.dart';

// --- Reusable Filter Dialog ---
// Keep the FilterDialogContent and _FilterDialogContentState classes here
// OR move them to a shared location like 'lib/core/widgets/filter_dialog.dart'
// (Code for FilterDialogContent and _FilterDialogContentState is omitted here for brevity,
// assume it's the same as in step 5 of the previous response)
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
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
        /* ... DatePicker config ... */
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
        }
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
            // Start Date ListTile
            ListTile(
                /* ... Start Date UI ... */
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
            // End Date ListTile
            ListTile(
                /* ... End Date UI ... */
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
            // Category Dropdown
            DropdownButtonFormField<String>(
              /* ... Category Dropdown UI ... */
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
                setState(() => _selectedCategoryName = newValue);
              },
              decoration: InputDecoration(
                  labelText: 'Category',
                  border: theme.inputDecorationTheme.border,
                  enabledBorder: theme.inputDecorationTheme.enabledBorder,
                  prefixIcon: const Icon(Icons.category_outlined),
                  contentPadding: theme.inputDecorationTheme.contentPadding),
            ),
            const SizedBox(height: 15),
            // Account Dropdown (needs AccountListBloc provided)
            AccountSelectorDropdown(
              /* ... Account Dropdown UI ... */
              selectedAccountId: _selectedAccountId,
              labelText: 'Account (Optional)',
              hintText: 'All Accounts',
              validator: null, // Optional filter
              onChanged: (String? newAccountId) {
                setState(() => _selectedAccountId = newAccountId);
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
// --- End Filter Dialog ---

class ExpenseListPage extends StatelessWidget {
  const ExpenseListPage({super.key});

  // --- Specific Builders for Expenses ---

  Widget _buildExpenseItem(
      BuildContext context, Expense item, VoidCallback onTapEdit) {
    // ExpenseCard needs AccountListBloc provided higher up (GenericListPage does this)
    return ExpenseCard(expense: item, onTap: onTapEdit);
  }

  Widget _buildExpenseTable(BuildContext context, List<Expense> items) {
    // This is the logic from the old _buildQuantumExpenseTable
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    // AccountListBloc is provided by GenericListPage
    final accountState = context.watch<AccountListBloc>().state;

    final rows = items.map((exp) {
      String accountName = '...'; // Placeholder
      if (accountState is AccountListLoaded) {
        try {
          accountName = accountState.items // Use items from base state
              .firstWhere((acc) => acc.id == exp.accountId)
              .name;
        } catch (_) {
          accountName = 'N/A';
        }
      } else if (accountState is AccountListError) {
        accountName = 'Error';
      }

      return DataRow(cells: [
        DataCell(Text(DateFormatter.formatDate(exp.date),
            style: theme.textTheme.bodySmall)),
        DataCell(Tooltip(
            message: exp.title,
            child: Text(exp.title, overflow: TextOverflow.ellipsis))),
        DataCell(Tooltip(
            message: exp.category.displayName,
            child: Text(exp.category.displayName,
                overflow: TextOverflow.ellipsis))),
        DataCell(Tooltip(
            message: accountName,
            child: Text(accountName, overflow: TextOverflow.ellipsis))),
        DataCell(Text(
          CurrencyFormatter.format(exp.amount, currencySymbol),
          style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error, fontWeight: FontWeight.w500),
          textAlign: TextAlign.end,
        )),
      ]);
    }).toList();

    // Consistent Card wrapping for the table
    return Card(
      margin: EdgeInsets.zero, // Use ListView padding
      shape: theme.cardTheme.shape,
      elevation: theme.cardTheme.elevation,
      color: theme.cardTheme.color,
      clipBehavior: theme.cardTheme.clipBehavior ?? Clip.none,
      child: SingleChildScrollView(
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
          dividerThickness: theme.dataTableTheme.dividerThickness,
          dataRowColor: theme.dataTableTheme.dataRowColor,
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

  Widget _buildEmptyState(BuildContext context, bool filtersApplied) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;
    String emptyText =
        filtersApplied ? 'No expenses match filters.' : 'No expenses yet.';
    // Use AssetKeys for consistency
    String illustrationKey = filtersApplied
        ? AssetKeys.illuEmptyFilter
        : AssetKeys.illuEmptyTransactions;
    // Provide default paths from AppAssets
    String defaultIllustration = filtersApplied
        ? AppAssets.elIlluEmptyCalendar
        : AppAssets.elIlluEmptyAddTransaction;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
                modeTheme?.assets.getIllustration(illustrationKey,
                        defaultPath: defaultIllustration) ??
                    defaultIllustration,
                height: 100,
                colorFilter: ColorFilter.mode(
                    theme.colorScheme.secondary, BlendMode.srcIn)),
            const SizedBox(height: 16),
            Text(emptyText,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: theme.colorScheme.secondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            if (filtersApplied)
              ElevatedButton.icon(
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear Filters'),
                  style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                  onPressed: () {
                    log.info(
                        "[ExpenseListPage] Clearing filters via empty state.");
                    // Dispatch FilterExpenses with no arguments to clear
                    context.read<ExpenseListBloc>().add(const FilterExpenses());
                    // Also reload summary with cleared filters
                    context.read<SummaryBloc>().add(const LoadSummary(
                        forceReload: true, updateFilters: true));
                  })
            else
              Text('Tap "+" to add your first expense!',
                  style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  void _showExpenseFilterDialog(
      BuildContext context, BaseListState currentState) {
    log.info("[ExpenseListPage] Showing filter dialog.");
    // Get category names from the *entity* definition
    final List<String> expenseCategoryNames = entityCategory
        .PredefinedCategory.values
        .map<String>((e) => entityCategory.Category.fromPredefined(e).name)
        .toList();
    // Get income categories just to pass them (FilterDialog needs both lists)
    final List<String> incomeCategoryNames = PredefinedIncomeCategory.values
        .map<String>((e) => IncomeCategory.fromPredefined(e).name)
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Provide AccountListBloc again specifically for the dialog's dropdown
        return BlocProvider.value(
          value: sl<AccountListBloc>(), // Ensure AccountListBloc is available
          child: FilterDialogContent(
            isIncomeFilter: false, // Specify this is for expenses
            expenseCategoryNames: expenseCategoryNames,
            incomeCategoryNames: incomeCategoryNames, // Pass income names
            initialStartDate: currentState.filterStartDate,
            initialEndDate: currentState.filterEndDate,
            initialCategoryName: currentState.filterCategory,
            initialAccountId: currentState.filterAccountId,
            onApplyFilter: (startDate, endDate, categoryName, accountId) {
              log.info(
                  "[ExpenseListPage] Filter dialog applied. Start=$startDate, End=$endDate, Cat=$categoryName, AccID=$accountId");
              // Dispatch specific FilterExpenses event
              context.read<ExpenseListBloc>().add(FilterExpenses(
                  startDate: startDate,
                  endDate: endDate,
                  category: categoryName,
                  accountId: accountId));
              // Trigger summary reload with new filters
              context.read<SummaryBloc>().add(LoadSummary(
                  startDate: startDate,
                  endDate: endDate,
                  forceReload: true,
                  updateFilters: true));
              Navigator.of(dialogContext).pop(); // Close dialog
            },
            onClearFilter: () {
              log.info("[ExpenseListPage] Filter dialog cleared.");
              // Dispatch specific FilterExpenses event with no args
              context.read<ExpenseListBloc>().add(const FilterExpenses());
              // Trigger summary reload with cleared filters
              context.read<SummaryBloc>().add(
                  const LoadSummary(forceReload: true, updateFilters: true));
              Navigator.of(dialogContext).pop(); // Close dialog
            },
          ),
        );
      },
    );
  }

  Future<bool> _confirmExpenseDeletion(
      BuildContext context, Expense item) async {
    // Reusing the generic confirmation dialog logic
    return await AppDialogs.showConfirmation(
          context,
          title: "Confirm Deletion",
          content:
              'Are you sure you want to delete the expense "${item.title}"?',
          confirmText: "Delete",
          confirmColor: Theme.of(context).colorScheme.error, // Use theme color
        ) ??
        false; // Return false if dismissed
  }

  @override
  Widget build(BuildContext context) {
    // Instantiate GenericListPage with Expense-specific types and builders
    return GenericListPage<Expense, ExpenseListBloc, ExpenseListEvent,
        ExpenseListState>(
      pageTitle: 'Expenses',
      addRouteName: RouteNames.addExpense,
      editRouteName: RouteNames.editExpense,
      itemHeroTagPrefix: 'expense',
      fabHeroTag: 'fab_expenses',
      showSummaryCard: true, // Expenses page shows the summary card
      // Provide the specific builders and event creators
      itemBuilder: _buildExpenseItem,
      tableBuilder: _buildExpenseTable,
      emptyStateBuilder: _buildEmptyState,
      filterDialogBuilder: _showExpenseFilterDialog,
      deleteConfirmationBuilder:
          _confirmExpenseDeletion, // Pass the updated confirmation method
      deleteEventBuilder: (id) => DeleteExpenseRequested(id),
      loadEventBuilder: ({bool forceReload = false}) =>
          LoadExpenses(forceReload: forceReload),
    );
  }
}
