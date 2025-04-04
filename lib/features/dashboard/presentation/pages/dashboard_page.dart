// lib/features/dashboard/presentation/pages/dashboard_page.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/widgets/placeholder_screen.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/core/widgets/transaction_list_item.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart'; // For TransactionListItem icon lookup
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
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
    _ensureBlocLoaded<TransactionListBloc>(() => const LoadTransactions());
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
      context
          .read<TransactionListBloc>()
          .add(const LoadTransactions(forceReload: true));
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

  // --- Recent Transactions Section Widget ---
  Widget _buildRecentTransactions(
      BuildContext context, SettingsState settings) {
    final theme = Theme.of(context);
    final currencySymbol = settings.currencySymbol;
    final transactionState = context.watch<TransactionListBloc>().state;

    List<TransactionEntity> recentItems = [];
    // Only show loading if initial load is happening for transactions
    bool isLoading = transactionState.status == ListStatus.loading;
    String? errorMsg = transactionState.errorMessage;

    if (transactionState.status == ListStatus.success ||
        transactionState.status == ListStatus.reloading) {
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
            recentItems.isEmpty) // Show loading only if list is truly empty
          const Center(
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: CircularProgressIndicator(strokeWidth: 2)))
        else if (errorMsg != null &&
            recentItems.isEmpty) // Show error only if list is truly empty
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
              return TransactionListItem(
                transaction: item,
                currencySymbol: currencySymbol,
                onTap: () {
                  // Use unified edit route
                  const String routeName = RouteNames.editTransaction;
                  context.pushNamed(routeName,
                      pathParameters: {RouteNames.paramTransactionId: item.id},
                      extra: item.originalEntity);
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
              onPressed: () => context.go(RouteNames
                  .transactionsList), // Navigate to the Transactions Tab
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
      // Conditional asset display
      if (isQuantum && useTables)
        _buildQuantumAssetTable(context, overview.accountBalances, settings)
      else if (!isQuantum) // Show Pie Chart for Elemental
        AssetDistributionPieChart(accountBalances: overview.accountBalances)
      else
        const SizedBox
            .shrink(), // Don't show table/pie if Quantum but tables disabled

      _buildRecentTransactions(context, settings),
      const SizedBox(height: 80), // Padding at bottom for global FAB
    ];

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: modeTheme?.pagePadding.copyWith(top: 8, bottom: 8) ??
            const EdgeInsets.symmetric(vertical: 8.0),
        children: children,
      ),
    );
  }

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
      return Card(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                  child: Text("No accounts with balance.",
                      style: theme.textTheme.bodyMedium))));
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
                columns: const [
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

  Widget _buildAetherDashboardBody(BuildContext context,
      FinancialOverview overview, SettingsState settings) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;
    final paletteId = settings.paletteIdentifier;

    Widget aetherContent;
    // Example: Choose visual based on palette
    if (paletteId == AppTheme.aetherPalette2) {
      // Garden
      aetherContent = const FinancialGardenWidget();
    } else {
      // Default to Starfield/Mystic/Calm
      aetherContent = const PersonalConstellationWidget();
    }

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: Stack(
        children: [
          // Background (ensure path is correct in theme config)
          if (modeTheme?.assets.mainBackgroundDark != null &&
              modeTheme!.assets.mainBackgroundDark!.isNotEmpty)
            Positioned.fill(
              child: SvgPicture.asset(
                modeTheme.assets.mainBackgroundDark!,
                fit: BoxFit.cover,
              ),
            ),
          ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: modeTheme?.pagePadding.copyWith(top: 8, bottom: 80) ??
                const EdgeInsets.only(top: 8.0, bottom: 80.0), // Themed padding
            children: [
              // Aether-specific Visualization Area
              Container(
                  height: 300, // Adjust height as needed
                  alignment: Alignment.center,
                  child: aetherContent),
              const SizedBox(height: 16), // Spacing after viz
              // Common Dashboard Cards
              OverallBalanceCard(overview: overview),
              const SizedBox(height: 16),
              IncomeExpenseSummaryCard(overview: overview),
              // Recent Transactions
              _buildRecentTransactions(context, settings),
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
      // Aether might not have a traditional AppBar
      appBar: uiMode == UIMode.aether
          ? null
          : AppBar(title: const Text("Dashboard")),
      body: BlocConsumer<DashboardBloc, DashboardState>(
        listener: (context, state) {
          if (state is DashboardError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                  content: Text("Dashboard Error: ${state.message}"),
                  backgroundColor: theme.colorScheme.error));
          }
        },
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
              bodyContent =
                  const Center(child: Text("Loading overview data..."));
            } else {
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
      // FAB is now handled globally by MainShell
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
