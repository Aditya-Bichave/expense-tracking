import 'package:expense_tracker/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

typedef ApplySortCallback =
    void Function(TransactionSortBy sortBy, SortDirection sortDirection);

class TransactionSortSheet extends StatelessWidget {
  final TransactionSortBy currentSortBy;
  final SortDirection currentSortDirection;
  final ApplySortCallback onApplySort;

  const TransactionSortSheet({
    super.key,
    required this.currentSortBy,
    required this.currentSortDirection,
    required this.onApplySort,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    SortDirection defaultDirection(TransactionSortBy sortBy) {
      switch (sortBy) {
        case TransactionSortBy.date:
        case TransactionSortBy.amount:
          return SortDirection.descending;
        case TransactionSortBy.category:
        case TransactionSortBy.title:
          return SortDirection.ascending;
      }
    }

    final sortOptions = TransactionSortBy.values.map((sortBy) {
      final bool isSelected = currentSortBy == sortBy;
      final SortDirection defaultDir = defaultDirection(sortBy);
      final IconData directionIcon = isSelected
          ? (currentSortDirection == SortDirection.descending
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded)
          : (defaultDir == SortDirection.descending
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded);

      return RadioListTile<TransactionSortBy>(
        title: Text(toBeginningOfSentenceCase(sortBy.name) ?? sortBy.name),
        value: sortBy,
        groupValue: currentSortBy,
        secondary: Icon(
          directionIcon,
          color: isSelected ? theme.colorScheme.primary : theme.disabledColor,
        ),
        activeColor: theme.colorScheme.primary,
        onChanged: (TransactionSortBy? value) {
          if (value != null) {
            final newDirection = isSelected
                ? (currentSortDirection == SortDirection.descending
                      ? SortDirection.ascending
                      : SortDirection.descending)
                : defaultDirection(value);
            onApplySort(value, newDirection);
            Navigator.pop(context);
          }
        },
      );
    }).toList();

    return Container(
      padding: const context.space.vLg,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Fit content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              'Sort Transactions By',
              style: theme.textTheme.titleLarge,
            ),
          ),
          ...sortOptions,
          const SizedBox(height: 8), // Padding at bottom
        ],
      ),
    );
  }
}
