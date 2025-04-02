import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
// import 'package:intl/intl.dart'; // No longer needed here
import 'package:expense_tracker/core/utils/currency_formatter.dart'; // Import formatter
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import SettingsBloc

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Get currency symbol from SettingsBloc
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;

    final theme = Theme.of(context);

    return BlocBuilder<SummaryBloc, SummaryState>(
      builder: (context, state) {
        if (state is SummaryLoading) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
                child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))),
          );
        } else if (state is SummaryLoaded) {
          final summary = state.summary;
          return Card(
            margin: const EdgeInsets.all(12.0),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expense Summary', // Title for the card
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Spent:', style: theme.textTheme.bodyLarge),
                      Text(
                        // Use CurrencyFormatter
                        CurrencyFormatter.format(
                            summary.totalExpenses, currencySymbol),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text('By Category:', style: theme.textTheme.titleMedium),
                  if (summary.categoryBreakdown.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('No expenses in selected period.'),
                    )
                  else
                    ...summary.categoryBreakdown.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key), // Category Name
                            Text(// Use CurrencyFormatter
                                CurrencyFormatter.format(
                                    entry.value, currencySymbol)), // Amount
                          ],
                        ),
                      );
                    }).toList(), // Display category breakdown
                ],
              ),
            ),
          );
        } else if (state is SummaryError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
                child: Text('Error loading summary: ${state.message}',
                    style: TextStyle(color: theme.colorScheme.error))),
          );
        }
        return const SizedBox.shrink(); // Initial state or empty
      },
    );
  }
}
