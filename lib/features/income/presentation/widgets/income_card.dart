import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
// If you need account name, you'll need to either pass it or fetch it
// import 'package:expense_tracking/features/accounts/domain/entities/asset_account.dart';

class IncomeCard extends StatelessWidget {
  final Income income;
  final String categoryName; // Pass category name explicitly
  final String accountName; // Pass account name explicitly
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const IncomeCard({
    super.key,
    required this.income,
    required this.categoryName,
    required this.accountName,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2); // Adjust symbol

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.arrow_downward, color: Colors.green),
          backgroundColor: Colors.greenAccent,
        ),
        title:
            Text(income.title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$categoryName • $accountName'), // Show category & account
            Text(DateFormatter.formatDateTime(
                income.date)), // Use your formatter
            if (income.notes != null && income.notes!.isNotEmpty)
              Text(
                income.notes!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Text(
          currencyFormat.format(income.amount),
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
        ),
        onTap: onTap,
        // Add edit/delete buttons if needed, similar to AccountCard
      ),
    );
  }
}
