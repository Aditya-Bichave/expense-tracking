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
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/core/utils/currency_parser.dart';
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
  late final AddEditTransactionBloc _bloc;
  TransactionEntity? _initialTransactionEntity;
  AddEditStatus? _previousStatus; // Track previous status
  final GlobalKey<TransactionFormState> _formKey =
      GlobalKey<TransactionFormState>();
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    _bloc = sl<AddEditTransactionBloc>();

    if (widget.initialTransactionData is Expense) {
      _initialTransactionEntity = TransactionEntity.fromExpense(
        widget.initialTransactionData as Expense,
      );
    } else if (widget.initialTransactionData is Income) {
      _initialTransactionEntity = TransactionEntity.fromIncome(
        widget.initialTransactionData as Income,
      );
    } else if (widget.initialTransactionData is TransactionEntity) {
      _initialTransactionEntity =
          widget.initialTransactionData as TransactionEntity;
    } else if (widget.initialTransactionData != null) {
      log.warning(
        "[AddEditTxnPage] Received unexpected initial data type: ${widget.initialTransactionData.runtimeType}",
      );
    }

    _bloc.add(
      InitializeTransaction(initialTransaction: _initialTransactionEntity),
    );
    _previousStatus = _bloc.state.status;
    log.info(
      "[AddEditTxnPage] initState complete. Initial Entity ID: ${_initialTransactionEntity?.id}",
    );
  }

  @override
  void dispose() {
    // If the Bloc was created here, dispose it. But it's from sl, so no dispose needed.
    super.dispose();
  }

  void _showSuggestionDialog(BuildContext context, Category suggestedCategory) {
    log.info(
      "[AddEditTxnPage] Showing suggestion dialog for '${suggestedCategory.name}'.",
    );
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

  void _askCreateCustomCategory(BuildContext context) {
    log.info(
      "[AddEditTxnPage] Asking user if they want to create a custom category.",
    );
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
          final formState = _formKey.currentState;
          if (formState != null) {
            final settings = context.read<SettingsBloc>().state;
            final locale = settings.selectedCountryCode;
            final title = formState.currentTitle.trim();
            final amount = parseCurrency(formState.currentAmountRaw, locale);
            final notesText = formState.currentNotes.trim();
            _bloc.add(
              CreateCustomCategoryRequested(
                title: title,
                amount: amount,
                date: formState.currentDate,
                accountId: formState.currentAccountId ?? '',
                notes: notesText.isEmpty ? null : notesText,
              ),
            );
          }
        } else {
          log.info(
            "[AddEditTxnPage] User chose/cancelled to select an existing category.",
          );
          _bloc.emit(
            _bloc.state.copyWith(status: AddEditStatus.ready),
          ); // Go back to ready
          if (create == false) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text("Please select a category manually."),
                ),
              );
          }
        }
      });
    });
  }

  Future<void> _navigateToAddCategory(
    BuildContext context,
    TransactionType currentType,
  ) async {
    log.info(
      "[AddEditTxnPage] Navigating to Add Category screen for type: ${currentType.name}",
    );
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
        "[AddEditTxnPage] Received new category from Add screen: ${result.name}. Dispatching CategoryCreated.",
      );
      _bloc.add(CategoryCreated(result));
    } else {
      log.info(
        "[AddEditTxnPage] Add Category screen popped without returning a category. Returning to form (ready state).",
      );
      _bloc.emit(_bloc.state.copyWith(status: AddEditStatus.ready));
    }
  }

  bool _hasUnsavedChanges() {
    final formState = _formKey.currentState;
    if (formState == null) return false;

    // Get current values
    final currentTitle = formState.currentTitle.trim();
    final currentAmountRaw = formState.currentAmountRaw.trim();
    final currentNotes = formState.currentNotes.trim();

    // If Adding (no initial transaction)
    if (_initialTransactionEntity == null) {
      return currentTitle.isNotEmpty ||
          currentAmountRaw.isNotEmpty ||
          currentNotes.isNotEmpty;
    }

    // If Editing
    final settings = context.read<SettingsBloc>().state;
    final locale = settings.selectedCountryCode;
    final currentAmount = parseCurrency(currentAmountRaw, locale);

    final initialTitle = _initialTransactionEntity!.title;
    final initialAmount = _initialTransactionEntity!.amount;
    final initialNotes = _initialTransactionEntity!.notes ?? '';

    if (currentTitle != initialTitle) return true;
    if ((currentAmount - initialAmount).abs() > 0.001) return true;
    if (currentNotes != initialNotes) return true;

    // Check Category
    final currentCatId = formState.selectedCategory?.id;
    final initialCatId = _initialTransactionEntity!.category?.id;
    if (currentCatId != initialCatId) return true;

    // Check Account
    final currentAccId = formState.currentAccountId;
    final initialAccId = _initialTransactionEntity!.accountId;
    if (currentAccId != initialAccId) return true;

    return false;
  }

  Future<void> _confirmDiscard() async {
    if (_hasUnsavedChanges()) {
      final discard = await AppDialogs.showConfirmation(
        context,
        title: "Discard Changes?",
        content:
            "You have unsaved changes. Are you sure you want to discard them?",
        confirmText: "Discard",
        cancelText: "Keep Editing",
        confirmColor: Theme.of(context).colorScheme.error,
      );

      if (discard == true) {
        _proceedToPop();
      }
    } else {
      _proceedToPop();
    }
  }

  void _proceedToPop() {
    if (!mounted) return;
    setState(() {
      _canPop = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RouteNames.transactionsList);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = _initialTransactionEntity != null;

    return BlocProvider.value(
      value: _bloc,
      child: BlocListener<AddEditTransactionBloc, AddEditTransactionState>(
        listener: (context, state) {
          log.fine(
            "[AddEditTxnPage] BlocListener: Status=${state.status}, PrevStatus=$_previousStatus, Suggestion=${state.suggestedCategory?.name}",
          );

          // --- Handle State Transitions for Dialogs/Navigation ---

          // 1. Show Suggestion Dialog
          if (state.status == AddEditStatus.suggestingCategory &&
              _previousStatus != AddEditStatus.suggestingCategory &&
              state.suggestedCategory != null) {
            _showSuggestionDialog(context, state.suggestedCategory!);
          }
          // --- CORRECTED: Check for askingCreateCategory status ---
          // 2. Ask "Create Custom?" Dialog (Triggered by status)
          else if (state.status == AddEditStatus.askingCreateCategory &&
              _previousStatus != AddEditStatus.askingCreateCategory) {
            _askCreateCustomCategory(context);
          }
          // --- END CORRECTION ---
          // 3. Navigate to Add Category (Triggered by dedicated state)
          else if (state.status == AddEditStatus.navigatingToCreateCategory &&
              _previousStatus != AddEditStatus.navigatingToCreateCategory) {
            _navigateToAddCategory(context, state.transactionType);
          }
          // 4. Handle Final Success
          else if (state.status == AddEditStatus.success &&
              _previousStatus != AddEditStatus.success) {
            log.info(
              "[AddEditTxnPage] Transaction save successful. Popping route.",
            );
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    'Transaction ${isEditing ? 'updated' : 'added'} successfully!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
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
              "[AddEditTxnPage] Transaction save/process error: ${state.errorMessage}",
            );
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.errorMessage}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _bloc.add(const ClearMessages());
            });
          }

          // Update previous state tracking *after* handling transitions
          _previousStatus = state.status;
        },
        child: PopScope(
          canPop: _canPop,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            await _confirmDiscard();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(isEditing ? 'Edit Transaction' : 'Add Transaction'),
              leading: IconButton(
                key: const ValueKey('button_addEditTransaction_close'),
                icon: const Icon(Icons.close),
                tooltip: 'Cancel',
                onPressed: _confirmDiscard,
              ),
            ),
            body: BlocBuilder<AddEditTransactionBloc, AddEditTransactionState>(
              builder: (context, state) {
                log.fine(
                    "[AddEditTxnPage] BlocBuilder: Status=${state.status}");

                final bool isLoadingOverlayVisible = state.status ==
                        AddEditStatus.saving ||
                    state.status == AddEditStatus.loading ||
                    state.status == AddEditStatus.navigatingToCreateCategory;

                return Stack(
                  children: [
                    TransactionForm(
                      key: _formKey,
                      initialTransaction: state.isEditing
                          ? (state.transactionType == TransactionType.expense
                              ? TransactionEntity.fromExpense(
                                  Expense(
                                    id: state.transactionId!,
                                    title: state.tempTitle ?? '',
                                    amount: state.tempAmount ?? 0,
                                    date: state.tempDate ?? DateTime.now(),
                                    category: state.category,
                                    accountId: state.tempAccountId ?? '',
                                  ),
                                )
                              : TransactionEntity.fromIncome(
                                  Income(
                                    id: state.transactionId!,
                                    title: state.tempTitle ?? '',
                                    amount: state.tempAmount ?? 0,
                                    date: state.tempDate ?? DateTime.now(),
                                    category: state.category,
                                    accountId: state.tempAccountId ?? '',
                                    notes: state.tempNotes,
                                  ),
                                ))
                          : null,
                      initialType: state.transactionType,
                      initialCategory: state.effectiveCategory,
                      initialTitle: state.tempTitle,
                      initialAmount: state.tempAmount,
                      initialDate: state.tempDate,
                      initialAccountId: state.tempAccountId,
                      initialNotes: state.tempNotes,
                      onSubmit: (
                        type,
                        title,
                        amount,
                        date,
                        category,
                        accountId,
                        notes,
                      ) {
                        log.info(
                          "[AddEditTxnPage] Form submitted via callback. Dispatching SaveTransactionRequested.",
                        );
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
                          color: Colors.black.withOpacity(0.1),
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
