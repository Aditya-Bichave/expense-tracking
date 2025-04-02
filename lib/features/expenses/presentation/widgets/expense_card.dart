import 'package:flutter/material.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final DismissDirectionCallback? onDismissed; // Callback for swipe-to-delete
  final VoidCallback? onTap; // Callback for tapping the card (for editing)

  const ExpenseCard({
    super.key, // Use super parameters
    required this.expense,
    this.onDismissed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget cardContent = ListTile(
      leading: CircleAvatar(
        // Or Icon based on category
        child: Text(
          expense.category.name.substring(0, 1), // First letter of category
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
        '\$${expense.amount.toStringAsFixed(2)}', // Format currency
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.error, // Or primary color based on type
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
    );

    // Wrap with Dismissible if onDismissed is provided
    if (onDismissed != null) {
      return Dismissible(
          key: Key(expense.id), // Unique key for dismissible
          direction: DismissDirection.endToStart, // Swipe left to delete
          onDismissed: onDismissed,
          background: Container(
            color: Colors.redAccent,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: const Icon(Icons.delete_sweep, color: Colors.white),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            elevation: 1, // Subtle elevation
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
