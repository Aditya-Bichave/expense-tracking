// lib/features/budgets/presentation/widgets/budget_form.dart
import 'package:collection/collection.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/widgets/app_dropdown_form_field.dart';
import 'package:expense_tracker/core/widgets/common_form_fields.dart';
import 'package:expense_tracker/core/widgets/category_selector_multi_tile.dart'; // Import the multi-select tile
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

typedef BudgetSubmitCallback =
    Function(
      String name,
      BudgetType type,
      double targetAmount,
      BudgetPeriodType period,
      DateTime? startDate,
      DateTime? endDate,
      List<String>? categoryIds,
      String? notes,
    );

class BudgetForm extends StatefulWidget {
  final Budget? initialBudget;
  final BudgetSubmitCallback onSubmit;
  final List<Category> availableCategories;

  const BudgetForm({
    super.key,
    this.initialBudget,
    required this.onSubmit,
    required this.availableCategories,
  });

  @override
  State<BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends State<BudgetForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;

  BudgetType _selectedType = BudgetType.overall;
  BudgetPeriodType _selectedPeriod = BudgetPeriodType.recurringMonthly;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  List<String> _selectedCategoryIds = [];
  String? _categoryErrorText;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialBudget;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _amountController = TextEditingController(
      text: initial?.targetAmount.toStringAsFixed(2) ?? '',
    );
    _notesController = TextEditingController(text: initial?.notes ?? '');
    _selectedType = initial?.type ?? BudgetType.overall;
    _selectedPeriod = initial?.period ?? BudgetPeriodType.recurringMonthly;
    _selectedStartDate = initial?.startDate;
    _selectedEndDate = initial?.endDate;
    _selectedCategoryIds =
        initial?.categoryIds
            ?.where(
              (id) => widget.availableCategories.any((cat) => cat.id == id),
            )
            .toList() ??
        [];
    log.info(
      "[BudgetForm] initState. Type: $_selectedType, Period: $_selectedPeriod, Initial Categories: ${_selectedCategoryIds.length}",
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initial =
        (isStartDate ? _selectedStartDate : _selectedEndDate) ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = DateTime(picked.year, picked.month, picked.day);
          if (_selectedEndDate != null &&
              _selectedEndDate!.isBefore(_selectedStartDate!)) {
            _selectedEndDate = _selectedStartDate;
          }
        } else {
          _selectedEndDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            23,
            59,
            59,
          );
          if (_selectedStartDate != null &&
              _selectedStartDate!.isAfter(_selectedEndDate!)) {
            _selectedStartDate = _selectedEndDate;
          }
        }
      });
      _formKey.currentState?.validate();
    }
  }

  void _showCategoryMultiSelect(BuildContext context) {
    final theme = Theme.of(context);
    final expenseCategories = widget.availableCategories
        .where(
          (cat) =>
              cat.type == CategoryType.expense &&
              cat.id != Category.uncategorized.id,
        )
        .toList();
    final items = expenseCategories
        .map((category) => MultiSelectItem<String>(category.id, category.name))
        .toList();
    final validInitialValue = _selectedCategoryIds
        .where((id) => items.any((item) => item.value == id))
        .toList();

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) {
        return MultiSelectBottomSheet<String>(
          items: items,
          initialValue: validInitialValue,
          title: const Text("Select Expense Categories"),
          selectedColor: theme.colorScheme.primary,
          selectedItemsTextStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
          itemsTextStyle: theme.textTheme.bodyMedium,
          searchHint: "Search Categories",
          searchIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          searchTextStyle: theme.textTheme.bodyMedium,
          confirmText: Text(
            'CONFIRM',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          cancelText: Text(
            'CANCEL',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          searchable: true,
          onConfirm: (values) {
            final newSelection = values.map((e) => e.toString()).toList();
            setState(() {
              _selectedCategoryIds = newSelection;
              if (_selectedCategoryIds.isNotEmpty) {
                _categoryErrorText = null;
              }
            });
            log.info(
              "[BudgetForm] Selected Category IDs: $_selectedCategoryIds",
            );
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _formKey.currentState?.validate(),
            );
          },
          maxChildSize: 0.7,
        );
      },
    );
  }

  void _submitForm() {
    log.info("[BudgetForm] Submit button pressed.");
    setState(() {
      _categoryErrorText = null;
    });

    bool isCategoryValid = true;
    if (_selectedType == BudgetType.categorySpecific &&
        _selectedCategoryIds.isEmpty) {
      isCategoryValid = false;
      setState(() {
        _categoryErrorText = 'Please select at least one category.';
      });
    }

    bool isFormValid = _formKey.currentState!.validate();

    if (isFormValid && isCategoryValid) {
      log.info("[BudgetForm] Form validated, calling onSubmit.");
      widget.onSubmit(
        _nameController.text.trim(),
        _selectedType,
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0,
        _selectedPeriod,
        _selectedStartDate,
        _selectedEndDate,
        _selectedType == BudgetType.categorySpecific
            ? _selectedCategoryIds
            : null,
        _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
    } else {
      log.warning(
        "[BudgetForm] Form validation failed (Form valid: $isFormValid, Category valid: $isCategoryValid).",
      );
      if (!isFormValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please correct the errors.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding:
            modeTheme?.pagePadding.copyWith(
              left: 16,
              right: 16,
              bottom: 40,
              top: 16,
            ) ??
            const EdgeInsets.all(16.0).copyWith(bottom: 40),
        children: [
          // Name
          CommonFormFields.buildNameField(
            context: context,
            controller: _nameController,
            labelText: 'Budget Name',
            hintText: 'e.g., Monthly Groceries, Vacation Fund',
            iconKey: 'label',
            fallbackIcon: Icons.label_outline,
          ),
          const SizedBox(height: 16),

          // Amount
          CommonFormFields.buildAmountField(
            context: context,
            controller: _amountController,
            labelText: 'Target Amount',
            currencySymbol: currencySymbol,
            iconKey: 'target',
            fallbackIcon: Icons.track_changes_outlined,
          ),
          const SizedBox(height: 20),

          // Budget Type Dropdown
          AppDropdownFormField<BudgetType>(
            value: _selectedType,
            labelText: 'Budget Type',
            prefixIcon: CommonFormFields.getPrefixIcon(
              context,
              'type',
              Icons.merge_type_outlined,
            ),
            items: BudgetType.values
                .map(
                  (BudgetType type) => DropdownMenuItem<BudgetType>(
                    value: type,
                    child: Text(type.displayName),
                  ),
                )
                .toList(),
            onChanged: (BudgetType? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedType = newValue;
                  if (newValue == BudgetType.overall) {
                    _selectedCategoryIds = [];
                    _categoryErrorText = null;
                  }
                  _formKey.currentState?.validate();
                });
              }
            },
            validator: (value) => value == null ? 'Please select a type' : null,
          ),
          const SizedBox(height: 16),

          // Category MultiSelect Tile (Conditional)
          if (_selectedType == BudgetType.categorySpecific) ...[
            CategorySelectorMultiTile(
              selectedCategoryIds: _selectedCategoryIds,
              availableCategories: widget.availableCategories,
              onTap: () => _showCategoryMultiSelect(context),
              label: 'Categories',
              hint: 'Select Categories *',
              errorText: _categoryErrorText,
            ),
            if (_selectedCategoryIds.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 16.0,
                  top: 4.0,
                ),
                child: Text(
                  _selectedCategoryIds
                      .map(
                        (id) =>
                            widget.availableCategories
                                .firstWhereOrNull((c) => c.id == id)
                                ?.name ??
                            '?',
                      )
                      .join(', '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 20),
          ],

          // Period Type Dropdown
          AppDropdownFormField<BudgetPeriodType>(
            value: _selectedPeriod,
            labelText: 'Period',
            prefixIcon: CommonFormFields.getPrefixIcon(
              context,
              'repeat',
              Icons.repeat_outlined,
            ),
            items: BudgetPeriodType.values
                .map(
                  (BudgetPeriodType type) => DropdownMenuItem<BudgetPeriodType>(
                    value: type,
                    child: Text(type.displayName),
                  ),
                )
                .toList(),
            onChanged: (BudgetPeriodType? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedPeriod = newValue;
                  if (newValue == BudgetPeriodType.recurringMonthly) {
                    _selectedStartDate = null;
                    _selectedEndDate = null;
                  }
                  _formKey.currentState?.validate();
                });
              }
            },
            validator: (value) =>
                value == null ? 'Please select a period' : null,
          ),
          const SizedBox(height: 16),

          // Date Pickers (Conditional)
          if (_selectedPeriod == BudgetPeriodType.oneTime) ...[
            FormField<bool>(
              key: ValueKey('date_picker_validator_$_selectedPeriod'),
              initialValue:
                  _selectedStartDate != null &&
                  _selectedEndDate != null &&
                  !_selectedEndDate!.isBefore(_selectedStartDate!),
              validator: (value) {
                if (_selectedPeriod == BudgetPeriodType.oneTime) {
                  if (_selectedStartDate == null || _selectedEndDate == null) {
                    return 'Please select start and end dates.';
                  }
                  if (_selectedEndDate!.isBefore(_selectedStartDate!)) {
                    return 'End date must be on or after start date.';
                  }
                }
                return null;
              },
              builder: (formFieldState) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CommonFormFields.buildDatePickerTile(
                          context: context,
                          selectedDate: _selectedStartDate,
                          label: 'Start Date *',
                          onTap: () => _selectDate(
                            context,
                            true,
                          ).then((_) => formFieldState.didChange(true)),
                          onClear: () => setState(() {
                            _selectedStartDate = null;
                            formFieldState.didChange(false);
                          }),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('-', style: TextStyle(fontSize: 16)),
                      ),
                      Expanded(
                        child: CommonFormFields.buildDatePickerTile(
                          context: context,
                          selectedDate: _selectedEndDate,
                          label: 'End Date *',
                          onTap: () => _selectDate(
                            context,
                            false,
                          ).then((_) => formFieldState.didChange(true)),
                          onClear: () => setState(() {
                            _selectedEndDate = null;
                            formFieldState.didChange(false);
                          }),
                        ),
                      ),
                    ],
                  ),
                  // Error Text display for Date Range FormField
                  if (formFieldState.hasError)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 12.0,
                        top: 8.0,
                      ),
                      child: Text(
                        formFieldState.errorText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Notes
          CommonFormFields.buildNotesField(
            context: context,
            controller: _notesController,
          ),
          const SizedBox(height: 32),

          // Submit Button
          ElevatedButton.icon(
            key: const ValueKey('button_submit'),
            icon: Icon(
              widget.initialBudget == null
                  ? Icons.add_circle_outline
                  : Icons.save_outlined,
            ),
            label: Text(
              widget.initialBudget == null ? 'Add Budget' : 'Update Budget',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: theme.textTheme.titleMedium,
            ),
            onPressed: _submitForm,
          ),
        ],
      ),
    );
  }
}
