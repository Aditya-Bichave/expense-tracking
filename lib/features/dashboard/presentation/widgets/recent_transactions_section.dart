// lib/features/dashboard/presentation/widgets/recent_transactions_section.dart
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class RecentTransactionsSection extends StatelessWidget {
  final Function(BuildContext, TransactionEntity) navigateToDetailOrEdit;

  const RecentTransactionsSection({
    super.key,
    required this.navigateToDetailOrEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currencySymbol = settings.currencySymbol;
    final transactionState = context.watch<TransactionListBloc>().state;
    final modeTheme = context.modeTheme;

    List<TransactionEntity> recentItems = [];
    bool isLoading = transactionState.status == ListStatus.loading;
    String? errorMsg = transactionState.errorMessage;

    if (transactionState.status == ListStatus.success ||
        transactionState.status == ListStatus.reloading) {
      recentItems =
          transactionState.transactions.take(5).toList(); // Show latest 5
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
            title: 'Recent Activity',
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8)),
        if (isLoading && recentItems.isEmpty)
          const Center(
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: CircularProgressIndicator(strokeWidth: 2)))
        else if (errorMsg != null && recentItems.isEmpty)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Center(
                child: Text("Error loading recent: $errorMsg",
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center)),
          )
        else if (recentItems.isEmpty)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    modeTheme?.assets.getIllustration(
                          AssetKeys.illuEmptyTransactions,
                          defaultPath: AppAssets.elIlluEmptyAddTransaction,
                        ) ??
                        AppAssets.elIlluEmptyAddTransaction,
                    height: 100,
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.secondary.withOpacity(0.5),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No recent activity",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Start tracking your spending",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentItems.length,
            itemBuilder: (ctx, index) {
              final item = recentItems[index];
              return TransactionListItem(
                // Use the moved widget
                transaction: item,
                currencySymbol: currencySymbol,
                onTap: () => navigateToDetailOrEdit(context, item),
              );
            },
          ),
        // "View All" Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Center(
            child: TextButton.icon(
              key: const ValueKey('button_recentTransactions_viewAll'),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('View All Transactions'),
              onPressed: () => context.go(RouteNames.transactionsList),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.secondary,
                textStyle: theme.textTheme.labelLarge,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
