// lib/features/budgets/presentation/pages/budget_detail_page.dart
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BudgetDetailPage extends StatefulWidget {
  final String budgetId;

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
  StreamSubscription? _categorySubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _budgetSubscription =
        context.read<BudgetListBloc>().stream.listen(_handleBlocStateChange);
    _transactionSubscription = context
        .read<TransactionListBloc>()
        .stream
        .listen(_handleBlocStateChange);
    _categorySubscription = context
        .read<CategoryManagementBloc>()
        .stream
        .listen(_handleBlocStateChange);
  }

  @override
  void dispose() {
    _budgetSubscription?.cancel();
    _transactionSubscription?.cancel();
    _categorySubscription?.cancel();
    super.dispose();
  }

  void _handleBlocStateChange(dynamic state) {
    if (mounted && !_isLoading) {
      log.fine("[BudgetDetail] Received Bloc update, reloading detail data.");
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    if (!_isLoading) {
      log.fine("[BudgetDetail] _loadData potentially refreshing.");
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Find Budget Status
    final budgetListState = context.read<BudgetListBloc>().state;
    BudgetWithStatus? foundBudgetStatus;
    if (budgetListState.status == BudgetListStatus.success) {
      foundBudgetStatus = budgetListState.budgetsWithStatus
          .firstWhereOrNull((bws) => bws.budget.id == widget.budgetId);
    }
    if (foundBudgetStatus == null) {
      log.severe(
          "[BudgetDetail] Cannot load details: Budget ID ${widget.budgetId} not found in loaded state.");
      if (mounted)
        setState(() {
          _isLoading = false;
          _error = "Budget not found.";
        });
      return;
    }

    // Find Transactions
    final transactionListState = context.read<TransactionListBloc>().state;
    List<TransactionEntity> foundTransactions = [];
    if (transactionListState.status == ListStatus.success ||
        transactionListState.status == ListStatus.reloading) {
      final budget = foundBudgetStatus.budget;
      final (periodStart, periodEnd) = budget.getCurrentPeriodDates();
      foundTransactions = transactionListState.transactions.where((txn) {
        if (txn.type != TransactionType.expense) return false;
        // Inclusive date check (using isSameDay or checking against start/end boundaries)
        final txnDateOnly =
            DateTime(txn.date.year, txn.date.month, txn.date.day);
        final startDateOnly =
            DateTime(periodStart.year, periodStart.month, periodStart.day);
        final endDateOnly = DateTime(periodEnd.year, periodEnd.month,
            periodEnd.day, 23, 59, 59); // End of day

        // Ensure date is on or after start AND on or before end
        if (txnDateOnly.isBefore(startDateOnly) ||
            txn.date.isAfter(endDateOnly)) return false;

        if (budget.type == BudgetType.overall) return true;
        if (budget.type == BudgetType.categorySpecific &&
            budget.categoryIds != null &&
            budget.categoryIds!.contains(txn.category?.id)) return true;
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
    // Navigate using the new route
    context.pushNamed(RouteNames.editBudget,
        pathParameters: {'id': _budgetWithStatus!.budget.id},
        extra: _budgetWithStatus!.budget);
  }

  void _handleDelete(BuildContext context) async {
    if (_budgetWithStatus == null) return;
    log.info(
        "[BudgetDetail] Delete requested for budget: ${_budgetWithStatus!.budget.name}");
    final confirmed = await AppDialogs.showConfirmation(
      context,
      title: "Confirm Delete",
      content:
          'Are you sure you want to delete the budget "${_budgetWithStatus!.budget.name}"? This cannot be undone.',
      confirmText: "Delete",
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (confirmed == true && context.mounted) {
      context
          .read<BudgetListBloc>()
          .add(DeleteBudget(budgetId: _budgetWithStatus!.budget.id));
      if (context.canPop())
        context.pop();
      else
        context.go(RouteNames.budgetsAndCats);
    }
  }

  void _navigateToTransactionDetail(
      BuildContext context, TransactionEntity transaction) {
    log.info(
        "[BudgetDetail] _navigateToTransactionDetail called for ${transaction.type.name} ID: ${transaction.id}");
    const String routeName =
        RouteNames.editTransaction; // Use edit route for now
    final Map<String, String> params = {
      RouteNames.paramTransactionId: transaction.id
    };
    final dynamic extraData = transaction.originalEntity;

    if (extraData == null) {
      log.severe(
          "[BudgetDetail] CRITICAL: originalEntity is null for transaction ID ${transaction.id}. Cannot navigate.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Error preparing transaction data."),
          backgroundColor: Colors.red));
      return;
    }
    log.info("[BudgetDetail] Attempting navigation via pushNamed:");
    log.info("  Route Name: $routeName");
    log.info("  Path Params: $params");
    log.info("  Extra Data Type: ${extraData?.runtimeType}");
    try {
      context.pushNamed(routeName, pathParameters: params, extra: extraData);
      log.info("[BudgetDetail] pushNamed executed.");
    } catch (e, s) {
      log.severe("[BudgetDetail] Error executing pushNamed: $e\n$s");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error navigating to transaction: $e"),
          backgroundColor: Colors.red));
    }
  }

  // Helper for Progress Bar (REMOVED AETHER TBD)
  Widget _buildProgressBarWidget(
      BuildContext context, AppModeTheme? modeTheme, UIMode uiMode) {
    final theme = Theme.of(context);
    if (_budgetWithStatus == null) return const SizedBox(height: 20);
    final status = _budgetWithStatus!;
    final percentage = status.percentageUsed.clamp(0.0, 1.0);
    final color = status.statusColor;
    final bool isQuantum = uiMode == UIMode.quantum;
    // final bool isAether = uiMode == UIMode.aether; // No longer needed for branching here

    if (isQuantum) {
      return LinearPercentIndicator(
          padding: EdgeInsets.zero,
          lineHeight: 8.0,
          percent: percentage,
          barRadius: const Radius.circular(4),
          backgroundColor:
              theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          progressColor: color,
          animation: false);
    } else {
      // Default for Elemental & Aether
      return LinearPercentIndicator(
          animation: true,
          animationDuration: 600,
          lineHeight: 20.0,
          percent: percentage,
          center: Text("${(status.percentageUsed * 100).toStringAsFixed(0)}%",
              style: TextStyle(
                  color: color.computeLuminance() > 0.5
                      ? Colors.black87
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          barRadius: const Radius.circular(10),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          progressColor: color);
    }
  }

  // Helper for Transaction List
  Widget _buildTransactionListWidget(
      BuildContext context, AppModeTheme? modeTheme, UIMode uiMode) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currency = settings.currencySymbol;
    final useTable =
        uiMode == UIMode.quantum && modeTheme?.preferDataTableForLists == true;

    if (_isLoading) {
      // Check main loading flag here
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_relevantTransactions.isEmpty) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Center(
              child: Text("No transactions found for this budget period.")));
    }

    if (useTable) {
      // Quantum DataTable
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: theme.dataTableTheme.headingRowHeight,
          dataRowMinHeight: theme.dataTableTheme.dataRowMinHeight,
          dataRowMaxHeight: theme.dataTableTheme.dataRowMaxHeight,
          columnSpacing: theme.dataTableTheme.columnSpacing,
          headingTextStyle: theme.dataTableTheme.headingTextStyle,
          dataTextStyle: theme.dataTableTheme.dataTextStyle,
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Title')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Amount'), numeric: true),
          ],
          rows: _relevantTransactions
              .map((txn) => DataRow(
                      onSelectChanged: (selected) {
                        if (selected == true)
                          _navigateToTransactionDetail(context, txn);
                      },
                      cells: [
                        DataCell(Text(DateFormatter.formatDate(txn.date))),
                        DataCell(
                            Text(txn.title, overflow: TextOverflow.ellipsis)),
                        DataCell(Text(txn.category?.name ?? 'N/A')),
                        DataCell(Text(
                            CurrencyFormatter.format(txn.amount, currency),
                            textAlign: TextAlign.end)),
                      ]))
              .toList(),
        ),
      );
    } else {
      // Elemental / Aether ListView
      final bool isAether = uiMode == UIMode.aether;
      final Duration itemDelay =
          isAether ? (modeTheme?.listAnimationDelay ?? 80.ms) : 50.ms;
      final Duration itemDuration =
          isAether ? (modeTheme?.listAnimationDuration ?? 450.ms) : 300.ms;

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _relevantTransactions.length,
        itemBuilder: (ctx, index) {
          final txn = _relevantTransactions[index];
          Widget item = TransactionListItem(
              transaction: txn,
              currencySymbol: currency,
              onTap: () => _navigateToTransactionDetail(context, txn));
          if (isAether) {
            item = item
                .animate(delay: itemDelay * index)
                .fadeIn(duration: itemDuration)
                .slideY(begin: 0.2, curve: Curves.easeOut);
          } else {
            item = item
                .animate()
                .fadeIn(delay: (itemDelay.inMilliseconds * 0.5 * index).ms);
          }
          return Padding(
            // Add padding between items
            padding: const EdgeInsets.only(bottom: 4.0),
            child: item,
          );
        },
      );
    }
  }

  // Helper for Category Chips
  Widget _buildCategoryChips(BuildContext context, List<String> categoryIds) {
    final categoryState = context.watch<CategoryManagementBloc>().state;
    final theme = Theme.of(context);
    if (categoryState.status != CategoryManagementStatus.loaded)
      return const SizedBox.shrink();
    final allCategories = [
      ...categoryState.allExpenseCategories,
      ...categoryState.allIncomeCategories
    ];
    final chips = categoryIds
        .map((id) {
          final category = allCategories.firstWhereOrNull((c) => c.id == id);
          if (category == null) return null;
          // Use themed icon getter (optional)
          Widget avatarIcon;
          final modeTheme = context.modeTheme;
          IconData fallbackIcon =
              availableIcons[category.iconName] ?? Icons.label;

          if (modeTheme != null) {
            String svgPath = modeTheme.assets
                .getCategoryIcon(category.iconName, defaultPath: '');
            if (svgPath.isNotEmpty) {
              avatarIcon = SvgPicture.asset(svgPath,
                  width: 16,
                  height: 16,
                  colorFilter:
                      ColorFilter.mode(category.displayColor, BlendMode.srcIn));
            } else {
              avatarIcon =
                  Icon(fallbackIcon, size: 16, color: category.displayColor);
            }
          } else {
            avatarIcon =
                Icon(fallbackIcon, size: 16, color: category.displayColor);
          }

          return Chip(
            avatar: avatarIcon,
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
    if (chips.isEmpty)
      return Text("Applies to: All Categories",
          style:
              theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic));
    return Wrap(spacing: 6.0, runSpacing: 4.0, children: [
      Text("Applies to:", style: theme.textTheme.bodySmall),
      const SizedBox(width: 4),
      ...chips
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final uiMode = settings.uiMode;
    final modeTheme = context.modeTheme;

    if (_isLoading)
      return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()));
    if (_error != null || _budgetWithStatus == null)
      return Scaffold(
          appBar: AppBar(title: const Text("Error")),
          body: Center(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(_error ?? "Budget could not be loaded.",
                      style: TextStyle(color: theme.colorScheme.error)))));

    final budget = _budgetWithStatus!.budget;
    final status = _budgetWithStatus!;
    final currency = settings.currencySymbol;
    final isAether = uiMode == UIMode.aether;
    final String? bgPath = isAether
        ? (Theme.of(context).brightness == Brightness.dark
            ? modeTheme?.assets.mainBackgroundDark
            : modeTheme?.assets.mainBackgroundLight)
        : null;

    Widget mainContent = ListView(
      padding: modeTheme?.pagePadding.copyWith(
              bottom: 80,
              top: isAether
                  ? (modeTheme.pagePadding.top +
                      kToolbarHeight +
                      MediaQuery.of(context).padding.top)
                  : modeTheme.pagePadding.top) ??
          const EdgeInsets.all(16.0).copyWith(bottom: 80),
      children: [
        // Budget Status Header Card
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
              _buildProgressBarWidget(context, modeTheme, uiMode),
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
                        fontWeight: FontWeight.w500,
                        color: status.amountRemaining >= 0
                            ? theme.colorScheme.primary
                            : status.statusColor),
                  ),
                ],
              ),
              if (budget.type == BudgetType.categorySpecific ||
                  budget.type == BudgetType.overall) ...[
                const SizedBox(height: 10),
                _buildCategoryChips(context, budget.categoryIds ?? []),
              ]
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Transactions Section
        SectionHeader(
            title: "Transactions in Period (${_relevantTransactions.length})"),
        _buildTransactionListWidget(context, modeTheme, uiMode),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(budget.name, overflow: TextOverflow.ellipsis),
        backgroundColor: isAether ? Colors.transparent : null,
        elevation: isAether ? 0 : null,
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
      extendBodyBehindAppBar: isAether,
      body: isAether && bgPath != null && bgPath.isNotEmpty
          ? Stack(
              children: [
                Positioned.fill(
                    child: SvgPicture.asset(bgPath, fit: BoxFit.cover)),
                mainContent,
              ],
            )
          : mainContent,
    );
  }
}
