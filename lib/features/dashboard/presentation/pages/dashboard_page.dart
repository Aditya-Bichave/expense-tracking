// lib/features/dashboard/presentation/pages/dashboard_page.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/aether_themes/presentation/widgets/financial_garden_widget.dart';
import 'package:expense_tracker/features/aether_themes/presentation/widgets/personal_constellation_widget.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/asset_distribution_section.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/recent_transactions_section.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/budget_summary_widget.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/goal_summary_widget.dart';
import 'package:expense_tracker/features/dashboard/presentation/widgets/stitch/stitch_dashboard_body.dart';
// Removed Expense/Income entity imports as they are handled by TransactionEntity
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart'; // Import AppScaffold
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart'; // Import AppKitTheme

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
    final kit = context.kit;

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding:
            modeTheme?.pagePadding.copyWith(top: 8, bottom: 80) ??
            EdgeInsets.only(top: kit.spacing.sm, bottom: 80.0),
        children: [
          DashboardHeader(overview: overview),
          SizedBox(height: kit.spacing.sm),
          AssetDistributionSection(accountBalances: overview.accountBalances),
          SizedBox(height: kit.spacing.lg),
          BudgetSummaryWidget(
            budgets: overview.activeBudgetsSummary,
            recentSpendingData:
                overview.recentSpendingSparkline, // Pass correct data
          ),
          SizedBox(height: kit.spacing.lg),
          GoalSummaryWidget(
            goals: overview.activeGoalsSummary,
            // Pass correct data to the correct parameter
            recentContributionData: overview.recentContributionSparkline,
          ),
          SizedBox(height: kit.spacing.lg),
          _buildReportNavigationButtons(context),
          SizedBox(height: kit.spacing.lg),
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
    final kit = context.kit;
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
            padding:
                modeTheme?.pagePadding.copyWith(
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
              SizedBox(height: kit.spacing.lg),
              DashboardHeader(overview: overview),
              SizedBox(height: kit.spacing.lg),
              BudgetSummaryWidget(
                budgets: overview.activeBudgetsSummary,
                recentSpendingData:
                    overview.recentSpendingSparkline, // Pass correct data
              ),
              SizedBox(height: kit.spacing.lg),
              GoalSummaryWidget(
                goals: overview.activeGoalsSummary,
                recentContributionData:
                    overview.recentContributionSparkline, // Pass correct data
              ),
              SizedBox(height: kit.spacing.lg),
              _buildReportNavigationButtons(context),
              SizedBox(height: kit.spacing.lg),
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
    final theme = Theme.of(context); // Maintaining Theme.of for legacy chips for now, can migrate to Bridge later
    final kit = context.kit;

    return Padding(
      padding: kit.spacing.hSm,
      child: Wrap(
        spacing: kit.spacing.sm,
        runSpacing: kit.spacing.xs,
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
    final kit = context.kit;

    // Determine AppBar using Tokens/Theme where possible, or Bridge later
    PreferredSizeWidget? appBar;
    if (isAether) {
      appBar = AppBar(backgroundColor: Colors.transparent, elevation: 0);
    } else {
      appBar = AppBar(title: const Text("Dashboard"));
    }

    return AppScaffold(
      // extendBodyBehindAppBar: isAether, // AppScaffold doesn't support this yet, might need to wrap body manually or update AppScaffold.
      // Checking AppScaffold... it doesn't expose extendBodyBehindAppBar.
      // For now, if isAether, we might need a standard Scaffold or enhance AppScaffold.
      // Given constraints "Replace Scaffold with UiScaffold or Bridge equivalent", and if AppScaffold is strictly defined in ui_kit (cannot touch),
      // we must rely on AppScaffold features.
      // If AppScaffold doesn't support extending body, visual might break for Aether.
      // However, Aether mode seems to rely on Stack/Positioned background.
      // Let's use standard Scaffold for Aether if AppScaffold is insufficient, OR check if we can live without extendBodyBehindAppBar.
      // But wait, the instruction says "Replace Scaffold with UiScaffold (if available) OR preserve existing but replace internal widgets".
      // Since Aether requires specific Scaffold properties not in AppScaffold, I will conditionally use AppScaffold for non-Aether or standard Scaffold for Aether to preserve behavior.
      // actually, let's try to use AppScaffold and see if we can achieve the effect.
      // AppScaffold wraps body in SafeArea. Aether typically wants to go behind bars.
      // If I use AppScaffold, I lose extendBodyBehindAppBar.
      // Decision: For Aether mode (which seems highly custom/legacy styled), I will keep Scaffold to maintain "100% behavioral integrity".
      // For other modes, I will use AppScaffold.
      // Actually, looking at AppScaffold, it enforces SafeArea. Aether mode with background image usually wants to ignore SafeArea top.

      // Let's use Scaffold for Aether to be safe on behavioral integrity, and AppScaffold for others.
      // But the goal is "Migrate the UI layer".
      // If I can't touch AppScaffold, and it forces SafeArea, Aether might look clipped.
      // Let's stick to the plan: "Replace Scaffold with UiScaffold (if available) OR preserve existing but replace internal widgets".
      // I'll use AppScaffold for Quantum/Elemental/Stitch. Aether is "heavily customized", so "Replace only the styling parts. Preserve structure." applies.

      body: isAether
        ? Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
            body: _buildBody(context, uiMode, settingsState),
          )
        : AppScaffold(
            appBar: AppBar(title: Text("Dashboard", style: kit.typography.title)),
            body: _buildBody(context, uiMode, settingsState),
            safeAreaTop: true, // Default
          ),
    );
  }

  Widget _buildBody(BuildContext context, UIMode uiMode, SettingsState settingsState) {
    final theme = Theme.of(context);

    return BlocConsumer<DashboardBloc, DashboardState>(
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
                case UIMode.stitch:
                  bodyContent = StitchDashboardBody(
                    overview: overview,
                    navigateToDetailOrEdit: _navigateToDetailOrEdit,
                    onRefresh: _refreshDashboard,
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
      );
  }
}
