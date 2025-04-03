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
import 'package:expense_tracker/features/expenses/presentation/bloc/expense_list/expense_list_bloc.dart';
import 'package:expense_tracker/features/income/presentation/bloc/income_list/income_list_bloc.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import SettingsBloc
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:flutter_svg/svg.dart'; // Import CurrencyFormatter

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DashboardBloc _dashboardBloc;

  @override
  void initState() {
    super.initState();
    log.info("[DashboardPage] initState called.");
    _dashboardBloc = sl<DashboardBloc>();
    if (_dashboardBloc.state is DashboardInitial) {
      log.info(
          "[DashboardPage] Initial state detected, dispatching LoadDashboard.");
      _dashboardBloc.add(const LoadDashboard());
    }
  }

  Future<void> _refreshDashboard() async {
    log.info("[DashboardPage] Pull-to-refresh triggered.");
    _dashboardBloc.add(const LoadDashboard(forceReload: true));
    try {
      sl<AccountListBloc>().add(const LoadAccounts(forceReload: true));
      sl<ExpenseListBloc>().add(const LoadExpenses(forceReload: true));
      sl<IncomeListBloc>().add(const LoadIncomes(forceReload: true));
    } catch (e) {
      log.warning("Error triggering dependent Blocs refresh: $e");
    }

    try {
      await _dashboardBloc.stream
          .firstWhere(
              (state) => state is DashboardLoaded || state is DashboardError)
          .timeout(const Duration(seconds: 5));
      log.info("[DashboardPage] Refresh stream finished or timed out.");
    } catch (e) {
      log.warning(
          "[DashboardPage] Error or timeout waiting for refresh stream: $e");
    }
  }

  // Builder for Elemental/Quantum modes
  Widget _buildElementalQuantumDashboard(
      BuildContext context, FinancialOverview overview) {
    final theme = Theme.of(context);
    final isQuantum =
        context.read<SettingsBloc>().state.uiMode == UIMode.quantum;

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          OverallBalanceCard(overview: overview),
          const SizedBox(height: 16),
          IncomeExpenseSummaryCard(overview: overview),
          const SizedBox(height: 16),
          // Conditional asset display
          if (isQuantum)
            _buildQuantumAssetTable(context, overview.accountBalances)
          else
            AssetDistributionPieChart(
                accountBalances: overview.accountBalances),
          const SizedBox(height: 24),
          Center(
              child: Text("More insights coming soon!",
                  style: theme.textTheme.labelMedium)),
        ],
      ),
    );
  }

  // Specific widget for Quantum Asset Table
  Widget _buildQuantumAssetTable(
      BuildContext context, Map<String, double> accountBalances) {
    final theme = Theme.of(context);
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;

    final rows = accountBalances.entries.map((entry) {
      return DataRow(cells: [
        DataCell(
            Text(entry.key, style: theme.textTheme.bodyMedium)), // Account Name
        DataCell(Text(
          CurrencyFormatter.format(entry.value, currencySymbol),
          style: theme.textTheme.bodyMedium?.copyWith(
              color: entry.value >= 0
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.error, // Use quantum colors
              fontWeight: FontWeight.w500),
          textAlign: TextAlign.end,
        )), // Balance
      ]);
    }).toList();

    if (rows.isEmpty) {
      return Card(
        // Use Card consistent with Quantum theme
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
              child: Text('No accounts added yet.',
                  style: theme.textTheme.bodyMedium)),
        ),
      );
    }

    return Card(
      // Wrap table in a card for consistency
      child: Padding(
        padding:
            const EdgeInsets.only(top: 12.0, bottom: 4.0), // Adjust padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Asset Balances', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              // Make table horizontally scrollable if needed
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20, // Adjust spacing
                headingRowHeight: 36,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 40,
                headingTextStyle: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
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

  @override
  Widget build(BuildContext context) {
    log.info("[DashboardPage] build method called.");
    final theme = Theme.of(context);
    final uiMode = context.watch<SettingsBloc>().state.uiMode; // Watch UI mode
    final paletteId = context
        .watch<SettingsBloc>()
        .state
        .paletteIdentifier; // Watch Palette for Aether sub-themes

    return Scaffold(
      // Aether might have a transparent AppBar or none
      appBar: uiMode == UIMode.aether
          ? null
          : AppBar(
              title: const Text('Dashboard'),
              actions: [
                IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshDashboard,
                    tooltip: 'Refresh'),
              ],
              // Apply theme settings
              backgroundColor: theme.appBarTheme.backgroundColor,
              foregroundColor: theme.appBarTheme.foregroundColor,
              elevation: theme.appBarTheme.elevation,
            ),
      // Body depends on UI Mode
      body: BlocConsumer<DashboardBloc, DashboardState>(
        listener: (context, state) {
          log.info(
              "[DashboardPage] BlocListener received state: ${state.runtimeType}");
          if (state is DashboardError) {
            log.warning(
                "[DashboardPage] Error state detected: ${state.message}");
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                  content: Text('Error loading dashboard: ${state.message}'),
                  backgroundColor: theme.colorScheme.error));
          }
        },
        builder: (context, state) {
          log.info(
              "[DashboardPage] BlocBuilder building for state: ${state.runtimeType}");
          Widget child;

          if (state is DashboardLoading && !state.isReloading) {
            child = const Center(child: CircularProgressIndicator());
          } else if (state is DashboardLoaded ||
              (state is DashboardLoading && state.isReloading)) {
            final overview = (state is DashboardLoaded)
                ? state.overview
                : (context.read<DashboardBloc>().state as DashboardLoaded?)
                    ?.overview;

            if (overview == null) {
              child = const Center(child: Text("Loading data..."));
            } else {
              // --- UI Mode Specific Body ---
              switch (uiMode) {
                case UIMode.aether:
                  // Choose Aether widget based on palette ID convention
                  if (paletteId == AppTheme.aetherPalette2) {
                    // Garden
                    child = const FinancialGardenWidget(); // Placeholder
                  } else {
                    // Starfield, Mystic, CalmSky or Default Aether
                    child = const PersonalConstellationWidget(); // Placeholder
                  }
                  break;
                case UIMode.quantum:
                case UIMode.elemental:
                  child = _buildElementalQuantumDashboard(context, overview);
                  break;
              }
              // --- End UI Mode Specific Body ---
            }
          } else if (state is DashboardError) {
            child = Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.error, size: 50),
                    const SizedBox(height: 16),
                    Text('Failed to load dashboard',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: _refreshDashboard)
                  ],
                ),
              ),
            );
          } else {
            child = const Center(child: CircularProgressIndicator());
          }

          // Add background based on theme extension if specified
          final modeTheme = context.modeTheme;
          String? bgPath = theme.brightness == Brightness.dark
              ? modeTheme?.assets.mainBackgroundDark
              : modeTheme?.assets.mainBackgroundLight;

          Widget themedChild = AnimatedSwitcher(
              duration: const Duration(milliseconds: 400), child: child);

          if (bgPath != null) {
            return Stack(
              children: [
                Positioned.fill(
                  child: SvgPicture.asset(
                    bgPath,
                    fit: BoxFit.cover,
                    // colorFilter: ColorFilter.mode(theme.scaffoldBackgroundColor.withOpacity(0.5), BlendMode.dstOver), // Example blend
                  ),
                ),
                themedChild, // Place the main content on top
              ],
            );
          } else {
            return themedChild; // No background asset specified
          }
        },
      ),
    );
  }
}

// Capitalize extension (can move to utils)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
