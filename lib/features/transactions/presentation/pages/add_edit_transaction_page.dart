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
  // --- REMOVED _askedCreateCustom flag, use Bloc state flag ---
  // bool _askedCreateCustom = false;
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
    // Bloc lifecycle can be managed by GetIt if registered as factory
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
          _bloc.add(const RejectCategorySuggestion());
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
          // No need to change state, UI stays on form
        }
      });
    });
  }

  // --- Navigate to Add Category ---
  Future<void> _navigateToAddCategory(
      BuildContext context, TransactionType currentType) async {
    log.info(
        "[AddEditTxnPage] Navigating to Add Category screen for type: ${currentType.name}");

    // Use Navigator.push and wait for the result
    final result = await Navigator.of(context).push<Category>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: sl<CategoryManagementBloc>(),
          child: AddEditCategoryScreen(
            // Pass the current transaction type so the Add Category screen knows
            // whether to create an Expense or Income category.
            initialType: currentType == TransactionType.expense
                ? CategoryType.expense
                : CategoryType.income,
          ),
        ),
      ),
    );

    if (!mounted) return; // Check mounted after await

    if (result != null) {
      log.info(
          "[AddEditTxnPage] Received new category from Add screen: ${result.name}. Dispatching CategoryCreated.");
      _bloc.add(CategoryCreated(result));
    } else {
      log.info(
          "[AddEditTxnPage] Add Category screen popped without returning a category. Returning to form.");
      // Reset status to ready to allow user interaction
      // --- Use correct enum ---
      _bloc.emit(_bloc.state.copyWith(status: AddEditStatus.ready));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = _initialTransactionEntity != null;

    // Provide the BLoC instance managed by this stateful widget
    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<AddEditTransactionBloc, AddEditTransactionState>(
        listener: (context, state) {
          log.fine(
              "[AddEditTxnPage] BlocListener: Status=${state.status}, PrevStatus=$_previousStatus, AskCreate=${state.askCreateCategory}");

          // 1. Show Suggestion Dialog
          if (state.status == AddEditStatus.suggestingCategory &&
              _previousStatus != AddEditStatus.suggestingCategory &&
              state.suggestedCategory != null) {
            _showSuggestionDialog(context, state.suggestedCategory!);
          }
          // 2. Ask "Create Custom?" Dialog (Triggered by flag in state)
          else if (state.askCreateCategory && // Check the flag
              !state.isEditing && // Only ask when adding new
              _previousStatus != state.status) {
            // Avoid re-showing on simple rebuilds
            _askCreateCustomCategory(context);
          }
          // 3. Navigate to Add Category
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
            if (context.canPop()) {
              context.pop();
            } else {
              log.warning(
                  "[AddEditTxnPage] Cannot pop context after successful save.");
              context.go(RouteNames.transactionsList);
            }
          }
          // 5. Handle Error
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
            // Reset to ready state to allow user to fix form/retry
            // --- Use correct enum ---
            _bloc.emit(state.copyWith(
                status: AddEditStatus.ready, clearErrorMessage: true));
          }

          // Update previous state tracking *after* processing transitions
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
            // --- Fix BlocProvider.value generic type ---
            // No, BlocBuilder infers the type from context, this part is fine
            builder: (context, state) {
              log.fine("[AddEditTxnPage] BlocBuilder: Status=${state.status}");

              // Show loading indicator for saving/processing/navigating
              if (state.status == AddEditStatus.saving ||
                  state.status == AddEditStatus.loading ||
                  state.status == AddEditStatus.navigatingToCreateCategory) {
                return const Center(child: CircularProgressIndicator());
              }

              // Show the form otherwise (ready, suggesting, error, initial)
              return TransactionForm(
                key: ValueKey(state.transactionType.toString() +
                    (state.initialTransaction?.id ?? 'new')),
                initialTransaction: state.initialTransaction,
                initialType: state.transactionType,
                // --- Pass effective category for pre-filling ---
                initialCategory: state.effectiveCategory,
                onSubmit:
                    (type, title, amount, date, category, accountId, notes) {
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
              );
            },
          ),
        ),
      ),
    );
  }
}


// --- TODO Reminder ---
// 1. Modify AddEditCategoryScreen constructor to accept optional `initialType`
//    and use it to set the initial value of the type dropdown (and maybe disable it).
// 2. Modify AddEditCategoryScreen's submit logic to pop with the created Category object.
// 3. Modify TransactionForm to accept `initialCategory` parameter and use it in initState.
// 4. Refine the state transition logic in the BlocListener if needed.