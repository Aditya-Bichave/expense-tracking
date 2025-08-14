import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/widgets/app_dropdown_form_field.dart';
import 'package:expense_tracker/core/widgets/common_form_fields.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_selection_widget.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_enums.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/bloc/add_edit_recurring_rule/add_edit_recurring_rule_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AddEditRecurringRulePage extends StatelessWidget {
  final RecurringRule? initialRule;

  const AddEditRecurringRulePage({super.key, this.initialRule});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = sl<AddEditRecurringRuleBloc>();
        if (initialRule != null) {
          bloc.add(InitializeForEdit(initialRule!));
        }
        return bloc;
      },
      child: AddEditRecurringRuleView(initialRule: initialRule),
    );
  }
}

class AddEditRecurringRuleView extends StatefulWidget {
  final RecurringRule? initialRule;
  const AddEditRecurringRuleView({super.key, this.initialRule});

  @override
  State<AddEditRecurringRuleView> createState() =>
      _AddEditRecurringRuleViewState();
}

class _AddEditRecurringRuleViewState extends State<AddEditRecurringRuleView> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final TextEditingController _intervalController;
  late final TextEditingController _occurrencesController;

  List<String> _weekdayNamesMonFirst([String? locale]) {
    final sundayFirst =
        DateFormat.EEEE(locale).dateSymbols.WEEKDAYS; // [Sun, Mon, ..., Sat]
    return [...sundayFirst.skip(1), sundayFirst.first]; // [Mon, Tue, ..., Sun]
  }

  @override
  void initState() {
    super.initState();
    final state = context.read<AddEditRecurringRuleBloc>().state;
    _descriptionController = TextEditingController(text: state.description);
    _amountController = TextEditingController(
        text: state.amount == 0 ? '' : state.amount.toString());
    _intervalController =
        TextEditingController(text: state.interval.toString());
    _occurrencesController =
        TextEditingController(text: state.totalOccurrences?.toString() ?? '');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _intervalController.dispose();
    _occurrencesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialRule == null
            ? 'Add Recurring Rule'
            : 'Edit Recurring Rule'),
      ),
      body: BlocConsumer<AddEditRecurringRuleBloc, AddEditRecurringRuleState>(
        listener: (context, state) {
          if (state.status == FormStatus.success) {
            Navigator.of(context).pop();
          } else if (state.status == FormStatus.failure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                    content: Text(state.errorMessage ?? 'An error occurred.')),
              );
          }

          if (_descriptionController.text != state.description) {
            _descriptionController.text = state.description;
          }
          if (_amountController.text !=
              (state.amount == 0 ? '' : state.amount.toString())) {
            _amountController.text =
                state.amount == 0 ? '' : state.amount.toString();
          }
          if (_intervalController.text != state.interval.toString()) {
            _intervalController.text = state.interval.toString();
          }
          if (_occurrencesController.text !=
              (state.totalOccurrences?.toString() ?? '')) {
            _occurrencesController.text =
                state.totalOccurrences?.toString() ?? '';
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CommonFormFields.buildTypeToggle(
                    context: context,
                    initialIndex:
                        state.transactionType == TransactionType.expense
                            ? 0
                            : 1,
                    labels: const ['Expense', 'Income'],
                    activeBgColors: [
                      [
                        theme.colorScheme.errorContainer.withOpacity(0.7),
                        theme.colorScheme.errorContainer
                      ],
                      [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.primaryContainer.withOpacity(0.7)
                      ]
                    ],
                    onToggle: (index) {
                      if (index != null) {
                        final newType = index == 0
                            ? TransactionType.expense
                            : TransactionType.income;
                        context
                            .read<AddEditRecurringRuleBloc>()
                            .add(TransactionTypeChanged(newType));
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    onChanged: (value) => context
                        .read<AddEditRecurringRuleBloc>()
                        .add(DescriptionChanged(value)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => context
                        .read<AddEditRecurringRuleBloc>()
                        .add(AmountChanged(value)),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.category),
                    title:
                        Text(state.selectedCategory?.name ?? 'Select Category'),
                    onTap: () async {
                      final category = await showCategoryPicker(
                        context,
                        state.transactionType == TransactionType.expense
                            ? CategoryTypeFilter.expense
                            : CategoryTypeFilter.income,
                      );
                      if (category != null) {
                        context
                            .read<AddEditRecurringRuleBloc>()
                            .add(CategoryChanged(category));
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  AccountSelectorDropdown(
                    selectedAccountId: state.accountId,
                    onChanged: (value) => context
                        .read<AddEditRecurringRuleBloc>()
                        .add(AccountChanged(value)),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  AppDropdownFormField<Frequency>(
                    labelText: 'Frequency',
                    value: state.frequency,
                    items: Frequency.values
                        .map((f) =>
                            DropdownMenuItem(value: f, child: Text(f.name)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context
                            .read<AddEditRecurringRuleBloc>()
                            .add(FrequencyChanged(value));
                      }
                    },
                  ),
                  const SizedBox(height: 8), // Smaller gap here
                  if (state.frequency == Frequency.daily)
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(
                          state.startTime?.format(context) ?? 'Select Time'),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: state.startTime ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          context
                              .read<AddEditRecurringRuleBloc>()
                              .add(TimeChanged(time));
                        }
                      },
                    ),
                  if (state.frequency == Frequency.weekly)
                    AppDropdownFormField<int>(
                      labelText: 'Day of Week',
                      value: state.dayOfWeek,
                      items: List.generate(
                          7,
                          (index) => DropdownMenuItem(
                                value: index + 1,
                                child: Text(_weekdayNamesMonFirst()[index]),
                              )),
                      onChanged: (value) {
                        if (value != null) {
                          context
                              .read<AddEditRecurringRuleBloc>()
                              .add(DayOfWeekChanged(value));
                        }
                      },
                    ),
                  if (state.frequency == Frequency.monthly)
                    AppDropdownFormField<int>(
                      labelText: 'Day of Month',
                      value: state.dayOfMonth,
                      items: List.generate(
                          31,
                          (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text((index + 1).toString()))),
                      onChanged: (value) {
                        if (value != null) {
                          context
                              .read<AddEditRecurringRuleBloc>()
                              .add(DayOfMonthChanged(value));
                        }
                      },
                    ),
                  const SizedBox(height: 16),
                  AppDropdownFormField<EndConditionType>(
                    labelText: 'Ends',
                    value: state.endConditionType,
                    items: EndConditionType.values
                        .map((ec) =>
                            DropdownMenuItem(value: ec, child: Text(ec.name)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context
                            .read<AddEditRecurringRuleBloc>()
                            .add(EndConditionTypeChanged(value));
                      }
                    },
                  ),
                  if (state.endConditionType == EndConditionType.onDate)
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(state.endDate != null
                          ? DateFormat.yMd().format(state.endDate!)
                          : 'Select End Date'),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: state.endDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          context
                              .read<AddEditRecurringRuleBloc>()
                              .add(EndDateChanged(date));
                        }
                      },
                    ),
                  if (state.endConditionType ==
                      EndConditionType.afterOccurrences)
                    TextFormField(
                      controller: _occurrencesController,
                      decoration: const InputDecoration(
                          labelText: 'Number of Occurrences'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => context
                          .read<AddEditRecurringRuleBloc>()
                          .add(TotalOccurrencesChanged(value)),
                    ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: state.status == FormStatus.inProgress
                        ? null
                        : () => context
                            .read<AddEditRecurringRuleBloc>()
                            .add(FormSubmitted()),
                    child: state.status == FormStatus.inProgress
                        ? const CircularProgressIndicator()
                        : const Text('Save'),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
