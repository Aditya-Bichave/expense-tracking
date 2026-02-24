// lib/main_shell.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/widgets/demo_indicator_widget.dart'; // Import Demo Indicator
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:flutter_bloc/flutter_bloc.dart'; // Import bloc
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import SettingsBloc

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  // Function to handle tapping on the BottomNavigationBar items
  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  // Helper to get the icon for each tab index
  IconData _getIconForIndex(int index, bool isActive) {
    switch (index) {
      case 0: // Dashboard
        return isActive ? Icons.dashboard_rounded : Icons.dashboard_outlined;
      case 1: // Transactions
        return isActive
            ? Icons.receipt_long_rounded
            : Icons.receipt_long_outlined;
      case 2: // Plan (Budgets/Goals)
        return isActive ? Icons.savings_rounded : Icons.savings_outlined;
      case 3: // Accounts
        return isActive
            ? Icons.account_balance_wallet_rounded
            : Icons.account_balance_wallet_outlined;
      case 4: // Recurring
        return isActive ? Icons.autorenew_rounded : Icons.autorenew_outlined;
      case 5: // Settings
        return isActive ? Icons.settings_rounded : Icons.settings_outlined;
      default:
        return Icons.help_outline; // Fallback
    }
  }

  // Helper to get the label for each tab index
  String _getLabelForIndex(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Transactions';
      case 2:
        return 'Plan';
      case 3:
        return 'Accounts';
      case 4:
        return 'Recurring';
      case 5:
        return 'Settings';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = theme.bottomNavigationBarTheme;
    final currentTabIndex = navigationShell.currentIndex;
    // --- Check Demo Mode State ---
    // Trigger rebuild when demo mode changes
    context.watch<SettingsBloc>().state.isInDemoMode;
    // --- End Check ---

    final bool showFab =
        (currentTabIndex == 0 || // Dashboard
        currentTabIndex == 1 || // Transactions
        currentTabIndex == 3 || // Accounts
        currentTabIndex == 4); // Recurring

    return Scaffold(
      // --- Wrap body with DemoIndicatorWidget ---
      body: Stack(
        children: [
          // Main Content
          navigationShell,
          // Demo Indicator Overlay
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: DemoIndicatorWidget(),
          ),
        ],
      ),
      // --- End Wrap ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTabIndex,
        onTap: (index) => _onTap(context, index),
        type: navTheme.type ?? BottomNavigationBarType.fixed,
        backgroundColor: navTheme.backgroundColor,
        selectedItemColor:
            navTheme.selectedItemColor ?? theme.colorScheme.primary,
        unselectedItemColor:
            navTheme.unselectedItemColor ?? theme.colorScheme.onSurfaceVariant,
        selectedLabelStyle: navTheme.selectedLabelStyle,
        unselectedLabelStyle: navTheme.unselectedLabelStyle,
        selectedIconTheme: navTheme.selectedIconTheme,
        unselectedIconTheme: navTheme.unselectedIconTheme,
        showSelectedLabels: navTheme.showSelectedLabels ?? true,
        showUnselectedLabels: navTheme.showUnselectedLabels ?? true,
        elevation: navTheme.elevation ?? 8.0,
        items: List.generate(6, (index) {
          return BottomNavigationBarItem(
            icon: Icon(_getIconForIndex(index, false)),
            activeIcon: Icon(_getIconForIndex(index, true)),
            label: _getLabelForIndex(index),
          );
        }),
      ),
      floatingActionButton: showFab
          ? FloatingActionButton(
              heroTag: 'main_shell_fab',
              onPressed: () {
                // --- Adjusted FAB navigation based on tab ---
                switch (currentTabIndex) {
                  case 0: // Dashboard -> Add Transaction
                  case 1: // Transactions -> Add Transaction
                    log.info(
                      "[MainShell FAB] Navigating to Add Transaction from tab $currentTabIndex.",
                    );
                    context.push(
                      '${RouteNames.transactionsList}/${RouteNames.addTransaction}',
                    ); // Use full path relative to shell
                    break;
                  case 3: // Accounts -> Add Account
                    log.info(
                      "[MainShell FAB] Navigating to Add Account from tab $currentTabIndex.",
                    );
                    context.push(
                      '${RouteNames.accounts}/${RouteNames.addAccount}',
                    ); // Use full path relative to shell
                    break;
                  case 4: // Recurring -> Add Recurring
                    log.info(
                      "[MainShell FAB] Navigating to Add Recurring from tab $currentTabIndex.",
                    );
                    context.push(
                      '${RouteNames.recurring}/${RouteNames.addRecurring}',
                    ); // Use full path relative to shell
                    break;
                  default:
                    return; // Should not happen if showFab is false for other tabs
                }
              },
              tooltip: 'Add',
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
