// lib/features/expenses/presentation/pages/expense_list_page.dart
// MODIFIED FILE

import 'package:expense_tracker/core/common/generic_list_page.dart';
import 'package:expense_tracker/core/common/base_list_state.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_categories.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_picker_dialog.dart';
import 'package:expense_tracker/features/categories/domain/usecases/save_user_categorization_history.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/expense_list/expense_list_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:go_router/go_router.dart';

// --- Filter Dialog Content ---
// (Assuming FilterDialogContent is correctly defined elsewhere or defined here)
class FilterDialogContent extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final String? initialCategoryName;
  final String? initialAccountId;
  final Function(DateTime?, DateTime?, String?, String?) onApplyFilter;
  final VoidCallback onClearFilter;
  final List<String> categoryNames;
  const FilterDialogContent({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    this.initialCategoryName,
    this.initialAccountId,
    required this.onApplyFilter,
    required this.onClearFilter,
    required this.categoryNames,
  });
  @override
  _FilterDialogContentState createState() => _FilterDialogContentState();
}

class _FilterDialogContentState extends State<FilterDialogContent> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedCategoryName;
  String? _selectedAccountId;
  List<String> get _categoryNames => widget.categoryNames;
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
      title: const Text('Filter Transactions'),
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
                  setState(() => _selectedCategoryName = newValue);
                },
                decoration: InputDecoration(
                    labelText: 'Category',
                    border: theme.inputDecorationTheme.border,
                    enabledBorder: theme.inputDecorationTheme.enabledBorder,
                    prefixIcon: const Icon(Icons.category_outlined),
                    contentPadding: theme.inputDecorationTheme.contentPadding)),
            const SizedBox(height: 15),
            AccountSelectorDropdown(
                selectedAccountId: _selectedAccountId,
                labelText: 'Account (Optional)',
                hintText: 'All Accounts',
                validator: null,
                onChanged: (String? newAccountId) {
                  setState(() => _selectedAccountId = newAccountId);
                }),
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

class ExpenseListPage extends StatelessWidget {
  const ExpenseListPage({super.key});

  // --- Navigation ---
  void _navigateToEdit(BuildContext context, Expense item) {
    log.info("[ExpenseListPage] Navigating to Edit item ID: ${item.id}");
    context.pushNamed(RouteNames.editExpense,
        pathParameters: {RouteNames.paramId: item.id}, extra: item);
  }

  // --- Category Interaction Handlers ---
  void _handleChangeCategoryRequest(BuildContext context, Expense item) async {
    log.info(
        "[ExpenseListPage] Change category requested for item ID: ${item.id}");
    // FIX: Pass the required CategoryTypeFilter
    final Category? selectedCategory =
        await showCategoryPicker(context, CategoryTypeFilter.expense);
    if (selectedCategory != null && context.mounted) {
      log.info(
          "[ExpenseListPage] Category '${selectedCategory.name}' selected from picker.");
      final matchData =
          TransactionMatchData(description: item.title, merchantId: null);
      context.read<ExpenseListBloc>().add(UserCategorizedExpense(
          expenseId: item.id,
          selectedCategory: selectedCategory,
          matchData: matchData));
    } else {
      log.info(
          "[ExpenseListPage] Category picker dismissed without selection.");
    }
  }

  void _handleUserCategorized(
      BuildContext context, Expense item, Category selectedCategory) {
    log.info(
        "[ExpenseListPage] User categorized item ID: ${item.id} as ${selectedCategory.name}");
    final matchData =
        TransactionMatchData(description: item.title, merchantId: null);
    context.read<ExpenseListBloc>().add(UserCategorizedExpense(
        expenseId: item.id,
        selectedCategory: selectedCategory,
        matchData: matchData));
  }

  // --- Build Methods ---

