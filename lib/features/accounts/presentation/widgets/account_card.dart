import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
// import 'package:intl/intl.dart'; // No longer needed here
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart'; // Import formatter
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import SettingsBloc

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
    // Get the current currency symbol from the SettingsBloc state
    // Using context.watch ensures the widget rebuilds if the currency changes
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;

    final balanceColor =
        account.currentBalance >= 0 ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Icon(_getAccountIcon(account.type), size: 30),
        title:
            Text(account.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(account.type.name),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              // Use the formatter here
              CurrencyFormatter.format(account.currentBalance, currencySymbol),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: balanceColor,
                fontSize: 16,
              ),
            ),
            // Optionally show initial balance if needed
            // Text(
            //   'Initial: ${CurrencyFormatter.format(account.initialBalance, currencySymbol)}',
            //   style: Theme.of(context).textTheme.bodySmall,
            // ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  IconData _getAccountIcon(AssetType type) {
    switch (type) {
      case AssetType.bank:
        return Icons.account_balance;
      case AssetType.cash:
        return Icons.wallet;
      case AssetType.crypto:
        return Icons.currency_bitcoin;
      case AssetType.investment:
        return Icons.trending_up;
      case AssetType.other:
        return Icons.credit_card;
      default:
        return Icons.help_outline;
    }
  }
}
