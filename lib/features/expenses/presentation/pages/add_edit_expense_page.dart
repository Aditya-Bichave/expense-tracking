import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/entities/category.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/add_edit_expense/add_edit_expense_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_form.dart';
// Removed explicit Bloc imports for refresh

class AddEditExpensePage extends StatelessWidget {
  final String? expenseId; // Passed from router for editing
  final Expense? expense; // Passed via router extra for editing

  const AddEditExpensePage({
    super.key,
    this.expenseId,
    this.expense,
  });

  Category _findCategoryById(String categoryId) {
    final predefined = PredefinedCategory.values.firstWhere(
      (e) =>
          Category.fromPredefined(e).name.toLowerCase() ==
          categoryId.toLowerCase(),
      orElse: () => PredefinedCategory.other,
    );
    return Category.fromPredefined(predefined);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = expense != null;

    return BlocProvider(
      create: (context) => sl<AddEditExpenseBloc>(param1: expense),
      child: BlocListener<AddEditExpenseBloc, AddEditExpenseState>(
        listener: (context, state) {
          if (state.status == FormStatus.success) {
            // No explicit refreshes needed here
            debugPrint(
                "Expense save successful, relying on stream for refresh.");

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Expense ${isEditing ? 'updated' : 'added'} successfully!')),
            );
            if (context.canPop()) {
              context.pop();
            }
          } else if (state.status == FormStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
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
              if (state.status == FormStatus.submitting) {
                return const Center(child: CircularProgressIndicator());
              }

              return ExpenseForm(
                initialExpense: state.initialExpense,
                onSubmit: (title, amount, categoryId, accountId, date) {
                  final Category categoryObject = _findCategoryById(categoryId);
                  context.read<AddEditExpenseBloc>().add(
                        SaveExpenseRequested(
                          existingExpenseId: isEditing ? expense?.id : null,
                          title: title,
                          amount: amount,
                          category: categoryObject,
                          date: date,
                          accountId: accountId,
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
