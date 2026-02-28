import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/main.dart';
import 'package:collection/collection.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_bridge/bridge_circular_progress_indicator.dart';
import 'package:expense_tracker/ui_bridge/bridge_scaffold.dart';

class TransactionDetailPage extends StatefulWidget {
  final String transactionId;
  final TransactionEntity? transaction;

  const TransactionDetailPage({
    super.key,
    required this.transactionId,
    this.transaction,
  });

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  TransactionEntity? _transaction;

  @override
  void initState() {
    super.initState();
    _transaction = widget.transaction;
    if (_transaction == null) {
      context.read<TransactionListBloc>().add(
        FetchTransactionById(widget.transactionId),
      );
    }
  }

  @override
  void dispose() {
    // Clear selection to avoid stale data next time
    // We can't access context here easily if unmounted, but typically safe in dispose.
    // However, checking mounted is safer.
    // context.read<TransactionListBloc>().add(const ClearSelectedTransaction());
    super.dispose();
  }

  void _handleDelete(BuildContext context) async {
    if (_transaction == null) return;
    log.info(
      "[TxnDetailPage] Delete requested for TXN ID: ${_transaction!.id}",
    );
    final confirmed = await AppDialogs.showConfirmation(
      context,
      title: "Confirm Deletion",
      content:
          'Are you sure you want to permanently delete this ${_transaction!.type.name}:\n"${_transaction!.title}"?',
      confirmText: "Delete",
      confirmColor: context.kit.colors.danger,
    );
    if (confirmed == true && context.mounted) {
      log.info("[TxnDetailPage] Delete confirmed.");
      context.read<TransactionListBloc>().add(DeleteTransaction(_transaction!));
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RouteNames.transactionsList);
      }
    } else {
      log.info("[TxnDetailPage] Delete cancelled.");
    }
  }

  void _navigateToEdit(BuildContext context) {
    if (_transaction == null) return;
    log.info(
      "[TxnDetailPage] Navigate to Edit requested for TXN ID: ${_transaction!.id}",
    );
    const String routeName = RouteNames.editTransaction;
    final Map<String, String> params = {
      RouteNames.paramTransactionId: _transaction!.id,
    };
    log.info("[TxnDetailPage] Navigating via pushNamed:");
    log.info("  Route Name: $routeName");
    log.info("  Path Params: $params");
    log.info("  Extra Data Type: ${_transaction.runtimeType}");

    context.pushNamed(routeName, pathParameters: params, extra: _transaction);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Attempt to find transaction from Bloc if not provided or if we want updates
    final txnState = context.watch<TransactionListBloc>().state;
    TransactionEntity? currentTransaction;

    // Check selectedTransaction from Bloc (from deep link fetch)
    if (txnState.selectedTransaction?.id == widget.transactionId) {
      currentTransaction = txnState.selectedTransaction;
      _transaction = currentTransaction;
    } else if (_transaction != null) {
      currentTransaction = _transaction;
      // Try to find updated version in state list
      final found = txnState.transactions.firstWhereOrNull(
        (t) => t.id == widget.transactionId,
      );
      if (found != null) {
        currentTransaction = found;
        _transaction = found; // Update local reference
      }
    } else {
      // Not provided and not in selected, search in state list
      currentTransaction = txnState.transactions.firstWhereOrNull(
        (t) => t.id == widget.transactionId,
      );
      if (currentTransaction != null) {
        _transaction = currentTransaction;
      }
    }

    if (currentTransaction == null) {
      // If still loading, show loader. If loaded and not found, show error.
      if (txnState.status == ListStatus.loading ||
          txnState.status == ListStatus.initial) {
        return BridgeScaffold(
          appBar: AppBar(title: const Text('Loading...')),
          body: const Center(child: BridgeCircularProgressIndicator()),
        );
      } else {
        return BridgeScaffold(
          appBar: AppBar(title: const Text('Not Found')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: context.kit.colors.textMuted,
                ),
                const SizedBox(height: 16),
                const Text('Transaction not found or deleted.'),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Go to Dashboard',
                  onPressed: () => context.go(RouteNames.dashboard),
                ),
              ],
            ),
          ),
        );
      }
    }

    final transaction = currentTransaction;
    final settings = context.watch<SettingsBloc>().state;
    final currencySymbol = settings.currencySymbol;
    final isExpense = transaction.type == TransactionType.expense;
    final amountColor = isExpense
        ? context.kit.colors.danger
        : context.kit.colors.success;

    final accountState = context.watch<AccountListBloc>().state;
    String accountName = 'Loading...';
    if (accountState is AccountListLoaded) {
      accountName =
          accountState.items
              .firstWhereOrNull((acc) => acc.id == transaction.accountId)
              ?.name ??
          'Unknown/Deleted Account';
    }

    return BridgeScaffold(
      appBar: AppBar(
        title: Text(isExpense ? 'Expense Details' : 'Income Details'),
        actions: [
          IconButton(
            key: const ValueKey('button_transactionDetail_edit'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => _navigateToEdit(context),
          ),
          IconButton(
            key: const ValueKey('button_transactionDetail_delete'),
            icon: Icon(Icons.delete_outline, color: context.kit.colors.danger),
            tooltip: 'Delete',
            onPressed: () => _handleDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: context.space.allLg,
        children: [
          AppCard(
            elevation: 1,
            child: Padding(
              padding: context.space.allLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: context.kit.typography.headline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${isExpense ? '-' : '+'} ${CurrencyFormatter.format(transaction.amount, currencySymbol)}',
                    style: context.kit.typography.display.copyWith(
                      color: amountColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: DateFormatter.formatDateTime(transaction.date),
          ),
          if (transaction.category != null)
            _buildDetailRow(
              context,
              icon:
                  availableIcons[transaction.category!.iconName] ??
                  Icons.category_outlined,
              label: 'Category',
              value: transaction.category!.name,
              valueColor: transaction.category!.displayColor,
              iconColor: transaction.category!.displayColor,
            )
          else
            _buildDetailRow(
              context,
              icon: Icons.label_off_outlined,
              label: 'Category',
              value: 'Uncategorized',
              valueColor: context.kit.colors.textMuted,
            ),
          _buildDetailRow(
            context,
            icon: Icons.account_balance_wallet_outlined,
            label: 'Account',
            value: accountName,
          ),
          if (transaction.notes != null && transaction.notes!.isNotEmpty)
            _buildDetailRow(
              context,
              icon: Icons.notes_outlined,
              label: 'Notes',
              value: transaction.notes!,
              isMultiline: true,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    Color? iconColor,
    bool isMultiline = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: context.space.vSm,
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ?? context.kit.colors.secondary,
          ),
          const SizedBox(width: 16),
          Text('$label:', style: theme.textTheme.bodyLarge),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: context.kit.typography.body.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
              textAlign: TextAlign.end,
              softWrap: isMultiline,
            ),
          ),
        ],
      ),
    );
  }
}
