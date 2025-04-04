import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/constants/route_names.dart'; // Import route names

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
        return 'Budgets'; // Simplified Label
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

    return Scaffold(
      body: navigationShell, // The page content for the current branch
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
        // Use theme properties for styling
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
        elevation: navTheme.elevation ?? 8.0, // Default elevation if not themed
        items: List.generate(5, (index) {
          // Generate 5 items
          final isActive = index == navigationShell.currentIndex;
          return BottomNavigationBarItem(
            icon: Icon(_getIconForIndex(index, false)),
            activeIcon: Icon(_getIconForIndex(index, true)),
            label: _getLabelForIndex(index),
          );
        }),
      ),
    );
  }
}
