// lib/features/transactions/presentation/widgets/transaction_list_view.dart
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_item.dart'; // Updated path
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionListView extends StatelessWidget {
  final TransactionListState state;
  final SettingsState settings;
  final Function(BuildContext, TransactionEntity) navigateToDetailOrEdit;

  const TransactionListView({
    super.key,
    required this.state,
    required this.settings,
    required this.navigateToDetailOrEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.status == ListStatus.loading && state.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == ListStatus.error && state.transactions.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                  "Error: ${state.errorMessage ?? 'Failed to load transactions'}",
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center)));
    }
    if (state.transactions.isEmpty &&
        state.status != ListStatus.loading &&
        state.status != ListStatus.reloading) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 60,
                        color: theme.colorScheme.secondary.withOpacity(0.7)),
                    const SizedBox(height: 16),
                    Text(
                        state.filtersApplied
                            ? "No transactions match filters"
                            : "No transactions recorded yet",
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      state.filtersApplied
                          ? "Try adjusting or clearing the filters."
                          : "Tap the '+' button to add your first expense or income.",
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ])));
    }

    return ListView.builder(
      padding:
          const EdgeInsets.only(top: 0, bottom: 80), // Ensure padding for FAB
      itemCount: state.transactions.length,
      itemBuilder: (ctx, index) {
        final transaction = state.transactions[index];
        final isSelected =
            state.selectedTransactionIds.contains(transaction.id);

        return Container(
          // Use Container for background color
          key: ValueKey(
              "${transaction.id}_list_item_${isSelected}"), // Unique key for item
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : Colors.transparent,
          child: TransactionListItem(
            transaction: transaction,
            currencySymbol: settings.currencySymbol,
            onTap: () {
              // Assign tap logic directly here
              if (state.isInBatchEditMode) {
                log.fine(
                    "[TxnListView] Item tapped in batch mode. Toggling selection for ${transaction.id}.");
                context
                    .read<TransactionListBloc>()
                    .add(SelectTransaction(transaction.id));
              } else {
                log.fine(
                    "[TxnListView] Item tapped in normal mode. Navigating to edit for ${transaction.id}.");
                navigateToDetailOrEdit(
                    context, transaction); // Navigate on normal tap
              }
            },
          ),
        ).animate().fadeIn(delay: (20 * index).ms).slideY(begin: 0.1);
      },
    );
  }
}
