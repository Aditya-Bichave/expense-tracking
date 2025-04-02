import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart'; // Import formatter
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import SettingsBloc

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final DismissDirectionCallback? onDismissed;
  final VoidCallback? onTap;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onDismissed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Get currency symbol from SettingsBloc
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;

    Widget cardContent = ListTile(
      leading: CircleAvatar(
        // Or Icon based on category
        child: Text(
          expense.category.name.isNotEmpty
              ? expense.category.name.substring(0, 1)
              : '?', // First letter or fallback
          style: TextStyle(color: theme.colorScheme.onPrimary),
        ),
        backgroundColor: theme.colorScheme.primary,
      ),
      title: Text(expense.title, style: theme.textTheme.titleMedium),
      subtitle: Text(
        '${expense.category.displayName}\n${DateFormatter.formatDateTime(expense.date)}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        // Use CurrencyFormatter
        CurrencyFormatter.format(expense.amount, currencySymbol),
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme
              .error, // Expenses are typically shown in red/error color
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
    );

    // Wrap with Dismissible if onDismissed is provided
    if (onDismissed != null) {
      return Dismissible(
          key: Key(expense.id),
          direction: DismissDirection.endToStart,
          onDismissed: onDismissed,
          background: Container(
            color: Colors.redAccent,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: const Icon(Icons.delete_sweep, color: Colors.white),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            elevation: 1,
            child: cardContent,
          ));
    } else {
      // Just return the Card without Dismissible
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        elevation: 1,
        child: cardContent,
      );
    }
  }
}
