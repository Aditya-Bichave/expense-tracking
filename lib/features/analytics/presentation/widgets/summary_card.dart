import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/ui_bridge/bridge_card.dart';
import 'package:expense_tracker/ui_bridge/bridge_circular_progress_indicator.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_style.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final theme = Theme.of(context);

    return BlocBuilder<SummaryBloc, SummaryState>(
      builder: (context, state) {
        log.info(
          "[SummaryCard] BlocBuilder running for state: ${state.runtimeType}",
        );

        Widget content;

        if (state is SummaryLoading && !state.isReloading) {
          log.info(
            "[SummaryCard UI] State is initial SummaryLoading. Showing Shimmer/Indicator.",
          );
          // Use a shimmer effect or simple indicator for initial load
          content = const Padding(
            padding: context.space.allLg,
            child: Center(child: BridgeCircularProgressIndicator(strokeWidth: 2)),
          );
        } else if (state is SummaryLoaded ||
            (state is SummaryLoading && state.isReloading)) {
          log.info(
            "[SummaryCard UI] State is SummaryLoaded or reloading. Building card content.",
          );
          final summary = (state is SummaryLoaded)
              ? state.summary
              : (context.read<SummaryBloc>().state as SummaryLoaded?)
                    ?.summary; // Use previous data if reloading

          if (summary == null) {
            // Should not happen if reloading logic is correct, but safety check
            log.warning(
              "[SummaryCard UI] Summary is null during Loaded/Reloading state.",
            );
            content = const Padding(
              padding: context.space.allLg,
              child: Center(child: Text('Loading summary data...')),
            );
          } else {
            content = Padding(
              padding: const context.space.allLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expense Summary', // Title for the card
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Spent:', style: theme.textTheme.titleMedium),
                      Text(
                        CurrencyFormatter.format(
                          summary.totalExpenses,
                          currencySymbol,
                        ),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme
                              .colorScheme
                              .error, // Expenses are typically red
                        ),
                      ),
                    ],
                  ),
                  if (summary.categoryBreakdown.isNotEmpty) ...[
                    const Divider(height: 24, thickness: 0.5),
                    Text('By Category:', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    // Use ListView for potentially many categories
                    ListView.separated(
                      shrinkWrap: true, // Important inside Column
                      physics:
                          const NeverScrollableScrollPhysics(), // Disable ListView's own scrolling
                      itemCount: summary.categoryBreakdown.length,
                      itemBuilder: (context, index) {
                        final entry = summary.categoryBreakdown.entries
                            .elementAt(index);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: theme.textTheme.bodyMedium,
                            ), // Category Name
                            Text(
                              CurrencyFormatter.format(
                                entry.value,
                                currencySymbol,
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ), // Amount
                          ],
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 6),
                    ),
                  ] else if (summary.totalExpenses > 0) ...[
                    // Show only if total > 0 but breakdown is empty
                    const Divider(height: 24, thickness: 0.5),
                    Text(
                      'No expenses with categories found in the selected period.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ] else ...[
                    // Show if total is also 0
                    const Divider(height: 24, thickness: 0.5),
                    Text(
                      'No expenses recorded in the selected period.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            );
          }
        } else if (state is SummaryError) {
          log.info(
            "[SummaryCard UI] State is SummaryError: ${state.message}. Showing error message.",
          );
          content = Padding(
            padding: const context.space.allLg,
            child: Center(
              child: Text(
                'Error loading summary: ${state.message}',
                textAlign: TextAlign.center,
                style: BridgeTextStyle(color: theme.colorScheme.error),
              ),
            ),
          );
        } else {
          // Initial state
          log.info(
            "[SummaryCard UI] State is SummaryInitial or Unknown. Showing loading indicator.",
          );
          content = const Padding(
            padding: context.space.allLg,
            child: Center(child: BridgeCircularProgressIndicator(strokeWidth: 2)),
          );
        }

        // Wrap content in Card and AnimatedSwitcher
        return BridgeCard(
          margin: const context.space.allMd,
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: content, // Animate the content changes
          ),
        );
      },
    );
  }
}
