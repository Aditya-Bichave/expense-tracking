// lib/features/reports/presentation/widgets/report_filter_controls.dart
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart'; // Added
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class ReportFilterControls extends StatelessWidget {
  const ReportFilterControls({super.key});

  static Future<void> showFilterSheet(BuildContext context) async {
    final filterBloc = BlocProvider.of<ReportFilterBloc>(context);
    if (filterBloc.state.optionsStatus != FilterOptionsStatus.loaded) {
      filterBloc.add(const LoadFilterOptions(forceReload: true));
      // Consider showing a loading indicator briefly or disabling button until loaded
      await filterBloc.stream.firstWhere((state) =>
          state.optionsStatus == FilterOptionsStatus.loaded ||
          state.optionsStatus == FilterOptionsStatus.error);
      if (!context.mounted ||
          filterBloc.state.optionsStatus == FilterOptionsStatus.error)
        return; // Don't show sheet if loading failed
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        // Provide the SAME Filter Bloc instance down to the sheet content
        return BlocProvider.value(
            value: filterBloc, child: const ReportFilterSheetContent());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class ReportFilterSheetContent extends StatefulWidget {
  const ReportFilterSheetContent({super.key});
  @override
  State<ReportFilterSheetContent> createState() =>
      _ReportFilterSheetContentState();
}

class _ReportFilterSheetContentState extends State<ReportFilterSheetContent> {
  late DateTime _tempStartDate;
  late DateTime _tempEndDate;
  late List<String> _tempSelectedCategoryIds;
  late List<String> _tempSelectedAccountIds;
  late List<String> _tempSelectedBudgetIds;
  late List<String> _tempSelectedGoalIds;
  late TransactionType?
      _tempSelectedTransactionType; // Corrected state variable

  @override
  void initState() {
    super.initState();
    // Initialize local state from BLoC state WHEN the sheet is built
    final currentState = context.read<ReportFilterBloc>().state;
    _tempStartDate = currentState.startDate;
    _tempEndDate = currentState.endDate;
    _tempSelectedCategoryIds = List.from(currentState.selectedCategoryIds);
    _tempSelectedAccountIds = List.from(currentState.selectedAccountIds);
    _tempSelectedBudgetIds = List.from(currentState.selectedBudgetIds);
    _tempSelectedGoalIds = List.from(currentState.selectedGoalIds);
    _tempSelectedTransactionType = currentState.selectedTransactionType;
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialRange =
        DateTimeRange(start: _tempStartDate, end: _tempEndDate);
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        _tempStartDate = picked.start;
        _tempEndDate = picked.end;
      });
    }
  }

  void _applyFilters() {
    context.read<ReportFilterBloc>().add(UpdateReportFilters(
          startDate: _tempStartDate, endDate: _tempEndDate,
          categoryIds: _tempSelectedCategoryIds,
          accountIds: _tempSelectedAccountIds,
          budgetIds: _tempSelectedBudgetIds, goalIds: _tempSelectedGoalIds,
          transactionType: _tempSelectedTransactionType, // Pass the value
        ));
    Navigator.pop(context);
  }

  void _clearFilters() {
    context.read<ReportFilterBloc>().add(const ClearReportFilters());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<ReportFilterBloc, ReportFilterState>(
      builder: (context, state) {
        // Prepare items based on LATEST state
        final categoryItems = state.availableCategories
            .where((c) => c.id != Category.uncategorized.id)
            .map((c) => MultiSelectItem<String>(c.id, c.name))
            .toList();
        final accountItems = state.availableAccounts
            .map((a) => MultiSelectItem<String>(a.id, a.name))
            .toList();
        final budgetItems = state.availableBudgets
            .map((b) => MultiSelectItem<String>(b.id, b.name))
            .toList();
        final goalItems = state.availableGoals
            .map((g) => MultiSelectItem<String>(g.id, g.name))
            .toList();

        // Ensure local temp state reflects latest BLoC state if options just loaded
        if (state.optionsStatus == FilterOptionsStatus.loaded &&
            _tempSelectedCategoryIds.isEmpty &&
            _tempSelectedAccountIds.isEmpty &&
            _tempSelectedBudgetIds.isEmpty &&
            _tempSelectedGoalIds.isEmpty) {
          _tempStartDate = state.startDate;
          _tempEndDate = state.endDate;
          _tempSelectedCategoryIds = List.from(state.selectedCategoryIds);
          _tempSelectedAccountIds = List.from(state.selectedAccountIds);
          _tempSelectedBudgetIds = List.from(state.selectedBudgetIds);
          _tempSelectedGoalIds = List.from(state.selectedGoalIds);
          _tempSelectedTransactionType = state.selectedTransactionType;
        }

        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16,
              left: 16,
              right: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Filter Report Data',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),

                // Date Range
                ListTile(
                  leading: const Icon(Icons.date_range_outlined),
                  title: const Text('Date Range'),
                  subtitle: Text(
                      '${DateFormatter.formatDate(_tempStartDate)} - ${DateFormatter.formatDate(_tempEndDate)}'),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: () => _selectDateRange(context),
                  shape: RoundedRectangleBorder(
                      side: BorderSide(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(8)),
                ),
                const SizedBox(height: 16),

                // Transaction Type Filter
                DropdownButtonFormField<TransactionType?>(
                  value: _tempSelectedTransactionType, // Use local temp state
                  decoration: InputDecoration(
                    labelText: 'Transaction Type',
                    prefixIcon: Icon(
                        _tempSelectedTransactionType == TransactionType.expense
                            ? Icons.arrow_downward
                            : _tempSelectedTransactionType ==
                                    TransactionType.income
                                ? Icons.arrow_upward
                                : Icons.swap_vert,
                        size: 20),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                  hint: const Text('All Types'), isExpanded: true,
                  items: const [
                    DropdownMenuItem<TransactionType?>(
                        value: null, child: Text('All Types')),
                    DropdownMenuItem<TransactionType?>(
                        value: TransactionType.expense,
                        child: Text('Expenses Only')),
                    DropdownMenuItem<TransactionType?>(
                        value: TransactionType.income,
                        child: Text('Income Only'))
                  ],
                  onChanged: (TransactionType? newValue) => setState(() =>
                      _tempSelectedTransactionType =
                          newValue), // Update local temp state
                ),
                const SizedBox(height: 16),

                // Account Multi-Select
                if (state.optionsStatus == FilterOptionsStatus.loaded)
                  MultiSelectDialogField<String>(
                    items: accountItems,
                    initialValue: _tempSelectedAccountIds,
                    title: const Text("Select Accounts"),
                    buttonText: Text(
                        _tempSelectedAccountIds.isEmpty
                            ? "All Accounts"
                            : "${_tempSelectedAccountIds.length} Accounts Selected",
                        overflow: TextOverflow.ellipsis),
                    buttonIcon:
                        const Icon(Icons.account_balance_wallet_outlined),
                    decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(8)),
                    chipDisplay: MultiSelectChipDisplay.none(),
                    onConfirm: (values) =>
                        setState(() => _tempSelectedAccountIds = values),
                    searchable: true,
                    searchHint: "Search Accounts",
                  )
                else if (state.optionsStatus == FilterOptionsStatus.loading)
                  const LinearProgressIndicator()
                else if (state.optionsStatus == FilterOptionsStatus.error)
                  Text("Error loading accounts",
                      style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: 16),

                // Category Multi-Select
                if (state.optionsStatus == FilterOptionsStatus.loaded)
                  MultiSelectDialogField<String>(
                    items: categoryItems,
                    initialValue: _tempSelectedCategoryIds,
                    title: const Text("Select Categories"),
                    buttonText: Text(
                        _tempSelectedCategoryIds.isEmpty
                            ? "All Categories"
                            : "${_tempSelectedCategoryIds.length} Categories Selected",
                        overflow: TextOverflow.ellipsis),
                    buttonIcon: const Icon(Icons.category_outlined),
                    decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(8)),
                    chipDisplay: MultiSelectChipDisplay.none(),
                    onConfirm: (values) =>
                        setState(() => _tempSelectedCategoryIds = values),
                    searchable: true,
                    searchHint: "Search Categories",
                  )
                else if (state.optionsStatus == FilterOptionsStatus.loading)
                  const SizedBox.shrink()
                else if (state.optionsStatus == FilterOptionsStatus.error)
                  Text("Error loading categories",
                      style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: 16),

                // Budget Multi-Select
                if (state.optionsStatus == FilterOptionsStatus.loaded)
                  MultiSelectDialogField<String>(
                    items: budgetItems,
                    initialValue: _tempSelectedBudgetIds,
                    title: const Text("Select Budgets (For Budget Report)"),
                    buttonText: Text(
                        _tempSelectedBudgetIds.isEmpty
                            ? "All Budgets"
                            : "${_tempSelectedBudgetIds.length} Budgets Selected",
                        overflow: TextOverflow.ellipsis),
                    buttonIcon: const Icon(Icons.pie_chart_outline),
                    decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(8)),
                    chipDisplay: MultiSelectChipDisplay.none(),
                    onConfirm: (values) =>
                        setState(() => _tempSelectedBudgetIds = values),
                    searchable: true,
                    searchHint: "Search Budgets",
                  )
                else if (state.optionsStatus == FilterOptionsStatus.loading)
                  const SizedBox.shrink()
                else if (state.optionsStatus == FilterOptionsStatus.error)
                  Text("Error loading budgets",
                      style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: 16),

                // Goal Multi-Select
                if (state.optionsStatus == FilterOptionsStatus.loaded)
                  MultiSelectDialogField<String>(
                    items: goalItems,
                    initialValue: _tempSelectedGoalIds,
                    title: const Text("Select Goals (For Goal Report)"),
                    buttonText: Text(
                        _tempSelectedGoalIds.isEmpty
                            ? "All Goals"
                            : "${_tempSelectedGoalIds.length} Goals Selected",
                        overflow: TextOverflow.ellipsis),
                    buttonIcon: const Icon(Icons.savings_outlined),
                    decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(8)),
                    chipDisplay: MultiSelectChipDisplay.none(),
                    onConfirm: (values) =>
                        setState(() => _tempSelectedGoalIds = values),
                    searchable: true,
                    searchHint: "Search Goals",
                  )
                else if (state.optionsStatus == FilterOptionsStatus.loading)
                  const SizedBox.shrink()
                else if (state.optionsStatus == FilterOptionsStatus.error)
                  Text("Error loading goals",
                      style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear All')),
                      Row(children: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel')),
                        const SizedBox(width: 8),
                        ElevatedButton(
                            onPressed: _applyFilters,
                            child: const Text('Apply Filters'))
                      ])
                    ]),
              ],
            ),
          ),
        );
      },
    );
  }
}
