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
      case 2: // Budgets & Cats & Goals (Unified Icon)
        return isActive
            ? Icons.savings_rounded
            : Icons.savings_outlined; // Example: Savings icon
      // Or keep pie chart:
      // return isActive ? Icons.pie_chart_rounded : Icons.pie_chart_outline_rounded;
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
        return 'Plan'; // Unified name for Budgets/Goals/Cats tab
      case 3:
        return 'Accounts';
      case 4:
        return 'Settings';
      default:
        return '';
    }
  }

  // Helper to show context-aware add actions
  void _showAddActions(BuildContext context, int currentIndex) {
    log.info(
        "[MainShell] FAB pressed on tab index: $currentIndex. Showing actions.");
    List<Widget> actions = [];

    switch (currentIndex) {
      case 0: // Dashboard - Offer Quick Add Transaction
      case 1: // Transactions - Offer Add Transaction
        actions = [
          ListTile(
            leading: const Icon(Icons.post_add_rounded),
            title: const Text('Add Transaction'),
            onTap: () {
              Navigator.pop(context); // Close bottom sheet
              context.pushNamed(RouteNames.addTransaction);
              log.info("[MainShell] Navigating to Add Transaction.");
            },
          ),
        ];
        break;

      // --- FIX: Updated actions for Tab Index 2 ---
      case 2: // Plan Tab (Budgets/Goals/Cats)
        actions = [
          ListTile(
            leading: const Icon(Icons.pie_chart_outline_rounded), // Budget icon
            title: const Text('Add Budget'),
            onTap: () {
              Navigator.pop(context); // Close bottom sheet
              context.pushNamed(RouteNames.addBudget); // Navigate to add budget
              log.info("[MainShell] Navigating to Add Budget.");
            },
          ),
          ListTile(
            leading: const Icon(Icons.savings_outlined), // Goal icon
            title: const Text('Add Goal'),
            onTap: () {
              Navigator.pop(context); // Close bottom sheet
              context.pushNamed(RouteNames.addGoal); // Navigate to add goal
              log.info("[MainShell] Navigating to Add Goal.");
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.create_new_folder_outlined), // Category icon
            title: const Text('Add Category'),
            onTap: () {
              Navigator.pop(context); // Close bottom sheet
              // Navigate using the route path defined in router.dart
              context.push(
                  '${RouteNames.budgetsAndCats}/${RouteNames.manageCategories}/${RouteNames.addCategory}');
              log.info("[MainShell] Navigating to Add Category.");
            },
          ),
        ];
        break;
      // --- END FIX ---

      case 3: // Accounts - Offer Add Account
        actions = [
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Add Asset Account'),
            onTap: () {
              Navigator.pop(context); // Close bottom sheet
              context.pushNamed(RouteNames.addAccount);
              log.info("[MainShell] Navigating to Add Account.");
            },
          ),
        ];
        break;
      case 4: // Settings - No default add action
      default:
        log.info("[MainShell] No specific FAB actions for tab $currentIndex.");
        return; // Don't show the sheet if no actions
    }

    // Show the modal bottom sheet
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        // Add SafeArea
        child: Wrap(
          children: [
            // Drag Handle
            Center(
              // Center the handle
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            ...actions,
            const SizedBox(height: 8), // Reduced bottom padding
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = theme.bottomNavigationBarTheme;
    final currentTabIndex = navigationShell.currentIndex;
    // Show FAB on all tabs except Settings (index 4)
    final bool showFab = currentTabIndex != 4;

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
        showSelectedLabels:
            navTheme.showSelectedLabels ?? true, // Default to true
        showUnselectedLabels:
            navTheme.showUnselectedLabels ?? true, // Default to true
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
      // --- FIX: FAB is now displayed based on `showFab` ---
      floatingActionButton: showFab
          ? FloatingActionButton(
              heroTag: 'main_shell_fab',
              onPressed: () => _showAddActions(context, currentTabIndex),
              tooltip: 'Add',
              child: const Icon(Icons.add),
            )
          : null,
      // --- END FIX ---
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
