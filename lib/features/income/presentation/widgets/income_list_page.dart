import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/income/presentation/bloc/income_list/income_list_bloc.dart';
import 'package:expense_tracker/features/income/presentation/widgets/income_card.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/entities/income_category.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/features/expenses/presentation/pages/expense_list_page.dart'; // Import shared FilterDialogContent
import 'package:flutter_svg/flutter_svg.dart'; // Import SVG

class IncomeListPage extends StatefulWidget {
  const IncomeListPage({super.key});

  @override
  State<IncomeListPage> createState() => _IncomeListPageState();
}

class _IncomeListPageState extends State<IncomeListPage> {
  late IncomeListBloc _incomeListBloc;

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
    try {
      context.read<IncomeListBloc>().add(const LoadIncomes(forceReload: true));
      context
          .read<AccountListBloc>()
          .add(const LoadAccounts(forceReload: true));
      await Future.wait([
        context.read<IncomeListBloc>().stream.firstWhere(
            (state) => state is IncomeListLoaded || state is IncomeListError),
        context.read<AccountListBloc>().stream.firstWhere(
            (state) => state is AccountListLoaded || state is AccountListError),
      ]).timeout(const Duration(seconds: 5));
      log.info("[IncomeListPage] Refresh streams finished or timed out.");
    } catch (e) {
      log.warning("[IncomeListPage] Error during refresh: $e");
    }
  }

  Future<bool> _confirmDeletion(BuildContext context, Income income) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: const Text("Confirm Deletion"),
            content: Text(
                'Are you sure you want to delete the income "${income.title}"?',
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

  // Moved Quantum table builder here
  Widget _buildQuantumIncomeTable(BuildContext context, List<Income> incomes) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final accountState = context.watch<AccountListBloc>().state;

    final rows = incomes.map((inc) {
      String accountName = '...';
      if (accountState is AccountListLoaded) {
        try {
          accountName = accountState.accounts
              .firstWhere((acc) => acc.id == inc.accountId)
              .name;
        } catch (_) {
          accountName = 'N/A';
        }
      }
      return DataRow(cells: [
        DataCell(Text(DateFormatter.formatDate(inc.date),
            style: theme.textTheme.bodySmall)), // Date
        DataCell(Text(inc.title, overflow: TextOverflow.ellipsis)), // Title
        DataCell(Text(inc.category.name,
            overflow: TextOverflow.ellipsis)), // Category
        DataCell(Text(accountName, overflow: TextOverflow.ellipsis)), // Account
        DataCell(Text(
          CurrencyFormatter.format(inc.amount, currencySymbol),
          style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.tertiary,
              fontWeight:
                  FontWeight.w500), // Use tertiary for income in quantum
          textAlign: TextAlign.end,
        )), // Amount
      ]);
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        headingRowHeight: 36,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 40,
        headingTextStyle:
            theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Title')),
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Account')),
          DataColumn(label: Text('Amount'), numeric: true),
        ],
        rows: rows,
      ),
    );
  }

  // Standard list builder
  Widget _buildStandardIncomeList(BuildContext context, List<Income> incomes) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(), // For refresh
      itemCount: incomes.length,
      itemBuilder: (context, index) {
        final income = incomes[index];
        return Dismissible(
          key: Key('income_${income.id}'),
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
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Icon(Icons.delete_sweep_outlined,
                    color: Theme.of(context).colorScheme.onErrorContainer),
              ],
            ),
          ),
          confirmDismiss: (direction) => _confirmDeletion(context, income),
          onDismissed: (direction) {
            log.info(
                "[IncomeListPage] Dismissed income '${income.title}'. Dispatching delete request.");
            context
                .read<IncomeListBloc>()
                .add(DeleteIncomeRequested(income.id));
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                  content: Text('Income "${income.title}" deleted.'),
                  backgroundColor: Colors.orange));
          },
          child: IncomeCard(
            income: income,
            onTap: () => _navigateToEditIncome(income),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    log.info("[IncomeListPage] Build method called.");
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;
    final useTables = modeTheme?.preferDataTableForLists ?? false;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _incomeListBloc),
        BlocProvider.value(value: sl<AccountListBloc>())
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Income'),
          actions: [
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
                  onPressed: () => _showFilterDialog(context, state),
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<IncomeListBloc, IncomeListState>(
          listener: (context, incomeState) {
            log.info(
                "[IncomeListPage] BlocListener received state: ${incomeState.runtimeType}");
            if (incomeState is IncomeListError) {
              log.warning(
                  "[IncomeListPage] Error state detected: ${incomeState.message}");
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(incomeState.message),
                  backgroundColor: theme.colorScheme.error,
                ));
            }
          },
          builder: (context, incomeState) {
            log.info(
                "[IncomeListPage] BlocBuilder building for income state: ${incomeState.runtimeType}");
            Widget child;

            if (incomeState is IncomeListLoading && !incomeState.isReloading) {
              child = const Center(child: CircularProgressIndicator());
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
                String emptyText = filtersActive
                    ? 'No income matches the current filters.'
                    : 'No income recorded yet.';
                String buttonText = filtersActive ? 'Clear Filters' : '';
                VoidCallback? buttonAction = filtersActive
                    ? () {
                        log.info("[IncomeListPage] Clearing filters.");
                        context
                            .read<IncomeListBloc>()
                            .add(const FilterIncomes());
                      }
                    : null;
                String illustrationKey = filtersActive
                    ? 'empty_filter'
                    : 'empty_transactions'; // Use different illustration keys
                String defaultIllustration = filtersActive
                    ? 'assets/elemental/illustrations/empty_calendar.svg'
                    : 'assets/elemental/illustrations/empty_add_transaction.svg';

                child = Center(
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
                        Text(
                          emptyText,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(color: theme.colorScheme.secondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        if (filtersActive)
                          ElevatedButton.icon(
                              icon: const Icon(Icons.clear_all, size: 18),
                              label: Text(buttonText),
                              style: ElevatedButton.styleFrom(
                                  visualDensity: VisualDensity.compact),
                              onPressed: buttonAction)
                        else
                          Text('Tap "+" to add your first income!',
                              style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              } else {
                // Need AccountListBloc provided for names in cards/tables
                child = BlocBuilder<AccountListBloc, AccountListState>(
                  builder: (context, accountState) {
                    log.info(
                        "[IncomeListPage UI] Nested AccountListBloc state: ${accountState.runtimeType}");
                    if (accountState is AccountListLoading &&
                        incomes.isNotEmpty) {
                      return const Center(
                          child: Text("Loading account names..."));
                    }
                    if (accountState is AccountListError &&
                        incomes.isNotEmpty) {
                      log.warning(
                          "[IncomeListPage] Error loading accounts: ${accountState.message}.");
                    }
                    // Build list or table
                    return RefreshIndicator(
                        onRefresh: _refreshIncome,
                        child: useTables
                            ? _buildQuantumIncomeTable(context, incomes)
                            : _buildStandardIncomeList(context, incomes));
                  },
                );
              }
            } else if (incomeState is IncomeListError) {
              child = Center(
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
              child = const Center(child: CircularProgressIndicator());
            }

            return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300), child: child);
          },
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_income',
          onPressed: _navigateToAddIncome,
          tooltip: 'Add Income',
          child: modeTheme != null
              ? SvgPicture.asset(
                  modeTheme.assets.getCommonIcon(AppModeTheme.iconAdd,
                      defaultPath: 'assets/elemental/icons/common/ic_add.svg'),
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                      theme.floatingActionButtonTheme.foregroundColor ??
                          Colors.white,
                      BlendMode.srcIn))
              : const Icon(Icons.add),
        ),
      ),
    );
  }

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
    final List<String> incomeCategoryNames = PredefinedIncomeCategory.values
        .map<String>((e) => IncomeCategory.fromPredefined(e).name)
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocProvider.value(
          // Provide AccountListBloc for the dialog
          value: sl<AccountListBloc>(),
          child: FilterDialogContent(
            isIncomeFilter: true,
            incomeCategoryNames: incomeCategoryNames,
            expenseCategoryNames: const [],
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
                  accountId: accountId));
              Navigator.of(dialogContext).pop();
            },
            onClearFilter: () {
              log.info("[IncomeListPage] Filter dialog cleared.");
              context.read<IncomeListBloc>().add(const FilterIncomes());
              Navigator.of(dialogContext).pop();
            },
          ),
        );
      },
    );
  }
}
