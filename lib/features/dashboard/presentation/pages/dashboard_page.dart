// lib/features/dashboard/presentation/pages/dashboard_page.dart
// --- Add imports ---
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart'; // Needed for TransactionListItem usage
import 'package:expense_tracker/core/widgets/placeholder_screen.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/core/widgets/transaction_list_item.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart'; // For TransactionListItem icon lookup
// --- Import unified transaction components ---
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
// --- Remove old imports if present ---
// import 'package:expense_tracker/features/expenses/domain/entities/expense.dart'; // No longer needed directly here
// import 'package:expense_tracker/features/income/domain/entities/income.dart'; // No longer needed directly here
// import 'package:expense_tracker/features/expenses/presentation/bloc/expense_list/expense_list_bloc.dart'; // REMOVE
// import 'package:expense_tracker/features/income/presentation/bloc/income_list/income_list_bloc.dart'; // REMOVE
// --- Existing imports ---
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/aether_themes/presentation/widgets/financial_garden_widget.dart';
import 'package:expense_tracker/features/aether_themes/presentation/widgets/personal_constellation_widget.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/overall_balance_card.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/income_expense_summary_card.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/asset_distribution_pie_chart.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:flutter_svg/svg.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DashboardBloc _dashboardBloc;
  late SettingsBloc _settingsBloc;

  @override
  void initState() {
    super.initState();
    log.info("[DashboardPage] initState called.");
    _dashboardBloc = BlocProvider.of<DashboardBloc>(context);
    _settingsBloc = BlocProvider.of<SettingsBloc>(context);

    // Ensure dependent BLoCs are loaded if not already handled globally
    _ensureBlocLoaded<AccountListBloc>(() => const LoadAccounts());
    // --- Use TransactionListBloc ---
    _ensureBlocLoaded<TransactionListBloc>(() => const LoadTransactions());
    // --- Remove checks for old Blocs ---
    // _ensureBlocLoaded<ExpenseListBloc>(() => const LoadExpenses()); // REMOVE
    // _ensureBlocLoaded<IncomeListBloc>(() => const LoadIncomes()); // REMOVE
  }

  // Helper to check and load dependent BLoCs if needed
  void _ensureBlocLoaded<T extends Bloc>(Function eventCreator) {
    try {
      final bloc = BlocProvider.of<T>(context);
      // A more robust check might be needed depending on the exact initial state class name
      if (bloc.state.runtimeType.toString().contains('Initial')) {
        log.info(
            "[DashboardPage] ${T.toString()} is initial, dispatching load.");
        bloc.add(eventCreator());
      }
    } catch (e) {
      log.severe(
          "[DashboardPage] Error ensuring ${T.toString()} is loaded: $e");
      // Optionally show an error message to the user
    }
  }

  Future<void> _refreshDashboard() async {
    log.info("[DashboardPage] Pull-to-refresh triggered.");
    // Refresh Dashboard itself
    _dashboardBloc.add(const LoadDashboard(forceReload: true));

    // Trigger refresh for dependent lists
    try {
      context
          .read<AccountListBloc>()
          .add(const LoadAccounts(forceReload: true));
      // --- Refresh unified list ---
      context
          .read<TransactionListBloc>()
          .add(const LoadTransactions(forceReload: true));
      // --- Remove old refreshes ---
      // context.read<ExpenseListBloc>().add(const LoadExpenses(forceReload: true)); // REMOVE
      // context.read<IncomeListBloc>().add(const LoadIncomes(forceReload: true)); // REMOVE
    } catch (e) {
      log.warning("Error triggering dependent Blocs refresh during pull: $e");
    }

    // Wait for dashboard load completion
    try {
      await _dashboardBloc.stream
          .firstWhere(
              (state) => state is DashboardLoaded || state is DashboardError)
          .timeout(const Duration(seconds: 7));
      log.info("[DashboardPage] Refresh stream finished or timed out.");
    } catch (e) {
      log.warning(
          "[DashboardPage] Error or timeout waiting for refresh stream: $e");
    }
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.remove_circle_outline), // Expense icon
            title: const Text('Add Expense'),
            onTap: () {
              Navigator.pop(ctx);
              // Use context.pushNamed for potentially pushing onto root navigator
              context.pushNamed(RouteNames.addExpense);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline), // Income icon
            title: const Text('Add Income'),
            onTap: () {
              Navigator.pop(ctx);
              context.pushNamed(RouteNames.addIncome);
            },
          ),
          // Add Transfer option later if needed
        ],
      ),
    );
  }

  // --- Recent Transactions Section Widget ---
  Widget _buildRecentTransactions(
      BuildContext context, SettingsState settings) {
    final theme = Theme.of(context);
    final currencySymbol = settings.currencySymbol;

    // --- Watch the unified TransactionListBloc ---
    final transactionState = context.watch<TransactionListBloc>().state;

    List<TransactionEntity> recentItems = [];
    bool isLoading = transactionState.status == ListStatus.loading ||
        transactionState.status == ListStatus.reloading;
    String? errorMsg = transactionState.errorMessage;

    if (!isLoading &&
        errorMsg == null &&
        transactionState.status == ListStatus.success) {
      // Already sorted by date descending in the BLoC/UseCase by default
      recentItems =
          transactionState.transactions.take(5).toList(); // Show latest 5
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
            title: 'Recent Activity',
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8)),
        if (isLoading &&
            recentItems.isEmpty) // Show loading only if list is empty
          const Center(
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: CircularProgressIndicator(strokeWidth: 2)))
        else if (errorMsg != null &&
            recentItems.isEmpty) // Show error only if list is empty
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Center(
                child: Text("Error loading recent: $errorMsg",
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center)),
          )
        else if (recentItems.isEmpty)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Center(
                child: Text("No transactions recorded yet.",
                    style: theme.textTheme.bodyMedium)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentItems.length,
            itemBuilder: (ctx, index) {
              final item = recentItems[index];
              // Use the common TransactionListItem widget
              return TransactionListItem(
                transaction: item,
                currencySymbol: currencySymbol,
                onTap: () {
                  // Navigate to edit page based on type
                  final routeName = item.type == TransactionType.expense
                      ? RouteNames.editExpense
                      : RouteNames.editIncome;
                  context.pushNamed(routeName,
                      pathParameters: {RouteNames.paramTransactionId: item.id},
                      extra: item.originalEntity // Pass original for edit form
                      );
                },
              );
            },
          ),
        // "View All" Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Center(
            child: TextButton.icon(
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('View All Transactions'),
              // Navigate to the Transactions Tab using GoRouter path
              onPressed: () => context.go(RouteNames.transactionsList),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.secondary,
                textStyle: theme.textTheme.labelLarge,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Dashboard Build Logic ---

  // Builder for Elemental/Quantum modes
  Widget _buildElementalQuantumDashboard(BuildContext context,
      FinancialOverview overview, SettingsState settings) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;
    final bool isQuantum = settings.uiMode == UIMode.quantum;
    final bool useTables = modeTheme?.preferDataTableForLists ?? false;

    List<Widget> children = [
      OverallBalanceCard(overview: overview),
      const SizedBox(height: 16),
      IncomeExpenseSummaryCard(overview: overview),
      const SizedBox(height: 16),
      // Placeholder Widgets (using simple Cards)
      Card(
          elevation: 1,
          child: ListTile(
              leading:
                  Icon(Icons.donut_small_outlined, color: theme.disabledColor),
              title: Text('Budget Overview'),
              subtitle: Text('Coming Soon!'),
              enabled: false)),
      const SizedBox(height: 16),
      Card(
          elevation: 1,
          child: ListTile(
              leading: Icon(Icons.savings_outlined, color: theme.disabledColor),
              title: Text('Savings Goals'),
              subtitle: Text('Coming Soon!'),
              enabled: false)),
      const SizedBox(height: 16),
      Card(
          elevation: 1,
          child: ListTile(
              leading:
                  Icon(Icons.insights_outlined, color: theme.disabledColor),
              title: Text('Aspirant Engine Insights'),
              subtitle: Text('Coming Soon!'),
              enabled: false)),
      const SizedBox(height: 16),
      // Conditional asset display
      if (isQuantum && useTables)
        _buildQuantumAssetTable(context, overview.accountBalances, settings)
      else if (!isQuantum)
        AssetDistributionPieChart(accountBalances: overview.accountBalances)
      else
        const SizedBox.shrink(),

      // Recent Transactions Section (Uses TransactionListBloc)
      _buildRecentTransactions(context, settings),

      const SizedBox(height: 80), // Padding at bottom for FAB
    ];

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: modeTheme?.pagePadding ?? const EdgeInsets.all(16.0),
        children: children,
      ),
    );
  }

  // Specific widget for Quantum Asset Table
  Widget _buildQuantumAssetTable(BuildContext context,
      Map<String, double> accountBalances, SettingsState settings) {
    final theme = Theme.of(context);
    final currencySymbol = settings.currencySymbol;
    final rows = accountBalances.entries.map((entry) {
      return DataRow(cells: [
        DataCell(Text(entry.key, style: theme.textTheme.bodyMedium)),
        DataCell(Text(
          CurrencyFormatter.format(entry.value, currencySymbol),
          style: theme.textTheme.bodyMedium?.copyWith(
              color: entry.value >= 0
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.error,
              fontWeight: FontWeight.w500),
          textAlign: TextAlign.end,
        )),
      ]);
    }).toList();

    if (rows.isEmpty) {
      return Card(/* ... empty state ... */);
    }
    return Card(
      margin: theme.cardTheme.margin,
      shape: theme.cardTheme.shape,
      elevation: theme.cardTheme.elevation,
      color: theme.cardTheme.color,
      clipBehavior: theme.cardTheme.clipBehavior ?? Clip.none,
      child: Padding(
        padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Asset Balances', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                /* ... table properties ... */ columns: const [
                  DataColumn(label: Text('Account')),
                  DataColumn(label: Text('Balance'), numeric: true),
                ],
                rows: rows,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Specific Widget Builder for Aether Dashboard Body
  Widget _buildAetherDashboardBody(BuildContext context,
      FinancialOverview overview, SettingsState settings) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;
    final paletteId = settings.paletteIdentifier;

    Widget aetherContent;
    if (paletteId == AppTheme.aetherPalette2) {
      aetherContent = const FinancialGardenWidget();
    } else {
      aetherContent = const PersonalConstellationWidget();
    }

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: Stack(
        children: [
          if (modeTheme?.assets.mainBackgroundDark != null)
            Positioned.fill(
              child: SvgPicture.asset(
                modeTheme!.assets.mainBackgroundDark!,
                fit: BoxFit.cover,
              ),
            ),
          ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Container(height: 300, child: aetherContent), // Placeholder viz
              OverallBalanceCard(overview: overview),
              IncomeExpenseSummaryCard(overview: overview),
              _buildRecentTransactions(
                  context, settings), // Recent transactions
              const SizedBox(height: 80),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    log.info("[DashboardPage] Build method called.");
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final uiMode = settingsState.uiMode;

    return Scaffold(
      appBar:
          uiMode == UIMode.aether ? null : AppBar(/* ... AppBar setup ... */),
      body: BlocConsumer<DashboardBloc, DashboardState>(
        listener: (context, state) {/* ... Error listener ... */},
        builder: (context, state) {
          log.fine(
              "[DashboardPage] BlocBuilder building for state: ${state.runtimeType}");
          Widget bodyContent;

          if (state is DashboardLoading && !state.isReloading) {
            bodyContent = const Center(child: CircularProgressIndicator());
          } else if (state is DashboardLoaded ||
              (state is DashboardLoading && state.isReloading)) {
            final overview = (state is DashboardLoaded)
                ? state.overview
                : (context.read<DashboardBloc>().state as DashboardLoaded?)
                    ?.overview;
            if (overview == null) {
              bodyContent = const Center(
                  child: Text("Loading overview data...")); // Should be brief
            } else {
              // Switch based on UI Mode
              switch (uiMode) {
                case UIMode.aether:
                  bodyContent = _buildAetherDashboardBody(
                      context, overview, settingsState);
                  break;
                case UIMode.quantum:
                case UIMode.elemental:
                default:
                  bodyContent = _buildElementalQuantumDashboard(
                      context, overview, settingsState);
                  break;
              }
            }
          } else if (state is DashboardError) {
            bodyContent = Center(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Error loading dashboard: ${state.message}',
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center)));
          } else {
            // Initial state
            bodyContent = const Center(child: CircularProgressIndicator());
          }

          return AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: KeyedSubtree(
                  key: ValueKey(
                      state.runtimeType.toString() + uiMode.toString()),
                  child: bodyContent));
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'dashboard_fab',
        onPressed: () => _showQuickActions(context),
        tooltip: 'Quick Actions',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Keep Capitalize extension or move to utils
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
