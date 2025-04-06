// lib/main_shell.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/main.dart'; // Import logger

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

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
      case 4: // Settings
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

    // --- FIX: Show FAB only for specific tabs (0, 1, 3) ---
    final bool showFab =
        currentTabIndex == 0 || currentTabIndex == 1 || currentTabIndex == 3;
    // --- END FIX ---

    return Scaffold(
      body: navigationShell,
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
        items: List.generate(5, (index) {
          final isActive = index == navigationShell.currentIndex;
          return BottomNavigationBarItem(
            icon: Icon(_getIconForIndex(index, false)),
            activeIcon: Icon(_getIconForIndex(index, true)),
            label: _getLabelForIndex(index),
          );
        }),
      ),
      floatingActionButton: showFab
          ? FloatingActionButton(
              heroTag: 'main_shell_fab', // Keep a unique tag
              onPressed: () {
                // Simplified navigation based on allowed tabs
                switch (currentTabIndex) {
                  case 0: // Dashboard -> Add Transaction
                  case 1: // Transactions -> Add Transaction
                    context.pushNamed(RouteNames.addTransaction);
                    log.info(
                        "[MainShell FAB] Navigating to Add Transaction from tab $currentTabIndex.");
                    break;
                  case 3: // Accounts -> Add Account
                    context.pushNamed(RouteNames.addAccount);
                    log.info(
                        "[MainShell FAB] Navigating to Add Account from tab $currentTabIndex.");
                    break;
                }
              },
              tooltip: 'Add',
              child: const Icon(Icons.add),
            )
          : null, // No FAB for Plan or Settings tab in the shell
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
