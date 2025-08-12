// lib/features/transactions/presentation/pages/add_edit_transaction_page.dart
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_form.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/categories/presentation/pages/add_edit_category_screen.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';

class AddEditTransactionPage extends StatefulWidget {
  final dynamic initialTransactionData;

  const AddEditTransactionPage({super.key, this.initialTransactionData});

  @override
  State<AddEditTransactionPage> createState() => _AddEditTransactionPageState();
}

class _AddEditTransactionPageState extends State<AddEditTransactionPage> {
  TransactionEntity? _initialTransactionEntity;

  @override
  void initState() {
    super.initState();
    // Prepare the initial entity but do not create the BLoC here.
    if (widget.initialTransactionData is Expense) {
      _initialTransactionEntity = TransactionEntity.fromExpense(
          widget.initialTransactionData as Expense);
    } else if (widget.initialTransactionData is Income) {
      _initialTransactionEntity =
          TransactionEntity.fromIncome(widget.initialTransactionData as Income);
    } else if (widget.initialTransactionData is TransactionEntity) {
      _initialTransactionEntity =
          widget.initialTransactionData as TransactionEntity;
    } else if (widget.initialTransactionData != null) {
      log.warning(
          "[AddEditTxnPage] Received unexpected initial data type: ${widget.initialTransactionData.runtimeType}");
    }
    log.info(
        "[AddEditTxnPage] initState complete. Initial Entity ID: ${_initialTransactionEntity?.id}");
  }

  void _showSuggestionDialog(BuildContext context, Category suggestedCategory) {
    log.info(
        "[AddEditTxnPage] Showing suggestion dialog for '${suggestedCategory.name}'.");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppDialogs.showConfirmation(
        context,
        title: "Suggestion",
        content: "Did you mean '${suggestedCategory.name}'?",
        confirmText: "Yes, use it",
        cancelText: "No, pick myself",
        barrierDismissible: false,
      ).then((confirmed) {
        if (!mounted) return;
        final bloc = context.read<AddEditTransactionBloc>();
        if (confirmed == true) {
          log.info("[AddEditTxnPage] Suggestion accepted.");
          bloc.add(AcceptCategorySuggestion(suggestedCategory));
        } else {
          log.info("[AddEditTxnPage] Suggestion rejected.");
          bloc.add(const RejectCategorySuggestion());
        }
      });
    });
  }

  void _askCreateCustomCategory(BuildContext context) {
    log.info(
        "[AddEditTxnPage] Asking user if they want to create a custom category.");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<AddEditTransactionBloc>();
      AppDialogs.showConfirmation(
        context,
        title: "Choose Category",
        content:
            "We couldn't find a matching category. Would you like to create a new one or select an existing category?",
        confirmText: "Create New",
        cancelText: "Select Existing",
        barrierDismissible: false,
      ).then((create) {
        if (!mounted) return;
        if (create == true) {
          log.info("[AddEditTxnPage] User chose to create a new category.");
          bloc.add(const CreateCustomCategoryRequested());
        } else {
          log.info(
              "[AddEditTxnPage] User chose/cancelled to select an existing category.");
          bloc.emit(bloc.state
              .copyWith(status: AddEditStatus.ready)); // Go back to ready
          if (create == false) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(
                  content: Text("Please select a category manually.")));
          }
        }
      });
    });
  }

  Future<void> _navigateToAddCategory(
      BuildContext context, TransactionType currentType) async {
    log.info(
        "[AddEditTxnPage] Navigating to Add Category screen for type: ${currentType.name}");
    final categoryType = currentType == TransactionType.expense
        ? CategoryType.expense
        : CategoryType.income;

    final result = await Navigator.of(context).push<Category>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: sl<CategoryManagementBloc>(),
          child: AddEditCategoryScreen(initialType: categoryType),
        ),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      log.info(
          "[AddEditTxnPage] Received new category from Add screen: ${result.name}. Dispatching CategoryCreated.");
      context.read<AddEditTransactionBloc>().add(CategoryCreated(result));
    } else {
      log.info(
          "[AddEditTxnPage] Add Category screen popped without returning a category. Returning to form (ready state).");
      context
          .read<AddEditTransactionBloc>()
          .emit(context.read<AddEditTransactionBloc>().state.copyWith(status: AddEditStatus.ready));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = _initialTransactionEntity != null;

    return BlocProvider(
      create: (context) => sl<AddEditTransactionBloc>()
        ..add(InitializeTransaction(initialTransaction: _initialTransactionEntity)),
      child: BlocListener<AddEditTransactionBloc, AddEditTransactionState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          log.fine(
              "[AddEditTxnPage] BlocListener: Status=${state.status}, Suggestion=${state.suggestedCategory?.name}");

          // 1. Show Suggestion Dialog
          if (state.status == AddEditStatus.suggestingCategory &&
              state.suggestedCategory != null) {
            _showSuggestionDialog(context, state.suggestedCategory!);
          }
          // 2. Ask "Create Custom?" Dialog
          else if (state.status == AddEditStatus.askingCreateCategory) {
            _askCreateCustomCategory(context);
          }
          // 3. Navigate to Add Category
          else if (state.status == AddEditStatus.navigatingToCreateCategory) {
            _navigateToAddCategory(context, state.transactionType);
          }
          // 4. Handle Final Success
          else if (state.status == AddEditStatus.success) {
            log.info(
                "[AddEditTxnPage] Transaction save successful. Popping route.");
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                  content: Text(
                      'Transaction ${isEditing ? 'updated' : 'added'} successfully!'),
                  backgroundColor: Colors.green));
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && context.canPop()) {
                context.pop();
              } else if (mounted) {
                context.go(RouteNames.transactionsList);
              }
            });
          }
          // 5. Handle Error State
          else if (state.status == AddEditStatus.error && state.errorMessage != null) {
            log.warning(
                "[AddEditTxnPage] Transaction save/process error: ${state.errorMessage}");
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                  content: Text('Error: ${state.errorMessage}'),
                  backgroundColor: Theme.of(context).colorScheme.error));
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.read<AddEditTransactionBloc>().add(const ClearMessages());
              }
            });
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(RouteNames.transactionsList);
                }
              },
            ),
          ),
          body: BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
            builder: (context, state) {
              log.fine("[AddEditTxnPage] BlocBuilder: Status=${state.status}");

              final bool isLoadingOverlayVisible =
                  state.status == AddEditStatus.saving ||
                      state.status == AddEditStatus.loading ||
                      state.status == AddEditStatus.navigatingToCreateCategory;

              return Stack(
                children: [
                  TransactionForm(
                    key: ValueKey(state.transactionType.toString() +
                        (state.initialTransaction?.id ?? 'new')),
                    initialTransaction: state.initialTransaction,
                    initialType: state.transactionType,
                    initialCategory: state.effectiveCategory,
                    onSubmit: (type, title, amount, date, category, accountId,
                        notes) {
                      log.info(
                          "[AddEditTxnPage] Form submitted via callback. Dispatching SaveTransactionRequested.");
                      context.read<AddEditTransactionBloc>().add(
                            SaveTransactionRequested(
                              title: title,
                              amount: amount,
                              date: date,
                              category: category,
                              accountId: accountId,
                              notes: notes,
                            ),
                          );
                    },
                  ),
                  if (isLoadingOverlayVisible)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withAlpha((255 * 0.1).round()),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
