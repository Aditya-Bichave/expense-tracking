import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For currency formatting
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';

class AccountCard extends StatelessWidget {
  final AssetAccount account;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AccountCard({
    super.key,
    required this.account,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
        symbol: '\$', decimalDigits: 2); // Adjust symbol as needed
    final balanceColor =
        account.currentBalance >= 0 ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Icon(_getAccountIcon(account.type),
            size: 30), // Helper function for icon
        title:
            Text(account.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(account.type.name), // Assumes enum has a nice name
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(account.currentBalance),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: balanceColor,
                fontSize: 16,
              ),
            ),
            // Optionally show initial balance if needed
            // Text(
            //   'Initial: ${currencyFormat.format(account.initialBalance)}',
            //   style: Theme.of(context).textTheme.bodySmall,
            // ),
          ],
        ),
        onTap: onTap, // Navigate to account details/transactions maybe?
        // Add edit/delete functionality if needed (e.g., via PopupMenuButton or Swipe)
        // Example using a PopupMenuButton in trailing, adjust layout if needed:
        // trailing: Row(
        //   mainAxisSize: MainAxisSize.min,
        //   children: [
        //     Text(...), // Balance Text
        //     if (onEdit != null || onDelete != null)
        //       PopupMenuButton<String>(
        //         onSelected: (value) {
        //           if (value == 'edit' && onEdit != null) onEdit!();
        //           if (value == 'delete' && onDelete != null) onDelete!();
        //         },
        //         itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        //           if (onEdit != null) const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
        //           if (onDelete != null) const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
        //         ],
        //         icon: const Icon(Icons.more_vert),
        //       ),
        //   ],
        // ),
      ),
    );
  }

  // Helper to get an icon based on account type
  IconData _getAccountIcon(AssetType type) {
    switch (type) {
      case AssetType.bank:
        return Icons.account_balance;
      case AssetType.cash:
        return Icons.wallet; // Or Icons.money
      case AssetType.crypto:
        return Icons.currency_bitcoin; // Or a generic crypto icon
      case AssetType.investment:
        return Icons.trending_up;
      case AssetType.other:
        return Icons.credit_card; // Generic fallback
      default:
        return Icons.help_outline;
    }
  }
}
