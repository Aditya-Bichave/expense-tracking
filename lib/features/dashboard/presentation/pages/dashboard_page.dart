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

  @override
  Widget build(BuildContext context) {
    log.info("[DashboardPage] build method called.");
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
                  "[DashboardPage UI] State is DashboardLoaded or reloading. Building dashboard content.");
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
                child = RefreshIndicator(
                  onRefresh: _refreshDashboard,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      OverallBalanceCard(overview: overview),
                      const SizedBox(height: 16),
                      IncomeExpenseSummaryCard(overview: overview),
                      const SizedBox(height: 16),
                      // Filter balances for the chart here if not done in UseCase
                      AssetDistributionPieChart(
                        accountBalances: overview.accountBalances,
                      ),
                      const SizedBox(height: 24),
                      Center(
                          child: Text("More insights coming soon!",
                              style: theme.textTheme.labelMedium)),
                    ],
                  ),
                );
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

            // Animate between child states
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: child,
            );
          },
        ),
      ),
    );
  }
}
