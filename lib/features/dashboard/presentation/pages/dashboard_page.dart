// lib/features/dashboard/presentation/pages/dashboard_page.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/aether_themes/presentation/widgets/financial_garden_widget.dart';
import 'package:expense_tracker/features/aether_themes/presentation/widgets/personal_constellation_widget.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/net_worth_card.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/net_worth_composition_widget.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/recent_transactions_section.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/budget_summary_widget.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/goal_summary_widget.dart';
// Removed Expense/Income entity imports as they are handled by TransactionEntity
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

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
    _dashboardBloc = BlocProvider.of<DashboardBloc>(context);
  }

  Future<void> _refreshDashboard() async {
    log.info("[DashboardPage] Pull-to-refresh triggered.");
    _dashboardBloc.add(const LoadDashboard(forceReload: true));

    try {
      // Wait for dashboard bloc to finish loading/erroring
      await _dashboardBloc.stream
          .firstWhere(
            (state) => state is DashboardLoaded || state is DashboardError,
          )
          .timeout(const Duration(seconds: 10));
      log.info("[DashboardPage] Refresh stream finished or timed out.");
    } catch (e) {
      log.warning(
        "[DashboardPage] Error or timeout waiting for refresh stream: $e",
      );
    }
  }

  void _navigateToDetailOrEdit(
    BuildContext context,
    TransactionEntity transaction,
  ) {
    log.info(
      "[DashboardPage] Navigate to Edit requested for TXN ID: ${transaction.id}",
    );
    const String routeName = RouteNames.editTransaction;
    final Map<String, String> params = {
      RouteNames.paramTransactionId: transaction.id,
    };
    context.pushNamed(routeName, pathParameters: params, extra: transaction);
  }

  Widget _buildElementalQuantumDashboard(
    BuildContext context,
    FinancialOverview overview,
    SettingsState settings,
  ) {
    final modeTheme = context.modeTheme;
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: modeTheme?.pagePadding.copyWith(top: 8, bottom: 80) ??
            const EdgeInsets.only(top: 8.0, bottom: 80.0),
        children: [
          NetWorthCard(overview: overview),
          const SizedBox(height: 8),
          NetWorthComposition(overview: overview),
          const SizedBox(height: 16),
          BudgetSummaryWidget(
            budgets: overview.activeBudgetsSummary,
            recentSpendingData:
                overview.recentSpendingSparkline, // Pass correct data
          ),
          const SizedBox(height: 16),
          GoalSummaryWidget(
            goals: overview.activeGoalsSummary,
            // Pass correct data to the correct parameter
            recentContributionData: overview.recentContributionSparkline,
          ),
          const SizedBox(height: 16),
          _buildReportNavigationButtons(context),
          const SizedBox(height: 16),
          RecentTransactionsSection(
            navigateToDetailOrEdit: _navigateToDetailOrEdit,
          ),
        ],
      ),
    );
  }

  Widget _buildAetherDashboardBody(
    BuildContext context,
    FinancialOverview overview,
    SettingsState settings,
  ) {
    final modeTheme = context.modeTheme;
    final paletteId = settings.paletteIdentifier;
    Widget aetherContent = (paletteId == AppTheme.aetherPalette2)
        ? const FinancialGardenWidget()
        : const PersonalConstellationWidget();

    final String? bgPath = Theme.of(context).brightness == Brightness.dark
        ? modeTheme?.assets.mainBackgroundDark
        : modeTheme?.assets.mainBackgroundLight;

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: Stack(
        children: [
          if (bgPath != null && bgPath.isNotEmpty)
            Positioned.fill(child: SvgPicture.asset(bgPath, fit: BoxFit.cover)),
          ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: modeTheme?.pagePadding.copyWith(
                  top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
                  bottom: 80,
                ) ??
                EdgeInsets.only(
                  top:
                      kToolbarHeight + MediaQuery.of(context).padding.top + 8.0,
                  bottom: 80.0,
                ),
            children: [
              Container(
                height: 300,
                alignment: Alignment.center,
                child: aetherContent,
              ),
              const SizedBox(height: 16),
              NetWorthCard(overview: overview),
              const SizedBox(height: 16),
              BudgetSummaryWidget(
                budgets: overview.activeBudgetsSummary,
                recentSpendingData:
                    overview.recentSpendingSparkline, // Pass correct data
              ),
              const SizedBox(height: 16),
              GoalSummaryWidget(
                goals: overview.activeGoalsSummary,
                recentContributionData:
                    overview.recentContributionSparkline, // Pass correct data
              ),
              const SizedBox(height: 16),
              _buildReportNavigationButtons(context),
              const SizedBox(height: 16),
              RecentTransactionsSection(
                navigateToDetailOrEdit: _navigateToDetailOrEdit,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportNavigationButtons(BuildContext context) {
    // ... (implementation unchanged) ...
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        alignment: WrapAlignment.center,
        children: [
          ActionChip(
            key: const ValueKey('button_dashboard_to_spendingCategoryReport'),
            avatar: Icon(
              Icons.pie_chart_outline,
              size: 16,
              color: theme.colorScheme.secondary,
            ),
            label: Text('Spending / Cat', style: theme.textTheme.labelSmall),
            onPressed: () => context.push(
              '${RouteNames.dashboard}/${RouteNames.reportSpendingCategory}',
            ),
            visualDensity: VisualDensity.compact,
          ),
          ActionChip(
            key: const ValueKey('button_dashboard_to_spendingTimeReport'),
            avatar: Icon(
              Icons.timeline_outlined,
              size: 16,
              color: theme.colorScheme.secondary,
            ),
            label: Text('Spending / Time', style: theme.textTheme.labelSmall),
            onPressed: () => context.push(
              '${RouteNames.dashboard}/${RouteNames.reportSpendingTime}',
            ),
            visualDensity: VisualDensity.compact,
          ),
          ActionChip(
            key: const ValueKey('button_dashboard_to_incomeExpenseReport'),
            avatar: Icon(
              Icons.compare_arrows_outlined,
              size: 16,
              color: theme.colorScheme.secondary,
            ),
            label: Text(
              AppLocalizations.of(context)!.incomeVsExpense,
              style: theme.textTheme.labelSmall,
            ),
            onPressed: () => context.push(
              '${RouteNames.dashboard}/${RouteNames.reportIncomeExpense}',
            ),
            visualDensity: VisualDensity.compact,
          ),
          ActionChip(
            key: const ValueKey('button_dashboard_to_budgetPerformanceReport'),
            avatar: Icon(
              Icons.assignment_turned_in_outlined,
              size: 16,
              color: theme.colorScheme.secondary,
            ),
            label: Text('Budget Perf.', style: theme.textTheme.labelSmall),
            onPressed: () => context.push(
              '${RouteNames.dashboard}/${RouteNames.reportBudgetPerformance}',
            ),
            visualDensity: VisualDensity.compact,
          ),
          ActionChip(
            key: const ValueKey('button_dashboard_to_goalProgressReport'),
            avatar: Icon(
              Icons.track_changes_outlined,
              size: 16,
              color: theme.colorScheme.secondary,
            ),
            label: Text('Goal Progress', style: theme.textTheme.labelSmall),
            onPressed: () => context.push(
              '${RouteNames.dashboard}/${RouteNames.reportGoalProgress}',
            ),
            visualDensity: VisualDensity.compact,
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
    final isAether = uiMode == UIMode.aether;

    return Scaffold(
      extendBodyBehindAppBar: isAether,
      appBar: isAether
          ? AppBar(backgroundColor: Colors.transparent, elevation: 0)
          : AppBar(title: const Text("Dashboard")),
      body: BlocConsumer<DashboardBloc, DashboardState>(
        listener: (context, state) {
          if (state is DashboardError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text("Dashboard Error: ${state.message}"),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
          }
        },
        builder: (context, state) {
          log.fine(
            "[DashboardPage] BlocBuilder building for state: ${state.runtimeType}",
          );
          Widget bodyContent;

          if (state is DashboardLoading && !state.isReloading) {
            bodyContent = const Center(child: CircularProgressIndicator());
          } else if (state is DashboardLoaded ||
              (state is DashboardLoading && state.isReloading)) {
            final overview = (state is DashboardLoaded)
                ? state.overview
                : (context.read<DashboardBloc>().state as DashboardLoaded?)
                    ?.overview; // Use previous data if reloading
            if (overview == null && state is DashboardLoading) {
              bodyContent = const Center(
                child: CircularProgressIndicator(),
              ); // Still loading initial data
            } else if (overview == null) {
              bodyContent = const Center(
                child: Text("Failed to load overview data."),
              ); // Error case if overview somehow null after loading
            } else {
              switch (uiMode) {
                case UIMode.aether:
                  bodyContent = _buildAetherDashboardBody(
                    context,
                    overview,
                    settingsState,
                  );
                  break;
                case UIMode.quantum:
                case UIMode.elemental:
                  bodyContent = _buildElementalQuantumDashboard(
                    context,
                    overview,
                    settingsState,
                  );
                  break;
              }
            }
          } else if (state is DashboardError) {
            bodyContent = Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error loading dashboard: ${state.message}',
                      style: TextStyle(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      key: const ValueKey('button_dashboard_retry'),
                      onPressed: _refreshDashboard,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Initial state
            bodyContent = const Center(child: CircularProgressIndicator());
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: KeyedSubtree(
              key: ValueKey(state.runtimeType.toString() + uiMode.toString()),
              child: bodyContent,
            ),
          );
        },
      ),
    );
  }
}
