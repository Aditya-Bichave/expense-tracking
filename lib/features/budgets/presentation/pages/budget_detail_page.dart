// lib/features/budgets/presentation/pages/budget_detail_page.dart
import 'dart:async';

import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:expense_tracker/core/constants/route_names.dart'; // <<< ENSURE THIS IMPORT EXISTS
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/widgets/app_card.dart'; // Import AppCard
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
// Import BudgetCard if needed for header, or build header directly
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart'; // For icon lookup in chip
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class BudgetDetailPage extends StatefulWidget {
  final String budgetId; // Pass ID via path parameter

  const BudgetDetailPage({super.key, required this.budgetId});

  @override
  State<BudgetDetailPage> createState() => _BudgetDetailPageState();
}

class _BudgetDetailPageState extends State<BudgetDetailPage> {
  BudgetWithStatus? _budgetWithStatus;
  List<TransactionEntity> _relevantTransactions = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _budgetSubscription;
  StreamSubscription? _transactionSubscription;
  StreamSubscription? _categorySubscription; // To rebuild chips if names change

  @override
  void initState() {
    super.initState();
    _loadData();
    // Listen for changes that might affect this budget or its transactions
    _budgetSubscription =
        context.read<BudgetListBloc>().stream.listen(_handleBlocStateChange);
    _transactionSubscription = context
        .read<TransactionListBloc>()
        .stream
        .listen(_handleBlocStateChange);
    _categorySubscription = context
        .read<CategoryManagementBloc>()
        .stream
        .listen(_handleBlocStateChange); // Listen for category name changes
  }

  @override
  void dispose() {
    _budgetSubscription?.cancel();
    _transactionSubscription?.cancel();
    _categorySubscription?.cancel();
    super.dispose();
  }

