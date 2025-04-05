// lib/features/dashboard/presentation/pages/dashboard_page.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/aether_themes/presentation/widgets/financial_garden_widget.dart';
import 'package:expense_tracker/features/aether_themes/presentation/widgets/personal_constellation_widget.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
// Import decomposed widgets
import 'package:expense_tracker/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/asset_distribution_section.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/recent_transactions_section.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/budget_summary_widget.dart'; // ADDED
import 'package:expense_tracker/features/dashboard/presentation/widgets/goal_summary_widget.dart'; // ADDED
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
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
  late SettingsBloc _settingsBloc;

  @override
  void initState() {
    super.initState();
    log.info("[DashboardPage] initState called.");
    _dashboardBloc = BlocProvider.of<DashboardBloc>(context);
    _settingsBloc = BlocProvider.of<SettingsBloc>(context);
    _ensureBlocLoaded<AccountListBloc>(() => const LoadAccounts());
    _ensureBlocLoaded<TransactionListBloc>(() => const LoadTransactions());
  }

  void _ensureBlocLoaded<T extends Bloc>(Function eventCreator) {
    try {
      final bloc = BlocProvider.of<T>(context);
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
    _dashboardBloc.add(const LoadDashboard(forceReload: true));
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

  void _navigateToDetailOrEdit(
      BuildContext context, TransactionEntity transaction) {
    log.info(
        "[DashboardPage] Navigate to Edit requested for TXN ID: ${transaction.id}");
    const String routeName = RouteNames.editTransaction;
    final Map<String, String> params = {
      RouteNames.paramTransactionId: transaction.id
    };
    final dynamic extraData = transaction.originalEntity;
    if (extraData == null) {
      log.severe(
          "[DashboardPage] CRITICAL: originalEntity is null for transaction ID ${transaction.id}. Cannot navigate.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Error preparing edit data."),
          backgroundColor: Colors.red));
      return;
    }
    context.pushNamed(routeName, pathParameters: params, extra: extraData);
  }

  // --- Dashboard Build Logic ---

  Widget _buildElementalQuantumDashboard(BuildContext context,
      FinancialOverview overview, SettingsState settings) {
    final modeTheme = context.modeTheme;
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: modeTheme?.pagePadding.copyWith(top: 8, bottom: 80) ??
            const EdgeInsets.only(top: 8.0, bottom: 80.0),
        children: [
          // Use the decomposed header widget
          DashboardHeader(overview: overview),
          const SizedBox(height: 8), // Spacing after header

          // Use the decomposed asset distribution widget
          AssetDistributionSection(accountBalances: overview.accountBalances),
          const SizedBox(height: 16), // Increase spacing
          // --- ADDED Budget & Goal Summaries ---
          BudgetSummaryWidget(budgets: overview.activeBudgetsSummary),
          const SizedBox(height: 16),
          GoalSummaryWidget(goals: overview.activeGoalsSummary),
          const SizedBox(height: 16),
          // --- END Summaries ---

          // Use the decomposed recent transactions widget
          RecentTransactionsSection(
              navigateToDetailOrEdit: _navigateToDetailOrEdit),
        ],
      ),
    );
  }

  Widget _buildAetherDashboardBody(BuildContext context,
      FinancialOverview overview, SettingsState settings) {
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
          if (modeTheme?.assets.mainBackgroundDark != null &&
              modeTheme!.assets.mainBackgroundDark!.isNotEmpty)
            Positioned.fill(
                child: SvgPicture.asset(modeTheme.assets.mainBackgroundDark!,
                    fit: BoxFit.cover)),
          ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: modeTheme?.pagePadding.copyWith(top: 8, bottom: 80) ??
                const EdgeInsets.only(top: 8.0, bottom: 80.0), // Themed padding
            children: [
              Container(
                  height: 300,
                  alignment: Alignment.center,
                  child: aetherContent),
              const SizedBox(height: 16),
              // Use the decomposed header widget
              DashboardHeader(overview: overview),
              const SizedBox(height: 16),
              // --- ADDED Budget & Goal Summaries ---
              BudgetSummaryWidget(budgets: overview.activeBudgetsSummary),
              const SizedBox(height: 16),
              GoalSummaryWidget(goals: overview.activeGoalsSummary),
              const SizedBox(height: 16),
              // --- END Summaries ---
              // Use the decomposed recent transactions widget
              RecentTransactionsSection(
                  navigateToDetailOrEdit: _navigateToDetailOrEdit),
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
    );
  }
}
