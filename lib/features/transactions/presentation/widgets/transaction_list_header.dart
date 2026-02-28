// lib/features/transactions/presentation/widgets/transaction_list_header.dart
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';
import 'package:expense_tracker/ui_bridge/bridge_border_radius.dart';

class TransactionListHeader extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onClearSearch;
  final VoidCallback onToggleCalendarView;
  final bool isCalendarViewShown;
  final Function(BuildContext, TransactionListState) showFilterDialog;
  final Function(BuildContext, TransactionListState) showSortDialog;

  const TransactionListHeader({
    super.key,
    required this.searchController,
    required this.onClearSearch,
    required this.onToggleCalendarView,
    required this.isCalendarViewShown,
    required this.showFilterDialog,
    required this.showSortDialog,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<TransactionListBloc, TransactionListState>(
      builder: (context, state) {
        final isInBatchMode = state.isInBatchEditMode;
        final bool hasSearchTerm =
            state.searchTerm != null && state.searchTerm!.isNotEmpty;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 4.0),
          child: Column(
            children: [
              TextField(
                key: const ValueKey('textField_transactionSearch'),
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search title, category, amount...",
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BridgeBorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BridgeBorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BridgeBorderRadius.circular(30),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  isDense: true,
                  suffixIcon: hasSearchTerm
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: "Clear Search",
                          onPressed: onClearSearch,
                        )
                      : null,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        key: const ValueKey('button_show_filter'),
                        icon: Icon(
                          Icons.filter_list_rounded,
                          size: 18,
                          color: state.filtersApplied
                              ? theme.colorScheme.primary
                              : null,
                        ),
                        label: Text(
                          "Filter",
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: state.filtersApplied
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                        onPressed: () => showFilterDialog(context, state),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      TextButton.icon(
                        key: const ValueKey('button_show_sort'),
                        icon: const Icon(Icons.sort_rounded, size: 18),
                        label: Text("Sort", style: theme.textTheme.labelMedium),
                        onPressed: () => showSortDialog(context, state),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        key: const ValueKey('button_toggle_view'),
                        icon: Icon(
                          isCalendarViewShown
                              ? Icons.view_list_rounded
                              : Icons.calendar_today_rounded,
                          size: 20,
                        ),
                        tooltip: isCalendarViewShown
                            ? "List View"
                            : "Calendar View",
                        onPressed: onToggleCalendarView,
                      ),
                      IconButton(
                        key: const ValueKey('button_toggle_batchEdit'),
                        icon: Icon(
                          isInBatchMode
                              ? Icons.cancel_outlined
                              : Icons.select_all_rounded,
                          size: 20,
                        ),
                        tooltip: isInBatchMode
                            ? "Cancel Selection"
                            : "Select Multiple",
                        color: isInBatchMode ? theme.colorScheme.primary : null,
                        onPressed: () => context
                            .read<TransactionListBloc>()
                            .add(const ToggleBatchEdit()),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
