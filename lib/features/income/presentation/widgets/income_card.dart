import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
// import 'package:intl/intl.dart'; // No longer needed here
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart'; // Import formatter
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import SettingsBloc

class IncomeCard extends StatelessWidget {
  final Income income;
  final String categoryName;
  final String accountName;
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
    // Get currency symbol from SettingsBloc
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          // Consistent styling with expense card
          backgroundColor: Colors.green.shade100, // Lighter background
          child: Icon(Icons.arrow_downward,
              color: Colors.green.shade800), // Adjusted colors
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
              Padding(
                // Add padding for notes
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  income.notes!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: Text(
          // Use CurrencyFormatter
          CurrencyFormatter.format(income.amount, currencySymbol),
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700, // Adjusted color
              fontSize: 16),
        ),
        onTap: onTap,
        // Add edit/delete buttons if needed
      ),
    );
  }
}