  void _handleBlocStateChange(dynamic state) {
    // More specific check: Reload only if the relevant data might have changed
    // or if the list itself has changed (e.g., item deleted)
    // For simplicity now, reload if not already loading.
    if (mounted && !_isLoading) {
      log.fine("[BudgetDetail] Received Bloc update, reloading detail data.");
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    // Avoid flicker if already loaded and just receiving minor updates
    if (!_isLoading) {
      log.fine(
          "[BudgetDetail] _loadData called while not loading, potentially refreshing.");
      // Consider only setState if data actually changes, but full reload is simpler for now
    }
    setState(() {
      _isLoading = true; // Always set loading true at start of load attempt
      _error = null;
    });

    // 1. Find the BudgetWithStatus from BudgetListBloc state
    final budgetListState = context.read<BudgetListBloc>().state;
    BudgetWithStatus? foundBudgetStatus;
    if (budgetListState.status == BudgetListStatus.success) {
      foundBudgetStatus = budgetListState.budgetsWithStatus.firstWhereOrNull(
        (bws) => bws.budget.id == widget.budgetId,
      );
    }

    if (foundBudgetStatus == null) {
      log.severe(
          "[BudgetDetail] Cannot load details: Budget ID ${widget.budgetId} not found in loaded state.");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Budget not found. It might have been deleted.";
        });
        // Optional: Auto-pop after delay if budget is gone
        // Future.delayed(Duration(seconds: 2), () => mounted ? context.pop() : null);
      }
      return;
    }

    // 2. Find relevant transactions from TransactionListBloc state
    final transactionListState = context.read<TransactionListBloc>().state;
    List<TransactionEntity> foundTransactions = [];
    if (transactionListState.status == ListStatus.success ||
        transactionListState.status == ListStatus.reloading) {
      final budget = foundBudgetStatus.budget;
      final (periodStart, periodEnd) = budget.getCurrentPeriodDates();

      foundTransactions = transactionListState.transactions.where((txn) {
        if (txn.type != TransactionType.expense) return false;
        // Inclusive date check for start and end
        final txnDateOnly =
            DateTime(txn.date.year, txn.date.month, txn.date.day);
        final startDateOnly =
            DateTime(periodStart.year, periodStart.month, periodStart.day);
        final endDateOnly =
            DateTime(periodEnd.year, periodEnd.month, periodEnd.day);

        if (txnDateOnly.isBefore(startDateOnly) ||
            txnDateOnly.isAfter(endDateOnly)) {
          return false; // Outside period
        }

        if (budget.type == BudgetType.overall) return true;

        if (budget.type == BudgetType.categorySpecific &&
            budget.categoryIds != null &&
            budget.categoryIds!.contains(txn.category?.id)) {
          return true;
        }
        return false;
      }).toList();
      foundTransactions.sort((a, b) => b.date.compareTo(a.date));
    }

    if (mounted) {
      setState(() {
        _budgetWithStatus = foundBudgetStatus;
        _relevantTransactions = foundTransactions;
        _isLoading = false;
      });
    }
  }

  void _navigateToEdit(BuildContext context) {
    if (_budgetWithStatus == null) return;
    log.info(
        "[BudgetDetail] Navigate to edit for budget: ${_budgetWithStatus!.budget.name}");
    // Use the correct RouteName constant
    context.pushNamed(
      RouteNames.editBudget, // <<< CORRECTED RouteName usage
      pathParameters: {'id': _budgetWithStatus!.budget.id},
      extra: _budgetWithStatus!.budget,
    );
  }

  void _handleDelete(BuildContext context) async {
    if (_budgetWithStatus == null) return;
    log.info(
        "[BudgetDetail] Delete requested for budget: ${_budgetWithStatus!.budget.name}");
    final confirmed = await AppDialogs.showConfirmation(
      context,
      title: "Confirm Delete",
      content:
          'Are you sure you want to delete the budget "${_budgetWithStatus!.budget.name}"?',
      confirmText: "Delete",
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (confirmed == true && context.mounted) {
      context
          .read<BudgetListBloc>()
          .add(DeleteBudget(budgetId: _budgetWithStatus!.budget.id));
      if (context.canPop())
        context.pop(); // Go back after requesting delete
      else
        context.go(RouteNames.budgetsAndCats); // Fallback if cannot pop
    }
  }

  void _navigateToTransactionDetail(
      BuildContext context, TransactionEntity transaction) {
    log.info(
        "[BudgetDetail] Navigate to txn detail/edit for txn ID: ${transaction.id}");
    const String routeName = RouteNames.editTransaction;
    final Map<String, String> params = {
      RouteNames.paramTransactionId: transaction.id
    };
    final dynamic extraData = transaction.originalEntity;
    if (extraData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Error preparing transaction data."),
          backgroundColor: Colors.red));
      return;
    }
    context.pushNamed(routeName, pathParameters: params, extra: extraData);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;

    if (_isLoading) {
      return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _budgetWithStatus == null) {
      return Scaffold(
          appBar: AppBar(title: const Text("Error")),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_error ?? "Budget could not be loaded.",
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
          ));
    }

    final budget = _budgetWithStatus!.budget;
    final status = _budgetWithStatus!;
    final currency = settings.currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: Text(budget.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _navigateToEdit(context),
              tooltip: "Edit Budget"),
          IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: () => _handleDelete(context),
              tooltip: "Delete Budget"),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0).copyWith(bottom: 80),
        children: [
          // --- Budget Status Header ---
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget.period == BudgetPeriodType.recurringMonthly
                      ? 'This Month\'s Progress'
                      : 'Period Progress (${DateFormatter.formatDate(budget.startDate!)} - ${DateFormatter.formatDate(budget.endDate!)})',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                LinearPercentIndicator(
                  animation: true,
                  animationDuration: 600,
                  lineHeight: 20.0,
                  percent: status.percentageUsed.clamp(0.0, 1.0),
                  center: Text(
                    "${(status.percentageUsed * 100).toStringAsFixed(0)}%",
                    style: TextStyle(
                        color: status.statusColor.computeLuminance() > 0.5
                            ? Colors.black87
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                  barRadius: const Radius.circular(10),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  progressColor: status.statusColor,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Spent: ${CurrencyFormatter.format(status.amountSpent, currency)}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: status.statusColor)),
                    Text(
                        'Target: ${CurrencyFormatter.format(budget.targetAmount, currency)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      status.amountRemaining >= 0
                          ? '${CurrencyFormatter.format(status.amountRemaining, currency)} left'
                          : '${CurrencyFormatter.format(status.amountRemaining.abs(), currency)} over',
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: status.amountRemaining >= 0
                              ? theme.colorScheme.primary
                              : status.statusColor),
                    ),
                  ],
                ),
                if (budget.type == BudgetType.categorySpecific) ...[
                  const SizedBox(height: 10),
                  _buildCategoryChips(
                      context, budget.categoryIds ?? []), // Pass context here
                ]
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- Relevant Transactions ---
          SectionHeader(
              title:
                  "Transactions in Period (${_relevantTransactions.length})"),
          if (_relevantTransactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                  child: Text("No transactions found for this budget period.",
                      style: theme.textTheme.bodyMedium)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _relevantTransactions.length,
              itemBuilder: (ctx, index) {
                final txn = _relevantTransactions[index];
                return TransactionListItem(
                  transaction: txn,
                  currencySymbol: currency,
                  onTap: () => _navigateToTransactionDetail(context, txn),
                );
              },
            )
        ],
      ),
    );
  }

  // Helper method moved inside the State class
  Widget _buildCategoryChips(BuildContext context, List<String> categoryIds) {
    final categoryState = context.watch<CategoryManagementBloc>().state;
    final theme = Theme.of(context); // Get theme here
    if (categoryState.status != CategoryManagementStatus.loaded) {
      return const SizedBox.shrink();
    }
    // Use *all* categories from the state for lookup
    final allCategories = [
      ...categoryState.predefinedExpenseCategories,
      ...categoryState.customExpenseCategories,
      ...categoryState
          .predefinedIncomeCategories, // Include income just in case
      ...categoryState.customIncomeCategories,
    ];

    final chips = categoryIds
        .map((id) {
          final category = allCategories.firstWhereOrNull((c) => c.id == id);
          if (category == null) return null;
          return Chip(
            avatar: Icon(availableIcons[category.iconName] ?? Icons.category,
                size: 16, color: category.displayColor),
            label: Text(category.name),
            labelStyle: theme.textTheme.labelSmall
                ?.copyWith(color: category.displayColor),
            backgroundColor: category.displayColor.withOpacity(0.1),
            side: BorderSide.none,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          );
        })
        .whereNotNull()
        .toList();

    if (chips.isEmpty) {
      return Text("No categories assigned", style: theme.textTheme.bodySmall);
    }

    return Wrap(
      spacing: 6.0,
      runSpacing: 4.0,
      children: chips,
    );
  }
}