  // Builder function matching ItemWidgetBuilder<Expense>
  Widget _buildExpenseItem(
    BuildContext context,
    Expense item,
    bool isSelected,
    // Callbacks provided by GenericListPage that WE MUST IMPLEMENT:
    VoidCallback onEditTap, // For edit navigation
    VoidCallback onSelectTap, // For toggling selection
    Function(Category selectedCategory)
        onCategoryConfirmed, // For category choice
    VoidCallback onChangeCategoryRequest, // For initiating category change
  ) {
    final theme = Theme.of(context);
    Widget card = ExpenseCard(
      expense: item,
      // Connect ExpenseCard's callbacks to the received callbacks
      onCardTap: (_) => onEditTap(), // Call the VoidCallback
      onUserCategorized: (_, cat) => onCategoryConfirmed(cat),
      onChangeCategoryRequest: (_) =>
          onChangeCategoryRequest(), // Call the VoidCallback
    );

    final bloc = context.read<ExpenseListBloc>();
    if (bloc.state is ExpenseListLoaded &&
        (bloc.state as ExpenseListLoaded).isInBatchEditMode) {
      card = Stack(
        children: [
          card,
          Positioned.fill(
            child: Material(
              color: isSelected
                  ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                  : Colors.transparent,
              child: InkWell(
                onTap: onSelectTap,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IgnorePointer(
                        child: Checkbox(
                      value: isSelected,
                      onChanged: null,
                      visualDensity: VisualDensity.compact,
                    )),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return card;
  }

  Widget _buildExpenseTable(BuildContext context, List<Expense> items) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final accountState = context.watch<AccountListBloc>().state;
    final rows = items.map((exp) {
      String accountName = '...';
      if (accountState is AccountListLoaded) {
        try {
          accountName = accountState.items
              .firstWhere((acc) => acc.id == exp.accountId)
              .name;
        } catch (_) {
          accountName = 'N/A';
        }
      } else if (accountState is AccountListError) {
        accountName = 'Error';
      }
      final categoryName = exp.category?.name ?? Category.uncategorized.name;
      return DataRow(cells: [
        DataCell(Text(DateFormatter.formatDate(exp.date),
            style: theme.textTheme.bodySmall)),
        DataCell(Tooltip(
            message: exp.title,
            child: Text(exp.title, overflow: TextOverflow.ellipsis))),
        DataCell(Tooltip(
            message: categoryName,
            child: Text(categoryName, overflow: TextOverflow.ellipsis))),
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
    return Card(
      margin: EdgeInsets.zero,
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
    String illustrationKey = filtersApplied
        ? AssetKeys.illuEmptyFilter
        : AssetKeys.illuEmptyTransactions;
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
                    context.read<ExpenseListBloc>().add(const FilterExpenses());
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
      BuildContext context, BaseListState currentState) async {
    log.info("[ExpenseListPage] Showing filter dialog.");
    final getCategoriesUseCase = sl<GetCategoriesUseCase>();
    final categoriesResult = await getCategoriesUseCase(const NoParams());
    List<String> categoryNames = [];
    if (categoriesResult.isRight()) {
      categoryNames =
          categoriesResult.getOrElse(() => []).map((cat) => cat.name).toList();
      categoryNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    } else {
      log.warning(
          "[ExpenseListPage] Failed to load categories for filter dialog.");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Could not load categories for filtering.")));
      }
      return;
    }
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: sl<AccountListBloc>(),
          child: FilterDialogContent(
            categoryNames: categoryNames,
            initialStartDate: currentState.filterStartDate,
            initialEndDate: currentState.filterEndDate,
            initialCategoryName: currentState.filterCategory,
            initialAccountId: currentState.filterAccountId,
            onApplyFilter: (startDate, endDate, categoryName, accountId) {
              log.info(
                  "[ExpenseListPage] Filter dialog applied. Start=$startDate, End=$endDate, Cat=$categoryName, AccID=$accountId");
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
              Navigator.of(dialogContext).pop();
            },
            onClearFilter: () {
              log.info("[ExpenseListPage] Filter dialog cleared.");
              context.read<ExpenseListBloc>().add(const FilterExpenses());
              context.read<SummaryBloc>().add(
                  const LoadSummary(forceReload: true, updateFilters: true));
              Navigator.of(dialogContext).pop();
            },
          ),
        );
      },
    );
  }

  Future<bool> _confirmExpenseDeletion(
      BuildContext context, Expense item) async {
    return await AppDialogs.showConfirmation(
          context,
          title: "Confirm Deletion",
          content:
              'Are you sure you want to delete the expense "${item.title}"?',
          confirmText: "Delete",
          confirmColor: Theme.of(context).colorScheme.error,
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ExpenseListBloc>(
            create: (_) => sl<ExpenseListBloc>()..add(const LoadExpenses())),
        BlocProvider<AccountListBloc>.value(value: sl<AccountListBloc>()),
        BlocProvider<SummaryBloc>.value(value: sl<SummaryBloc>()),
      ],
      child: BlocBuilder<ExpenseListBloc, ExpenseListState>(
          builder: (context, state) {
        final bool isInBatchEditMode =
            state is ExpenseListLoaded && state.isInBatchEditMode;
        final int selectionCount = state is ExpenseListLoaded
            ? state.selectedTransactionIds.length
            : 0;
        final theme = Theme.of(context);

        return GenericListPage<Expense, ExpenseListBloc, ExpenseListEvent,
            ExpenseListState>(
          pageTitle: 'Expenses',
          addRouteName: RouteNames.addExpense,
          editRouteName: RouteNames.editExpense,
          itemHeroTagPrefix: 'expense',
          fabHeroTag: 'fab_expenses',
          showSummaryCard: true,
          itemBuilder: (itemBuilderContext, item, isSelected) =>
              _buildExpenseItem(
                  itemBuilderContext,
                  item,
                  isSelected,
                  // --- Pass correct handlers from this page's scope ---
                  () => _navigateToEdit(
                      context, item), // Use page's context for navigation
                  () => context
                      .read<ExpenseListBloc>()
                      .add(SelectExpense(item.id)),
                  (selectedCategory) =>
                      _handleUserCategorized(context, item, selectedCategory),
                  () => _handleChangeCategoryRequest(context, item)
                  // --- End handlers ---
                  ),
          tableBuilder: _buildExpenseTable,
          emptyStateBuilder: _buildEmptyState,
          filterDialogBuilder: (dialogContext, currentState) =>
              _showExpenseFilterDialog(dialogContext, currentState),
          deleteConfirmationBuilder: (dialogContext, item) =>
              _confirmExpenseDeletion(dialogContext, item),
          deleteEventBuilder: (id) => DeleteExpenseRequested(id),
          loadEventBuilder: ({bool forceReload = false}) =>
              LoadExpenses(forceReload: forceReload),
          appBarActions: [
            IconButton(
              icon: Icon(isInBatchEditMode
                  ? Icons.cancel_outlined
                  : Icons.edit_note_outlined),
              tooltip:
                  isInBatchEditMode ? "Cancel Selection" : "Select Multiple",
              onPressed: () => context
                  .read<ExpenseListBloc>()
                  .add(const ToggleBatchEditMode()),
            )
          ],
          floatingActionButton: isInBatchEditMode
              ? FloatingActionButton.extended(
                  heroTag: "fab_expenses_batch",
                  onPressed: selectionCount > 0
                      ? () async {
                          // FIX: Pass the required CategoryTypeFilter
                          final Category? selectedCategory =
                              await showCategoryPicker(
                                  context, CategoryTypeFilter.expense);
                          if (selectedCategory != null &&
                              selectedCategory.id !=
                                  Category.uncategorized.id &&
                              context.mounted) {
                            context
                                .read<ExpenseListBloc>()
                                .add(ApplyBatchCategory(selectedCategory.id));
                          } else if (selectedCategory?.id ==
                                  Category.uncategorized.id &&
                              context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Please select a specific category for batch editing.")));
                          }
                        }
                      : null,
                  label: Text(selectionCount > 0
                      ? 'Categorize ($selectionCount)'
                      : 'Categorize'),
                  icon: const Icon(Icons.category),
                  backgroundColor: selectionCount > 0
                      ? theme.colorScheme.primaryContainer
                      : theme.disabledColor.withOpacity(0.1),
                  foregroundColor: selectionCount > 0
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.disabledColor,
                )
              : null, // No FAB if not in batch mode
        );
      }),
    );
  }
}
