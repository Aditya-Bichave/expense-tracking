// lib/features/transactions/presentation/widgets/transaction_list_view.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/categories/domain/usecases/save_user_categorization_history.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
// Keep this
// --- Import Expense/Income Card Widgets ---
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_card.dart';
import 'package:expense_tracker/features/income/presentation/widgets/income_card.dart';
// --- End Import ---
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/ui_bridge/bridge_card.dart';
import 'package:expense_tracker/ui_bridge/bridge_circular_progress_indicator.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_style.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class TransactionListView extends StatelessWidget {
  final TransactionListState state;
  final SettingsState settings;
  final Map<String, String> accountNameMap;
  final String currencySymbol;
  final Function(BuildContext, TransactionEntity) navigateToDetailOrEdit;
  // --- ADD Handlers ---
  final Function(BuildContext, TransactionEntity) handleChangeCategoryRequest;
  final Function(BuildContext, TransactionEntity) confirmDeletion;
  final bool enableAnimations;
  // --- END Handlers ---

  const TransactionListView({
    super.key,
    required this.state,
    required this.settings,
    required this.accountNameMap,
    required this.currencySymbol,
    required this.navigateToDetailOrEdit,
    // --- Add to constructor ---
    required this.handleChangeCategoryRequest,
    required this.confirmDeletion,
    this.enableAnimations = true,
    // --- End Add ---
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.status == ListStatus.loading && state.transactions.isEmpty) {
      return const Center(child: BridgeCircularProgressIndicator());
    }
    if (state.status == ListStatus.error && state.transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: context.space.allXl,
          child: Text(
            "Error: ${state.errorMessage ?? 'Failed to load transactions'}",
            style: BridgeTextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (state.transactions.isEmpty &&
        state.status != ListStatus.loading &&
        state.status != ListStatus.reloading) {
      return Center(
        child: Padding(
          padding: context.space.allXxxl,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 60,
                color: theme.colorScheme.secondary.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                state.filtersApplied
                    ? "No transactions match filters"
                    : "No transactions recorded yet",
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.filtersApplied
                    ? "Try adjusting or clearing the filters."
                    : "Tap the '+' button to add your first expense or income.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (!state
                  .filtersApplied) // Show add button only if no filters applied
                ElevatedButton.icon(
                  key: const ValueKey('button_listView_addFirst'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add First Transaction'),
                  onPressed: () => context.pushNamed(RouteNames.addTransaction),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        top: 0,
        bottom: 80,
      ), // Ensure padding for FAB
      itemCount: state.transactions.length,
      itemBuilder: (ctx, index) {
        final transaction = state.transactions[index];
        final isSelected = state.selectedTransactionIds.contains(
          transaction.id,
        );

        // --- USE ExpenseCard or IncomeCard based on type ---
        Widget cardItem;
        final accountName = accountNameMap[transaction.accountId] ?? 'Deleted';
        if (transaction.type == TransactionType.expense) {
          cardItem = ExpenseCard(
            expense: transaction.expense!,
            accountName: accountName,
            currencySymbol: currencySymbol,
            onCardTap: (exp) {
              // Pass original Expense
              if (state.isInBatchEditMode) {
                context.read<TransactionListBloc>().add(
                  SelectTransaction(exp.id),
                );
              } else {
                navigateToDetailOrEdit(
                  context,
                  transaction,
                ); // Pass the TransactionEntity
              }
            },
            onChangeCategoryRequest: (exp) =>
                handleChangeCategoryRequest(context, transaction),
            onUserCategorized: (exp, cat) {
              final matchData = TransactionMatchData(
                description: exp.title,
                merchantId: null,
              );
              context.read<TransactionListBloc>().add(
                UserCategorizedTransaction(
                  transactionId: exp.id,
                  transactionType: TransactionType.expense,
                  selectedCategory: cat,
                  matchData: matchData,
                ),
              );
            },
          );
        } else {
          // Income
          cardItem = IncomeCard(
            income: transaction.income!,
            accountName: accountName,
            currencySymbol: currencySymbol,
            onCardTap: (inc) {
              // Pass original Income
              if (state.isInBatchEditMode) {
                context.read<TransactionListBloc>().add(
                  SelectTransaction(inc.id),
                );
              } else {
                navigateToDetailOrEdit(
                  context,
                  transaction,
                ); // Pass the TransactionEntity
              }
            },
            onChangeCategoryRequest: (inc) =>
                handleChangeCategoryRequest(context, transaction),
            onUserCategorized: (inc, cat) {
              final matchData = TransactionMatchData(
                description: inc.title,
                merchantId: null,
              );
              context.read<TransactionListBloc>().add(
                UserCategorizedTransaction(
                  transactionId: inc.id,
                  transactionType: TransactionType.income,
                  selectedCategory: cat,
                  matchData: matchData,
                ),
              );
            },
          );
        }
        // --- END USE ---

        final animatedCard = enableAnimations
            ? cardItem
                  .animate()
                  .fadeIn(delay: (20 * (index % 10)).ms) // Cap delay
                  .slideY(begin: 0.1)
            : cardItem;

        return Dismissible(
          key: ValueKey("${transaction.id}_dismissible"),
          direction: DismissDirection.endToStart,
          background: ColoredBox(
            color: theme.colorScheme.errorContainer,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: context.space.hXl,
                child: Icon(
                  Icons.delete_sweep_outlined,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
          confirmDismiss: (_) async =>
              await confirmDeletion(context, transaction),
          onDismissed: (direction) {
            // BLoC event is dispatched by confirmDismiss callback now
            // context.read<TransactionListBloc>().add(DeleteTransaction(transaction));
          },
          child: isSelected
              ? ColoredBox(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  child: animatedCard,
                )
              : animatedCard,
        );
      },
    );
  }
}
