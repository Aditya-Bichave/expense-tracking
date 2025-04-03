import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
// Import Unified Category entity
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
// REMOVE Old Category import:
// import 'package:expense_tracker/features/expenses/domain/entities/category.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/add_edit_expense/add_edit_expense_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_form.dart';
import 'package:expense_tracker/core/utils/enums.dart';
import 'package:expense_tracker/main.dart';

class AddEditExpensePage extends StatelessWidget {
  final String? expenseId;
  final Expense? expense; // Passed via router extra for editing

  const AddEditExpensePage({
    super.key,
    this.expenseId,
    this.expense,
  });

  // REMOVED: _findCategoryByName (no longer needed as form passes full Category object)
  // Category _findCategoryByName(String categoryName) { ... }

  @override
  Widget build(BuildContext context) {
    final isEditing = expense != null;
    log.info(
        "[AddEditExpensePage] Build called. Editing: $isEditing, ExpenseId: $expenseId");

    // Provide the necessary dependencies to the AddEditExpenseBloc
    return BlocProvider(
      create: (context) => sl<AddEditExpenseBloc>(
        param1: expense, // Pass initial expense if editing
        // We need to ensure that CategorizeTransactionUseCase and ExpenseRepository are registered in sl
        // The create method in BlocProvider doesn't directly allow passing extra params like this easily.
        // Instead, ensure AddEditExpenseBloc fetches dependencies from sl itself or modify sl registration.
        // Assuming AddEditExpenseBloc constructor fetches from sl:
        // create: (context) => sl<AddEditExpenseBloc>(param1: expense),
        // OR If AddEditExpenseBloc doesn't use sl internally:
        // create: (context) => AddEditExpenseBloc(
        //    addExpenseUseCase: sl(), updateExpenseUseCase: sl(),
        //    categorizeTransactionUseCase: sl(), expenseRepository: sl(), // Manually provide deps
        //    initialExpense: expense,
        // ),
      ),
      child: BlocListener<AddEditExpenseBloc, AddEditExpenseState>(
        listener: (context, state) {
          log.info(
              "[AddEditExpensePage] BlocListener received state: Status=${state.status}");
          if (state.status == FormStatus.success) {
            log.info(
                "[AddEditExpensePage] Form submission successful. Popping route.");
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                      'Expense ${isEditing ? 'updated' : 'added'} successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            if (context.canPop()) {
              context.pop();
            } else {
              log.warning(
                  "[AddEditExpensePage] Cannot pop context after successful save.");
              context.goNamed(
                  'expenses_list'); // Fallback using route name constant
            }
          } else if (state.status == FormStatus.error &&
              state.errorMessage != null) {
            log.warning(
                "[AddEditExpensePage] Form submission error: ${state.errorMessage}");
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.errorMessage}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
          ),
          body: BlocBuilder<AddEditExpenseBloc, AddEditExpenseState>(
            builder: (context, state) {
              log.info(
                  "[AddEditExpensePage] BlocBuilder building for status: ${state.status}");
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: state.status == FormStatus.submitting
                    ? const Center(
                        key: ValueKey('loading'),
                        child: CircularProgressIndicator())
                    : ExpenseForm(
                        key: const ValueKey('form'),
                        initialExpense: state.initialExpense,
                        // UPDATED onSubmit signature to expect Category object
                        onSubmit:
                            (title, amount, categoryObject, accountId, date) {
                          log.info(
                              "[AddEditExpensePage] Form submitted. Dispatching SaveExpenseRequested.");
                          // Directly use the categoryObject passed from the form
                          context.read<AddEditExpenseBloc>().add(
                                SaveExpenseRequested(
                                  existingExpenseId: expenseId,
                                  title: title,
                                  amount: amount,
                                  category:
                                      categoryObject, // Pass the Category object
                                  date: date,
                                  accountId: accountId,
                                ),
                              );
                        },
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}
