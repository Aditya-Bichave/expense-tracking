import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart'; // To potentially get account name
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart'; // For icon lookup
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/main.dart';
import 'package:collection/collection.dart';

class TransactionDetailPage extends StatelessWidget {
  final TransactionEntity transaction; // Passed via GoRouter 'extra'

  const TransactionDetailPage({super.key, required this.transaction});

  // Handle Delete Action
  void _handleDelete(BuildContext context) async {
    log.info("[TxnDetailPage] Delete requested for TXN ID: ${transaction.id}");
    final confirmed = await AppDialogs.showConfirmation(
      context,
      title: "Confirm Deletion",
      content:
          'Are you sure you want to permanently delete this ${transaction.type.name}:\n"${transaction.title}"?',
      confirmText: "Delete",
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (confirmed == true && context.mounted) {
      log.info("[TxnDetailPage] Delete confirmed.");
      // Dispatch delete event to the list BLoC
      context.read<TransactionListBloc>().add(DeleteTransaction(transaction));
      // Pop back to the list screen after deletion is requested
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RouteNames.transactionsList); // Fallback navigation
      }
    } else {
      log.info("[TxnDetailPage] Delete cancelled.");
    }
  }

  // Navigate to the unified Edit page
  void _navigateToEdit(BuildContext context) {
    log.info(
      "[TxnDetailPage] Navigate to Edit requested for TXN ID: ${transaction.id}",
    );
    // Use the unified edit route name
    const String routeName = RouteNames.editTransaction;
    final Map<String, String> params = {
      RouteNames.paramTransactionId: transaction.id,
    };
    log.info("[TxnDetailPage] Navigating via pushNamed:");
    log.info("  Route Name: $routeName");
    log.info("  Path Params: $params");
    log.info("  Extra Data Type: ${transaction.runtimeType}");

    context.pushNamed(routeName, pathParameters: params, extra: transaction);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currencySymbol = settings.currencySymbol;
    final isExpense = transaction.type == TransactionType.expense;
    final amountColor = isExpense
        ? theme.colorScheme.error
        : Colors.green.shade700; // Use consistent green for income amount

    // Attempt to get account name
    final accountState = context.watch<AccountListBloc>().state;
    String accountName = 'Loading...'; // Default
    if (accountState is AccountListLoaded) {
      accountName = accountState.items
              .firstWhereOrNull((acc) => acc.id == transaction.accountId)
              ?.name ??
          'Unknown/Deleted Account';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isExpense ? 'Expense Details' : 'Income Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => _navigateToEdit(context),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            tooltip: 'Delete',
            onPressed: () => _handleDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Amount Card
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    '${isExpense ? '-' : '+'} ${CurrencyFormatter.format(transaction.amount, currencySymbol)}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Details Section
          _buildDetailRow(
            context,
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: DateFormatter.formatDateTime(transaction.date),
          ),
          if (transaction.category != null)
            _buildDetailRow(
              context,
              icon: availableIcons[transaction.category!.iconName] ??
                  Icons.category_outlined, // Use actual icon
              label: 'Category',
              value: transaction.category!.name,
              valueColor: transaction.category!.displayColor,
              iconColor:
                  transaction.category!.displayColor, // Color the icon too
            )
          else
            _buildDetailRow(
              context,
              icon: Icons.label_off_outlined,
              label: 'Category',
              value: 'Uncategorized',
              valueColor: theme.disabledColor,
            ),
          _buildDetailRow(
            context,
            icon: Icons.account_balance_wallet_outlined,
            label: 'Account',
            value: accountName, // Show fetched name
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

  // Helper for consistent detail rows
  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    Color? iconColor, // Optional color for the icon
    bool isMultiline = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ?? theme.colorScheme.secondary,
          ), // Use iconColor or default
          const SizedBox(width: 16),
          Text('$label:', style: theme.textTheme.bodyLarge),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
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
