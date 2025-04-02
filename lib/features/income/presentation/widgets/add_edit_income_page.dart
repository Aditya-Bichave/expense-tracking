import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/entities/income_category.dart';
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

  // Helper to find predefined category object by name (case-insensitive)
  IncomeCategory _findIncomeCategoryByName(String categoryName) {
    try {
      // Find the enum value corresponding to the name
      final predefined = PredefinedIncomeCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == categoryName.toLowerCase(),
      );
      // Create the Category object from the enum
      return IncomeCategory.fromPredefined(predefined);
    } catch (e) {
      log.warning(
          "Could not find PredefinedIncomeCategory for name '$categoryName'. Defaulting to Other.");
      return IncomeCategory(
          name:
              categoryName); // Or IncomeCategory.fromPredefined(PredefinedIncomeCategory.other)
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = income != null;
    log.info(
        "[AddEditIncomePage] Build called. Editing: $isEditing, IncomeId: $incomeId");

    return BlocProvider(
      create: (context) => sl<AddEditIncomeBloc>(param1: income),
      child: BlocListener<AddEditIncomeBloc, AddEditIncomeState>(
        listener: (context, state) {
          log.info(
              "[AddEditIncomePage] BlocListener received state: Status=${state.status}");
          if (state.status == FormStatus.success) {
            log.info(
                "[AddEditIncomePage] Form submission successful. Popping route.");
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                      'Income ${isEditing ? 'updated' : 'added'} successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            if (context.canPop()) {
              context.pop();
            } else {
              log.warning(
                  "[AddEditIncomePage] Cannot pop context after successful save.");
              context.goNamed('income_list'); // Fallback
            }
          } else if (state.status == FormStatus.error &&
              state.errorMessage != null) {
            log.warning(
                "[AddEditIncomePage] Form submission error: ${state.errorMessage}");
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
            title: Text(isEditing ? 'Edit Income' : 'Add Income'),
          ),
          body: BlocBuilder<AddEditIncomeBloc, AddEditIncomeState>(
            builder: (context, state) {
              log.info(
                  "[AddEditIncomePage] BlocBuilder building for status: ${state.status}");
              // Animate between loading and form
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: state.status == FormStatus.submitting
                    ? const Center(
                        key: ValueKey('loading'),
                        child: CircularProgressIndicator())
                    : IncomeForm(
                        key: const ValueKey('form'),
                        initialIncome:
                            state.initialIncome, // Use state's income
                        onSubmit: (title, amount, categoryName, accountId, date,
                            notes) {
                          // Expect categoryName
                          log.info(
                              "[AddEditIncomePage] Form submitted. Dispatching SaveIncomeRequested.");
                          // Find category object from name
                          final IncomeCategory categoryObject =
                              _findIncomeCategoryByName(categoryName);
                          context.read<AddEditIncomeBloc>().add(
                                SaveIncomeRequested(
                                  existingIncomeId:
                                      incomeId, // Use incomeId from route param
                                  title: title,
                                  amount: amount,
                                  category: categoryObject, // Pass object
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
