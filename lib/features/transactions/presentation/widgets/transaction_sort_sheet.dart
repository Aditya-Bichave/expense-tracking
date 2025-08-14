import 'package:expense_tracker/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/core/utils/string_extensions.dart';

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

    final sortOptions = TransactionSortBy.values.map((sortBy) {
      final bool isSelected = currentSortBy == sortBy;
      final IconData directionIcon = isSelected
          ? (currentSortDirection == SortDirection.descending
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded)
          : Icons.swap_vert_rounded; // Indicate sortable but not selected

      return RadioListTile<TransactionSortBy>(
        title: Text(
          sortBy.name.capitalize(),
        ), // Assuming capitalize extension exists
        value: sortBy,
        groupValue: currentSortBy,
        secondary: Icon(
          directionIcon,
          color: isSelected ? theme.colorScheme.primary : theme.disabledColor,
        ),
        activeColor: theme.colorScheme.primary,
        onChanged: (TransactionSortBy? value) {
          if (value != null) {
            // If selecting the same criteria, toggle direction, otherwise default to descending
            final newDirection = isSelected
                ? (currentSortDirection == SortDirection.descending
                      ? SortDirection.ascending
                      : SortDirection.descending)
                : SortDirection.descending;
            onApplySort(value, newDirection);
            Navigator.pop(context); // Close sheet after selection
          }
        },
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
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
