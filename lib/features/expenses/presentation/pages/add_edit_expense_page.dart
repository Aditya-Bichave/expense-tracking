import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/entities/category.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/add_edit_expense/add_edit_expense_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_form.dart';
import 'package:expense_tracker/core/utils/enums.dart'; // Shared FormStatus
import 'package:expense_tracker/main.dart'; // Import logger

class AddEditExpensePage extends StatelessWidget {
  final String? expenseId; // Passed from router for editing
  final Expense? expense; // Passed via router extra for editing

  const AddEditExpensePage({
    super.key,
    this.expenseId,
    this.expense,
  });

  // Helper to find predefined category object by name (case-insensitive)
  Category _findCategoryByName(String categoryName) {
    try {
      // Find the enum value corresponding to the name
      final predefined = PredefinedCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == categoryName.toLowerCase(),
        // orElse: () => PredefinedCategory.other, // Handled by catch
      );
      // Create the Category object from the enum
      return Category.fromPredefined(predefined);
    } catch (e) {
      log.warning(
          "Could not find PredefinedCategory for name '$categoryName'. Defaulting to Other.");
      // If name doesn't match any predefined enum, return a custom 'Other' or the name itself
      return Category(
          name:
              categoryName); // Or Category.fromPredefined(PredefinedCategory.other)
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = expense != null;
    log.info(
        "[AddEditExpensePage] Build called. Editing: $isEditing, ExpenseId: $expenseId");

    return BlocProvider(
      create: (context) => sl<AddEditExpenseBloc>(param1: expense),
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
              context.goNamed('expenses_list'); // Fallback
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
              // Animate between loading and form
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: state.status == FormStatus.submitting
                    ? const Center(
                        key: ValueKey('loading'),
                        child: CircularProgressIndicator())
                    : ExpenseForm(
                        key: const ValueKey('form'),
                        initialExpense:
                            state.initialExpense, // Use state's expense
                        onSubmit:
                            (title, amount, categoryName, accountId, date) {
                          // Changed categoryId to categoryName
                          log.info(
                              "[AddEditExpensePage] Form submitted. Dispatching SaveExpenseRequested.");
                          // Find category object from name before dispatching
                          final Category categoryObject =
                              _findCategoryByName(categoryName);
                          context.read<AddEditExpenseBloc>().add(
                                SaveExpenseRequested(
                                  existingExpenseId:
                                      expenseId, // Use expenseId from route param
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
