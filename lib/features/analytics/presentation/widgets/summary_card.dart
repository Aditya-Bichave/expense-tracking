import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:intl/intl.dart'; // For currency formatting

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
        locale: 'en_US', symbol: '\$'); // Customize as needed
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
                    'Summary', // Title for the card
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Spent:', style: theme.textTheme.bodyLarge),
                      Text(
                        currencyFormat.format(summary.totalExpenses),
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
                            Text(currencyFormat.format(entry.value)), // Amount
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
