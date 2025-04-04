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
      case 2: // Budgets & Cats
        return isActive
            ? Icons.pie_chart_rounded
            : Icons.pie_chart_outline_rounded;
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
        return 'Budgets';
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
            leading: const Icon(Icons.post_add_rounded), // Generic Add icon
            title: const Text('Add Transaction'),
            onTap: () {
              Navigator.pop(context); // Close bottom sheet
              // --- Use new unified route ---
              context.pushNamed(RouteNames.addTransaction);
              log.info("[MainShell] Navigating to Add Transaction.");
              // --- End Use ---
            },
          ),
          // Remove separate Expense/Income options
          // ListTile(leading: ..., title: Text('Add Expense'), onTap: ...),
          // ListTile(leading: ..., title: Text('Add Income'), onTap: ...),
        ];
        break;
      case 2: // Budgets & Cats - Offer Add Category (Budget later)
        actions = [
          ListTile(
            leading: const Icon(Icons.create_new_folder_outlined),
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
      builder: (ctx) => Wrap(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10)),
          ),
          ...actions,
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navTheme = theme.bottomNavigationBarTheme;
    final currentTabIndex = navigationShell.currentIndex;
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
        showSelectedLabels: navTheme.showSelectedLabels,
        showUnselectedLabels: navTheme.showUnselectedLabels,
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
              heroTag: 'main_shell_fab',
              onPressed: () => _showAddActions(context, currentTabIndex),
              tooltip: 'Add',
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
