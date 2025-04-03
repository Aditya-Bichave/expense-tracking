import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import SettingsBloc + UIMode
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/overall_balance_card.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/income_expense_summary_card.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/asset_distribution_pie_chart.dart';
// Import placeholder Aether widgets
import 'package:expense_tracker/features/aether_themes/presentation/widgets/financial_garden_widget.dart';
import 'package:expense_tracker/features/aether_themes/presentation/widgets/personal_constellation_widget.dart';

import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/expense_list/expense_list_bloc.dart';
import 'package:expense_tracker/features/income/presentation/bloc/income_list/income_list_bloc.dart';
import 'package:expense_tracker/main.dart'; // Import logger

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
    // Dispatch initial load event if needed
    if (_dashboardBloc.state is DashboardInitial) {
      log.info(
          "[DashboardPage] Initial state detected, dispatching LoadDashboard.");
      _dashboardBloc.add(const LoadDashboard());
    }
  }

  // Function to handle manual refresh
  Future<void> _refreshDashboard() async {
    log.info("[DashboardPage] Pull-to-refresh triggered.");
    // Dispatch load event for the dashboard, forcing reload
    _dashboardBloc.add(const LoadDashboard(forceReload: true));

    // Also trigger refreshes for underlying data Blocs might rely on
    // (though DashboardBloc's stream listener should handle most cases)
    try {
      sl<AccountListBloc>().add(const LoadAccounts(forceReload: true));
      sl<ExpenseListBloc>().add(const LoadExpenses(forceReload: true));
      sl<IncomeListBloc>().add(const LoadIncomes(forceReload: true));
    } catch (e) {
      log.warning("Error triggering dependent Blocs refresh: $e");
    }

    // Wait for the dashboard bloc to finish loading
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

  // --- Helper Widgets for different UI Modes ---

  Widget _buildElementalQuantumDashboard(
      BuildContext context, FinancialOverview overview, bool isQuantum) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: isQuantum
            ? const EdgeInsets.all(8.0) // Tighter padding for Quantum
            : const EdgeInsets.all(16.0),
        children: [
          OverallBalanceCard(overview: overview),
          SizedBox(height: isQuantum ? 8 : 16),
          IncomeExpenseSummaryCard(overview: overview),
          SizedBox(height: isQuantum ? 8 : 16),
          // Conditional Chart/Table for Quantum
          if (isQuantum)
            _buildQuantumAssetTable(context, overview)
          else
            AssetDistributionPieChart(
                accountBalances: overview.accountBalances),

          SizedBox(height: isQuantum ? 16 : 24),
          if (!isQuantum) // Only show placeholder text in Elemental
            Center(
                child: Text("More insights coming soon!",
                    style: theme.textTheme.labelMedium)),
          // TODO: Add more Quantum-specific data widgets here if needed
        ],
      ),
    );
  }

  Widget _buildAetherDashboard(BuildContext context,
      SettingsState settingsState, FinancialOverview overview) {
    // TODO: Choose between Garden/Constellation based on settingsState.selectedThemeIdentifier
    // For now, default to Garden
    final String themeId = settingsState.selectedThemeIdentifier;

    if (themeId == AppTheme.aetherConstellationThemeId) {
      return PersonalConstellationWidget(overview: overview);
    } else {
      // Default to Garden
      return FinancialGardenWidget(overview: overview);
    }
  }

  Widget _buildQuantumAssetTable(
      BuildContext context, FinancialOverview overview) {
    final theme = Theme.of(context);
    final positiveBalances =
        overview.accounts.where((acc) => acc.currentBalance > 0).toList();
    final currencySymbol = context.read<SettingsBloc>().state.currencySymbol;

    // Simple table representation
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Quantum padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Asset Distribution (Table)',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.secondary),
              ),
            ),
            if (positiveBalances.isEmpty)
              const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text("No positive balances to display."),
              ))
            else
              DataTable(
                columnSpacing: 12,
                horizontalMargin: 8,
                headingRowHeight: 30,
                dataRowMinHeight: 35,
                dataRowMaxHeight: 40,
                columns: const [
                  DataColumn(label: Text('Account')),
                  DataColumn(label: Text('Balance'), numeric: true),
                ],
                rows: positiveBalances
                    .map((account) => DataRow(
                          cells: [
                            DataCell(Text(account.name,
                                overflow: TextOverflow.ellipsis)),
                            DataCell(Text(CurrencyFormatter.format(
                                account.currentBalance, currencySymbol))),
                          ],
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    log.info("[DashboardPage] Build method called.");
    final theme = Theme.of(context);
    // Also watch SettingsBloc to determine UI mode
    final settingsState = context.watch<SettingsBloc>().state;
    final uiMode = settingsState.uiMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Dashboard (${StringHelperExtension(uiMode.name).capitalize()})'), // Show mode in title
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDashboard,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocProvider.value(
        value: _dashboardBloc,
        child: BlocConsumer<DashboardBloc, DashboardState>(
          listener: (context, state) {
            log.info(
                "[DashboardPage] BlocListener received state: ${state.runtimeType}");
            if (state is DashboardError) {
              log.warning(
                  "[DashboardPage] Error state detected: ${state.message}");
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('Error loading dashboard: ${state.message}'),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
            }
          },
          builder: (context, state) {
            log.info(
                "[DashboardPage] BlocBuilder building for state: ${state.runtimeType}");
            Widget child;

            // Handle different states
            if (state is DashboardLoading && !state.isReloading) {
              log.info(
                  "[DashboardPage UI] State is initial DashboardLoading. Showing CircularProgressIndicator.");
              child = const Center(child: CircularProgressIndicator());
            } else if (state is DashboardLoaded ||
                (state is DashboardLoading && state.isReloading)) {
              log.info(
                  "[DashboardPage UI] State is DashboardLoaded or reloading. Building dashboard content for mode: $uiMode");
              final overview = (state is DashboardLoaded)
                  ? state.overview
                  : (_dashboardBloc.state as DashboardLoaded?)
                      ?.overview; // Use previous data if reloading

              if (overview == null) {
                // Should only happen briefly during initial reload?
                log.warning(
                    "[DashboardPage UI] Overview data is null during Loaded/Reloading state.");
                child = const Center(child: Text("Loading data..."));
              } else {
                // --- Conditional Rendering based on UI Mode ---
                switch (uiMode) {
                  case UIMode.quantum:
                    child = _buildElementalQuantumDashboard(
                        context, overview, true);
                    break;
                  case UIMode.aether:
                    child =
                        _buildAetherDashboard(context, settingsState, overview);
                    break;
                  case UIMode.elemental:
                  default:
                    child = _buildElementalQuantumDashboard(
                        context, overview, false);
                    break;
                }
                // --- End Conditional Rendering ---
              }
            } else if (state is DashboardError) {
              log.info(
                  "[DashboardPage UI] State is DashboardError: ${state.message}. Showing error UI.");
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
                        onPressed: _refreshDashboard, // Call the refresh method
                      )
                    ],
                  ),
                ),
              );
            } else {
              // Initial State
              log.info(
                  "[DashboardPage UI] State is Initial or Unknown. Showing loading indicator.");
              child = const Center(child: CircularProgressIndicator());
            }

            // Animate between child states (Root level for mode switching)
            return AnimatedSwitcher(
              duration:
                  const Duration(milliseconds: 400), // Slightly longer duration
              transitionBuilder: (Widget child, Animation<double> animation) {
                // Use fade transition for simplicity between modes
                return FadeTransition(opacity: animation, child: child);
              },
              child: child,
            );
          },
        ),
      ),
    );
  }
}

// Helper extension
extension StringHelperExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
