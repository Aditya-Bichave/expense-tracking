// lib/features/dashboard/presentation/widgets/recent_transactions_section.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_item.dart'; // Updated path
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_bridge/bridge_button.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart'; // Assuming this exists or using standard Circular
import 'package:expense_tracker/ui_bridge/bridge_text.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';

class RecentTransactionsSection extends StatelessWidget {
  final Function(BuildContext, TransactionEntity) navigateToDetailOrEdit;

  const RecentTransactionsSection({
    super.key,
    required this.navigateToDetailOrEdit,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final settings = context.watch<SettingsBloc>().state;
    final currencySymbol = settings.currencySymbol;
    final transactionState = context.watch<TransactionListBloc>().state;

    List<TransactionEntity> recentItems = [];
    bool isLoading = transactionState.status == ListStatus.loading;
    String? errorMsg = transactionState.errorMessage;

    if (transactionState.status == ListStatus.success ||
        transactionState.status == ListStatus.reloading) {
      recentItems = transactionState.transactions
          .take(5)
          .toList(); // Show latest 5
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recent Activity',
          padding: EdgeInsets.fromLTRB(
            kit.spacing.lg,
            kit.spacing.xxl,
            kit.spacing.lg,
            kit.spacing.sm,
          ),
        ),
        if (isLoading && recentItems.isEmpty)
          Center(
            child: Padding(
              padding: kit.spacing.vXl,
              child: const AppLoadingIndicator(),
            ),
          )
        else if (errorMsg != null && recentItems.isEmpty)
          Padding(
            padding: kit.spacing.allLg,
            child: Center(
              child: BridgeText(
                "Error loading recent: $errorMsg",
                style: kit.typography.body.copyWith(color: kit.colors.error),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else if (recentItems.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: kit.spacing.lg,
              vertical: kit.spacing.xxl,
            ),
            child: Center(
              child: BridgeText(
                "No transactions recorded yet.",
                style: kit.typography.body,
              ),
            ),
          )
        else
          Column(
            children: recentItems.map((item) {
              return TransactionListItem(
                // Use the moved widget
                transaction: item,
                currencySymbol: currencySymbol,
                onTap: () => navigateToDetailOrEdit(context, item),
              );
            }).toList(),
          ),
        // "View All" Button
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: kit.spacing.lg,
            vertical: kit.spacing.md,
          ),
          child: Center(
            child: BridgeButton.ghost(
              key: const ValueKey('button_recentTransactions_viewAll'),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: 'View All Transactions',
              onPressed: () => context.go(RouteNames.transactionsList),
            ),
          ),
        ),
      ],
    );
  }
}
