import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
// REMOVE old income category import:
// import 'package:expense_tracker/features/income/domain/entities/income_category.dart';
// Use UNIFIED Category entity
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/income/presentation/bloc/add_edit_income/add_edit_income_bloc.dart';
import 'package:expense_tracker/features/income/presentation/widgets/income_form.dart';
import 'package:expense_tracker/core/utils/enums.dart'; // Shared FormStatus
import 'package:expense_tracker/main.dart'; // Import logger

class AddEditIncomePage extends StatelessWidget {
  final String? incomeId;
  final Income? income;

  const AddEditIncomePage({
    super.key,
    this.incomeId,
    this.income,
  });

  // REMOVE old helper function:
  // IncomeCategory _findIncomeCategoryByName(String categoryName) { ... }

  @override
  Widget build(BuildContext context) {
    final isEditing = income != null;
    log.info(
        "[AddEditIncomePage] Build called. Editing: $isEditing, IncomeId: $incomeId");

    return BlocProvider(
      // Assuming AddEditIncomeBloc fetches dependencies via sl
      create: (context) => sl<AddEditIncomeBloc>(param1: income),
      child: BlocListener<AddEditIncomeBloc, AddEditIncomeState>(
        listener: (context, state) {
          // ... (listener logic remains the same) ...
          log.info(
              "[AddEditIncomePage] BlocListener received state: Status=${state.status}");
          if (state.status == FormStatus.success) {
            /* ... success handling ... */
            log.info(
                "[AddEditIncomePage] Form submission successful. Popping route.");
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(
                    'Income ${isEditing ? 'updated' : 'added'} successfully!'),
                backgroundColor: Colors.green,
              ));
            if (context.canPop()) {
              context.pop();
            } else {
              log.warning(
                  "[AddEditIncomePage] Cannot pop context after successful save.");
              context.goNamed('income_list');
            }
          } else if (state.status == FormStatus.error &&
              state.errorMessage != null) {
            /* ... error handling ... */
            log.warning(
                "[AddEditIncomePage] Form submission error: ${state.errorMessage}");
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text('Error: ${state.errorMessage}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ));
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(isEditing ? 'Edit Income' : 'Add Income'),
          ),
          body: BlocBuilder<AddEditIncomeBloc, AddEditIncomeState>(
            builder: (context, state) {
              log.info(
                  "[AddEditIncomePage] BlocBuilder building for status: ${state.status}");
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: state.status == FormStatus.submitting
                    ? const Center(
                        key: ValueKey('loading'),
                        child: CircularProgressIndicator())
                    : IncomeForm(
                        key: const ValueKey('form'),
                        initialIncome: state.initialIncome,
                        // CORRECTED onSubmit signature
                        onSubmit: (title, amount, categoryObject, accountId,
                            date, notes) {
                          log.info(
                              "[AddEditIncomePage] Form submitted. Dispatching SaveIncomeRequested.");
                          // Directly use the categoryObject passed from the form
                          context.read<AddEditIncomeBloc>().add(
                                SaveIncomeRequested(
                                  existingIncomeId: incomeId,
                                  title: title,
                                  amount: amount,
                                  category:
                                      categoryObject, // Pass the Category object
                                  accountId: accountId,
                                  date: date,
                                  notes: notes,
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
