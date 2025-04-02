import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart'; // Ensure this is imported
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
    _dashboardBloc = sl<DashboardBloc>();
    // Dispatch initial load event
    _dashboardBloc.add(const LoadDashboard()); // Use const if no params

    // Optional: Add listeners to other Blocs if dashboard needs live updates
    // without manual refresh, though pull-to-refresh is often sufficient.
  }

  // Function to handle manual refresh
  Future<void> _refreshDashboard() async {
    // Dispatch load event for the dashboard
    _dashboardBloc.add(const LoadDashboard()); // Use const if no params

    // Optionally trigger refreshes for underlying data sources if dashboard relies on them
    try {
      sl<AccountListBloc>().add(LoadAccounts());
      sl<ExpenseListBloc>()
          .add(LoadExpenses()); // Or LoadExpensesWithFilter if needed
      sl<IncomeListBloc>().add(LoadIncomes());
    } catch (e) {
      // Handle cases where other Blocs might not be registered yet or fail
      debugPrint("Error refreshing dependent Blocs: $e");
      // Optionally show a less critical error message
    }
    // No need for artificial delay, RefreshIndicator handles UI feedback
  }

  @override
  void dispose() {
    // Avoid Bloc leaks if the Bloc was created here, but since we use sl,
    // the service locator manages its lifecycle. Closing is usually handled there.
    // If sl doesn't manage closing, you might need: _dashboardBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      // Use BlocProvider.value as the BLoC is obtained from sl and reused
      body: BlocProvider.value(
        value: _dashboardBloc,
        child: BlocConsumer<DashboardBloc, DashboardState>(
          listener: (context, state) {
            if (state is DashboardError) {
              // Avoid showing snackbar if error widget is already shown in builder
              // You might want one or the other, or only for specific errors.
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(
              //     content: Text('Error loading dashboard: ${state.message}'),
              //     backgroundColor: Theme.of(context).colorScheme.error,
              //   ),
              // );
            }
          },
          builder: (context, state) {
            // Handle Loading State
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            // Handle Loaded State
            else if (state is DashboardLoaded) {
              // Access data via state.overview (NOT state.financialOverview)
              final FinancialOverview overview = state.overview;

              return RefreshIndicator(
                onRefresh: _refreshDashboard,
                child: ListView(
                  // Ensure scroll physics allow refresh even when content fits screen
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Pass the 'overview' object to the relevant cards
                    OverallBalanceCard(overview: overview),
                    const SizedBox(height: 16),
                    IncomeExpenseSummaryCard(overview: overview),
                    const SizedBox(height: 16),

                    // Use the accountBalances map for the pie chart
                    if (overview.accountBalances.entries.any(
                        (e) => e.value > 0)) // Check for any positive balance
                      AssetDistributionPieChart(
                          accountBalances: overview.accountBalances)
                    else
                      const Card(
                          // Placeholder if no positive balances
                          child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                  child: Text(
                                      "No positive asset balances to chart.")))),

                    // Placeholder for future widgets
                    const SizedBox(height: 20),
                    Center(
                        child: Text("More insights coming soon!",
                            style: Theme.of(context).textTheme.labelMedium)),
                  ],
                ),
              );
            }
            // Handle Error State
            else if (state is DashboardError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          color: Theme.of(context).colorScheme.error, size: 50),
                      const SizedBox(height: 16),
                      Text('Failed to load dashboard:',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: _refreshDashboard,
                      )
                    ],
                  ),
                ),
              );
            }
            // Handle Initial State (or any other unhandled state)
            return const Center(
                child: CircularProgressIndicator()); // Default/Initial view
          },
        ),
      ),
    );
  }
}
