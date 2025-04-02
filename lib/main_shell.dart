import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  // Function to handle tapping on the BottomNavigationBar items
  void _onTap(BuildContext context, int index) {
    // Use the navigationShell to navigate to the corresponding branch (page)
    // The index parameter corresponds to the branch index in the StatefulShellRoute
    navigationShell.goBranch(
      index,
      // If tapping the same item again, should it reset the navigation stack?
      // Setting initialLocation to true resets the stack, false preserves it.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body displays the widget based on the current active branch
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex, // Highlight the active tab
        onTap: (index) => _onTap(context, index), // Handle tab selection
        type: BottomNavigationBarType.fixed, // Ensures all labels are visible
        // Use theme colors for better consistency
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            // Using a suitable icon for Income
            icon: Icon(Icons.trending_up_outlined),
            activeIcon: Icon(Icons.trending_up),
            label: 'Income',
          ),
          BottomNavigationBarItem(
            // Using a suitable icon for Accounts
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Accounts',
          ),
          // --- Settings Item ---
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
