// lib/features/dashboard/presentation/pages/dashboard_page.dart
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
import 'package:flutter_svg/svg.dart';
import 'package:expense_tracker/core/assets/app_assets.dart'; // Import asset catalog

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
    // Ensure dependent Blocs are loaded if necessary (e.g., AccountListBloc)
    final accountBloc = sl<AccountListBloc>();
    if (accountBloc.state is AccountListInitial) {
      log.info(
          "[DashboardPage] AccountListBloc is initial, dispatching LoadAccounts.");
      accountBloc.add(const LoadAccounts());
    }
    final expenseBloc = sl<ExpenseListBloc>();
    if (expenseBloc.state is ExpenseListInitial) {
      expenseBloc.add(const LoadExpenses());
    }
    final incomeBloc = sl<IncomeListBloc>();
    if (incomeBloc.state is IncomeListInitial) {
      incomeBloc.add(const LoadIncomes());
    }
  }

  Future<void> _refreshDashboard() async {
    log.info("[DashboardPage] Pull-to-refresh triggered.");
    _dashboardBloc.add(const LoadDashboard(forceReload: true));
    // Also refresh dependent lists if needed, might already be handled by DataChangedEvent
    try {
      // Use context.read ONLY if you are sure the context is still valid in async gap
      // Using sl might be safer here if context validity is uncertain
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
    final uiMode = context.read<SettingsBloc>().state.uiMode; // Read once
    final modeTheme = context.modeTheme; // Read theme extension
    final bool isQuantum = uiMode == UIMode.quantum;
    final bool useTables = modeTheme?.preferDataTableForLists ?? false;

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(), // Ensure scrollable for refresh
        padding: const EdgeInsets.all(16.0),
        children: [
          OverallBalanceCard(overview: overview),
          const SizedBox(height: 16),
          IncomeExpenseSummaryCard(overview: overview),
          const SizedBox(height: 16),
          // Conditional asset display
          if (isQuantum && useTables)
            _buildQuantumAssetTable(context, overview.accountBalances)
          else if (!isQuantum) // Only show pie chart for Elemental
            AssetDistributionPieChart(accountBalances: overview.accountBalances)
          else // Quantum but useTables is false (shouldn't happen with current config)
            const SizedBox.shrink(),
          const SizedBox(height: 24),
          Center(
              child: Text("More insights coming soon!",
                  style: theme.textTheme.labelMedium)),
          const SizedBox(height: 80), // Padding at bottom for FAB
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
                  ? theme.colorScheme.tertiary // Use quantum colors
                  : theme.colorScheme.error,
              fontWeight: FontWeight.w500),
          textAlign: TextAlign.end,
        )), // Balance
      ]);
    }).toList();

    if (rows.isEmpty) {
      return Card(
        // Use Card consistent with Quantum theme
        margin: theme.cardTheme.margin,
        shape: theme.cardTheme.shape,
        elevation: theme.cardTheme.elevation,
        color: theme.cardTheme.color,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
              child: Text('No accounts added yet.',
                  style: TextStyle(fontStyle: FontStyle.italic))),
        ),
      );
    }

    return Card(
      // Wrap table in a card for consistency
      margin: theme.cardTheme.margin,
      shape: theme.cardTheme.shape,
      elevation: theme.cardTheme.elevation,
      color: theme.cardTheme.color,
      clipBehavior: theme.cardTheme.clipBehavior ?? Clip.none,
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
                columnSpacing: theme.dataTableTheme.columnSpacing ?? 12,
                headingRowHeight: theme.dataTableTheme.headingRowHeight ?? 36,
                dataRowMinHeight: theme.dataTableTheme.dataRowMinHeight ?? 36,
                dataRowMaxHeight: theme.dataTableTheme.dataRowMaxHeight ?? 40,
                headingTextStyle: theme.dataTableTheme.headingTextStyle ??
                    theme.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                dataTextStyle: theme.dataTableTheme.dataTextStyle ??
                    theme.textTheme.bodySmall,
                dividerThickness: theme.dataTableTheme.dividerThickness,
                dataRowColor: theme.dataTableTheme.dataRowColor,
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

  // Specific Widget Builder for Aether Dashboard Body
  Widget _buildAetherDashboardBody(
      BuildContext context, FinancialOverview overview) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;
    final paletteId = context.watch<SettingsBloc>().state.paletteIdentifier;

    // Choose Aether widget based on palette ID convention
    Widget aetherContent;
    if (paletteId == AppTheme.aetherPalette2) {
      // Garden
      aetherContent = const FinancialGardenWidget(); // Placeholder
    } else {
      // Starfield, Mystic, CalmSky or Default Aether
      aetherContent = const PersonalConstellationWidget(); // Placeholder
    }

    // Example structure: Background + Content + Refresh
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: Stack(
        // Use stack for background
        children: [
          // Background based on theme extension
          if (modeTheme?.assets.mainBackgroundDark != null) // Check if defined
            Positioned.fill(
              child: SvgPicture.asset(
                modeTheme!
                    .assets.mainBackgroundDark!, // Use ! because we checked
                fit: BoxFit.cover,
              ),
            ),
          // Actual content on top
          ListView(
            // Make content scrollable for refresh
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              aetherContent,
              // Add other common Aether elements if needed
              const SizedBox(height: 80), // Padding for FAB if applicable
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
    final uiMode = context.watch<SettingsBloc>().state.uiMode; // Watch UI mode
    // final modeTheme = context.modeTheme; // Get theme extension

    return Scaffold(
      // Aether might have a transparent AppBar or none
      appBar: uiMode == UIMode.aether
          ? null // Aether themes might handle app bar internally or not have one
          : AppBar(
              title: const Text('Dashboard'),
              actions: [
                IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshDashboard,
                    tooltip: 'Refresh')
              ],
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
          Widget bodyContent; // Use a variable for the main body content

          if (state is DashboardLoading && !state.isReloading) {
            bodyContent = const Center(child: CircularProgressIndicator());
          } else if (state is DashboardLoaded ||
              (state is DashboardLoading && state.isReloading)) {
            final overview = (state is DashboardLoaded)
                ? state.overview
                : (context.read<DashboardBloc>().state as DashboardLoaded?)
                    ?.overview;

            if (overview == null) {
              // This might happen briefly during a forced reload before data is ready
              bodyContent = const Center(child: Text("Loading data..."));
            } else {
              // --- UI Mode Specific Body ---
              switch (uiMode) {
                case UIMode.aether:
                  bodyContent = _buildAetherDashboardBody(context, overview);
                  break;
                case UIMode.quantum:
                case UIMode.elemental:
                default: // Fallback to elemental/quantum style
                  bodyContent =
                      _buildElementalQuantumDashboard(context, overview);
                  break;
              }
              // --- End UI Mode Specific Body ---
            }
          } else if (state is DashboardError) {
            bodyContent = Center(
              // Error UI
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
            // Initial state
            bodyContent = const Center(child: CircularProgressIndicator());
          }

          // Apply background *outside* the switch, only if not Aether (Aether handles its own bg)
          // This assumes Elemental/Quantum might have a global background set via scaffold
          // If Elemental/Quantum also use Stack+SvgPicture, adjust accordingly.
          if (uiMode != UIMode.aether) {
            // Example: Apply a generic background for non-Aether modes if needed
            // final modeTheme = context.modeTheme;
            // String? bgPath = theme.brightness == Brightness.dark
            //     ? modeTheme?.assets.mainBackgroundDark
            //     : modeTheme?.assets.mainBackgroundLight;
            // if (bgPath != null && bgPath.isNotEmpty) {
            //      return Stack(children: [ Positioned.fill(child: SvgPicture.asset(bgPath, fit: BoxFit.cover)), bodyContent ]);
            // }
          }

          // Return the constructed body content (Aether includes its background, others might not)
          return AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child:
                  bodyContent // Key ensures animation triggers on state change
              );
        },
      ),
      // FAB might be needed for some modes but not others? Add conditionally.
      // floatingActionButton: uiMode != UIMode.aether ? FloatingActionButton(...) : null,
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
