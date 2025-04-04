import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/main.dart';

class TransactionDetailPage extends StatelessWidget {
  final TransactionEntity transaction; // Passed via GoRouter 'extra'

  const TransactionDetailPage({super.key, required this.transaction});

  // TODO: Implement delete confirmation and action
  void _handleDelete(BuildContext context) async {
    log.warning("Delete from Detail Page - Not fully implemented");
    // final confirmed = await AppDialogs.showConfirmation(...);
    // if (confirmed == true && context.mounted) {
    //    context.read<TransactionListBloc>().add(DeleteTransaction(transaction));
    //    context.pop(); // Go back after delete
    // }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Delete action TBD")));
  }

  // TODO: Implement navigation to Edit page
  void _navigateToEdit(BuildContext context) {
    log.info("Navigate to Edit from Detail Page");
    final routeName = transaction.type == TransactionType.expense
        ? RouteNames.editExpense
        : RouteNames.editIncome;
    context.pushNamed(routeName,
        pathParameters: {RouteNames.paramTransactionId: transaction.id},
        extra: transaction.originalEntity);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsBloc>().state;
    final currencySymbol = settings.currencySymbol;
    final isExpense = transaction.type == TransactionType.expense;
    final amountColor = isExpense
        ? theme.colorScheme.error
        : theme.colorScheme.tertiary; // Or a success green

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
              icon: Icons.category_outlined, // TODO: Use actual category icon
              label: 'Category',
              value: transaction.category!.name,
              valueColor: transaction.category!.displayColor,
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
            // TODO: Fetch account name based on transaction.accountId
            value: 'Account Name (ID: ${transaction.accountId})',
          ),
          if (transaction.notes != null && transaction.notes!.isNotEmpty)
            _buildDetailRow(
              context,
              icon: Icons.notes_outlined,
              label: 'Notes',
              value: transaction.notes!,
              isMultiline: true,
            ),

          // TODO: Add Map View if location data is added later
          // TODO: Add Receipt attachment display if implemented later
        ],
      ),
    );
  }

  // Helper for consistent detail rows
  Widget _buildDetailRow(BuildContext context,
      {required IconData icon,
      required String label,
      required String value,
      Color? valueColor,
      bool isMultiline = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.secondary),
          const SizedBox(width: 16),
          Text('$label:', style: theme.textTheme.bodyLarge),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500, color: valueColor),
              textAlign: TextAlign.end,
              softWrap: isMultiline,
            ),
          ),
        ],
      ),
    );
  }
}
