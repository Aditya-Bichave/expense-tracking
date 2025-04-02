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
      // The body will display the widget based on the current active branch
      // defined in the StatefulShellRoute.
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex, // Highlight the active tab
        onTap: (index) => _onTap(context, index), // Handle tab selection
        // Use 'fixed' to ensure all labels are visible, good for 4-5 items.
        // Use 'shifting' for animation effect if desired (usually better for <= 3 items).
        type: BottomNavigationBarType.fixed,
        // Optional: Customize colors
        // selectedItemColor: Theme.of(context).colorScheme.primary,
        // unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined), // Icon when inactive
            activeIcon: Icon(Icons.dashboard), // Icon when active
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons
                .account_balance_wallet_outlined), // Changed to match Income
            activeIcon:
                Icon(Icons.account_balance_wallet), // Changed to match Income
            label: 'Income', // Label is Income
          ),
          BottomNavigationBarItem(
            icon: Icon(
                Icons.account_balance_outlined), // Changed to match Accounts
            activeIcon:
                Icon(Icons.account_balance), // Changed to match Accounts
            label: 'Accounts',
          ),
        ],
      ),
    );
  }
}
