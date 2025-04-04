import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart'; // Import CategoryType
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/widgets/transaction_form.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// Import AddEditCategoryScreen and CategoryManagementBloc for navigation
import 'package:expense_tracker/features/categories/presentation/pages/add_edit_category_screen.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
// Import specific entities for type checking initial data
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';

class AddEditTransactionPage extends StatefulWidget {
  final dynamic initialTransactionData;

  const AddEditTransactionPage({super.key, this.initialTransactionData});

  @override
  State<AddEditTransactionPage> createState() => _AddEditTransactionPageState();
}

class _AddEditTransactionPageState extends State<AddEditTransactionPage> {
  late final AddEditTransactionBloc _bloc;
  TransactionEntity? _initialTransactionEntity;
  // Removed _askedCreateCustom flag, rely on Bloc state flag
  AddEditStatus? _previousStatus;

  @override
  void initState() {
    super.initState();
    _bloc = sl<AddEditTransactionBloc>();

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

    _bloc.add(
        InitializeTransaction(initialTransaction: _initialTransactionEntity));
    log.info(
        "[AddEditTxnPage] initState complete. Initial Entity ID: ${_initialTransactionEntity?.id}");
  }

  @override
  void dispose() {
    super.dispose();
  }

  // --- Suggestion Dialog ---
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
        if (confirmed == true) {
          log.info("[AddEditTxnPage] Suggestion accepted.");
          _bloc.add(AcceptCategorySuggestion(suggestedCategory));
        } else {
          log.info("[AddEditTxnPage] Suggestion rejected.");
          _bloc.add(
              const RejectCategorySuggestion()); // Bloc will handle setting ask flag
        }
      });
    });
  }

  // --- Ask Create Custom Dialog ---
  void _askCreateCustomCategory(BuildContext context) {
    log.info(
        "[AddEditTxnPage] Asking user if they want to create a custom category.");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
        // Clear the ask flag regardless of choice, as the dialog was shown
        _bloc.emit(_bloc.state.copyWith(clearAskCreateFlag: true));

        if (create == true) {
          log.info("[AddEditTxnPage] User chose to create a new category.");
          _bloc.add(const CreateCustomCategoryRequested());
        } else {
          log.info(
              "[AddEditTxnPage] User chose to select an existing category.");
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
                content: Text("Please select a category manually.")));
          // Status is already 'ready', user can now use the form picker
        }
      });
    });
  }

  // --- Navigate to Add Category Screen ---
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
          child: AddEditCategoryScreen(
            initialType: categoryType, // Pass the type
          ),
        ),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      log.info(
          "[AddEditTxnPage] Received new category from Add screen: ${result.name}. Dispatching CategoryCreated.");
      _bloc.add(CategoryCreated(result));
    } else {
      log.info(
          "[AddEditTxnPage] Add Category screen popped without returning a category. Returning to form.");
      _bloc.emit(_bloc.state.copyWith(status: AddEditStatus.ready));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = _initialTransactionEntity != null;

    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<AddEditTransactionBloc, AddEditTransactionState>(
        listener: (context, state) {
          log.fine(
              "[AddEditTxnPage] BlocListener: Status=${state.status}, PrevStatus=$_previousStatus, Suggestion=${state.suggestedCategory?.name}, AskCreate=${state.askCreateCategory}");

          // --- Handle State Transitions for Dialogs/Navigation ---

          // 1. Show Suggestion Dialog
          if (state.status == AddEditStatus.suggestingCategory &&
              _previousStatus != AddEditStatus.suggestingCategory &&
              state.suggestedCategory != null) {
            _showSuggestionDialog(context, state.suggestedCategory!);
          }
          // 2. Ask "Create Custom?" Dialog (Triggered by flag)
          else if (state.askCreateCategory &&
              _previousStatus !=
                  AddEditStatus.initial /* Avoid triggering on init */) {
            // Check the flag directly
            _askCreateCustomCategory(context);
          }
          // 3. Navigate to Add Category (Triggered by dedicated state)
          else if (state.status == AddEditStatus.navigatingToCreateCategory &&
              _previousStatus != AddEditStatus.navigatingToCreateCategory) {
            _navigateToAddCategory(context, state.transactionType);
          }
          // 4. Handle Final Success
          else if (state.status == AddEditStatus.success &&
              _previousStatus != AddEditStatus.success) {
            log.info(
                "[AddEditTxnPage] Transaction save successful. Popping route.");
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                      'Transaction ${isEditing ? 'updated' : 'added'} successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            // Pop after showing snackbar
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && context.canPop()) {
                context.pop();
              } else if (mounted) {
                context.go(RouteNames.transactionsList);
              }
            });
          }
          // 5. Handle Error State
          else if (state.status == AddEditStatus.error &&
              state.errorMessage != null &&
              _previousStatus != AddEditStatus.error) {
            log.warning(
                "[AddEditTxnPage] Transaction save/process error: ${state.errorMessage}");
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.errorMessage}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                // Dispatch event to clear error and reset status
                _bloc.add(const ClearMessages());
                // Setting status directly here might be overridden if ClearMessages does it
                _bloc.emit(_bloc.state.copyWith(status: AddEditStatus.ready));
              }
            });
          }

          // Update previous state tracking
          _previousStatus = state.status;
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

              final isLoadingOverlayVisible = state.status ==
                      AddEditStatus.saving ||
                  state.status == AddEditStatus.loading || // General loading
                  state.status == AddEditStatus.navigatingToCreateCategory;

              return Stack(
                children: [
                  // The actual form
                  TransactionForm(
                    key: ValueKey(state.transactionType.toString() +
                        (state.initialTransaction?.id ?? 'new') +
                        (state.effectiveCategory?.id ?? 'none')),
                    initialTransaction: state.initialTransaction,
                    initialType: state.transactionType,
                    initialCategory:
                        state.effectiveCategory, // Pass effective category
                    onSubmit: (type, title, amount, date, category, accountId,
                        notes) {
                      log.info(
                          "[AddEditTxnPage] Form submitted via callback. Dispatching SaveTransactionRequested.");
                      context.read<AddEditTransactionBloc>().add(
                            SaveTransactionRequested(
                              title: title, amount: amount, date: date,
                              category: category, // Category from form
                              accountId: accountId, notes: notes,
                            ),
                          );
                    },
                  ),
                  // Loading Overlay
                  if (isLoadingOverlayVisible)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.1),
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
