// lib/features/budgets/presentation/widgets/budget_form.dart
import 'package:collection/collection.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/widgets/app_text_form_field.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart'; // <<< CHANGE 1: Added Import

typedef BudgetSubmitCallback = Function(
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

  @override
  void initState() {
    super.initState();
    final initial = widget.initialBudget;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _amountController = TextEditingController(
        text: initial?.targetAmount.toStringAsFixed(2) ?? '');
    _notesController = TextEditingController(text: initial?.notes ?? '');

    _selectedType = initial?.type ?? BudgetType.overall;
    _selectedPeriod = initial?.period ?? BudgetPeriodType.recurringMonthly;
    _selectedStartDate = initial?.startDate;
    _selectedEndDate = initial?.endDate;
    _selectedCategoryIds =
        initial?.categoryIds?.map((e) => e.toString()).toList() ?? [];

    log.info(
        "[BudgetForm] initState. Type: $_selectedType, Period: $_selectedPeriod, Initial Categories: ${_selectedCategoryIds.length}");
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
          _selectedEndDate =
              DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
          if (_selectedStartDate != null &&
              _selectedStartDate!.isAfter(_selectedEndDate!)) {
            _selectedStartDate = _selectedEndDate;
          }
        }
      });
      // Trigger validation after date selection changes might affect the date FormField
      _formKey.currentState?.validate();
    }
  }

  void _showCategoryMultiSelect(BuildContext context) {
    final items = widget.availableCategories
        .where((cat) => cat.id != Category.uncategorized.id)
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
            title: const Text("Select Categories"),
            selectedColor: Theme.of(context).colorScheme.primary,
            searchable: true,
            confirmText: const Text('Confirm'), // <<< CHANGE 3: Added text
            cancelText: const Text('Cancel'), // <<< CHANGE 3: Added text
            onConfirm: (values) {
              setState(() {
                _selectedCategoryIds = values.map((e) => e.toString()).toList();
              });
              log.info(
                  "[BudgetForm] Selected Category IDs: $_selectedCategoryIds");
              // Trigger validation after selection changes
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Ensure validation runs after state update
                _formKey.currentState?.validate();
              });
            },
            maxChildSize: 0.7,
          );
        });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Validation now happens correctly via FormFields
      log.info("[BudgetForm] Form validated, calling onSubmit.");
      widget.onSubmit(
        _nameController.text.trim(),
        _selectedType,
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0,
        _selectedPeriod,
        _selectedStartDate, // Pass dates regardless of period type, UseCase/Entity handles logic
        _selectedEndDate,
        _selectedType == BudgetType.categorySpecific
            ? _selectedCategoryIds
            : null,
        _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
    } else {
      log.warning("[BudgetForm] Form validation failed.");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please correct the errors.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;

    final categoryMultiSelectItems = widget.availableCategories
        .where((cat) => cat.id != Category.uncategorized.id)
        .map((category) => MultiSelectItem<String>(category.id, category.name))
        .toList();

    return Form(
      key: _formKey,
      child: ListView(
        padding: modeTheme?.pagePadding ?? const EdgeInsets.all(16.0),
        children: [
          // Name
          AppTextFormField(
            controller: _nameController,
            labelText: 'Budget Name',
            hintText: 'e.g., Monthly Groceries, Vacation Fund',
            prefixIconData: Icons.label_outline,
            textCapitalization: TextCapitalization.words,
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Enter a name' : null,
          ),
          const SizedBox(height: 16),

          // Amount
          AppTextFormField(
            controller: _amountController,
            labelText: 'Target Amount',
            prefixText: '$currencySymbol ',
            prefixIconData: Icons.track_changes_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter amount';
              final number = double.tryParse(value.replaceAll(',', '.'));
              if (number == null) return 'Invalid number';
              if (number <= 0) return 'Must be positive';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Budget Type Radio
          Text("Budget Type", style: theme.textTheme.titleSmall),
          Row(
            children: [
              Expanded(
                  child: RadioListTile<BudgetType>(
                title: Text(BudgetType.overall.displayName,
                    style: theme.textTheme.bodyMedium),
                value: BudgetType.overall,
                groupValue: _selectedType,
                onChanged: (v) => setState(() {
                  _selectedType = v!;
                  if (v == BudgetType.overall) _selectedCategoryIds = [];
                  WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _formKey.currentState?.validate());
                }),
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: VisualDensity.compact,
              )),
              Expanded(
                  child: RadioListTile<BudgetType>(
                title: Text(BudgetType.categorySpecific.displayName,
                    style: theme.textTheme.bodyMedium),
                value: BudgetType.categorySpecific,
                groupValue: _selectedType,
                onChanged: (v) => setState(() {
                  _selectedType = v!;
                  WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _formKey.currentState?.validate());
                }),
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: VisualDensity.compact,
              )),
            ],
          ),
          const SizedBox(height: 8),

          // Category MultiSelect (Conditional)
          if (_selectedType == BudgetType.categorySpecific) ...[
            FormField<List<String>>(
              key: ValueKey(
                  'category_selector_$_selectedType'), // Key to rebuild on type change
              initialValue: _selectedCategoryIds,
              validator: (value) {
                // This validation now correctly runs when type changes or form is submitted
                if (_selectedType == BudgetType.categorySpecific &&
                    (value == null || value.isEmpty)) {
                  return 'Please select at least one category.';
                }
                return null;
              },
              builder: (formFieldState) {
                final selectedNames = _selectedCategoryIds.map((id) {
                  final category = widget.availableCategories
                      .firstWhereOrNull((c) => c.id == id);
                  return category?.name ?? '?';
                }).toList();

                // --- CHANGE 2: Safely get borderRadius ---
                BorderRadius inputBorderRadius =
                    BorderRadius.circular(8.0); // Default
                final borderConfig = theme.inputDecorationTheme.enabledBorder;
                InputBorder? errorBorderConfig =
                    theme.inputDecorationTheme.errorBorder;
                BorderSide errorSide =
                    BorderSide(color: theme.colorScheme.error, width: 1.5);

                if (borderConfig is OutlineInputBorder) {
                  inputBorderRadius = borderConfig.borderRadius;
                }
                if (errorBorderConfig is OutlineInputBorder) {
                  errorSide = errorBorderConfig.borderSide;
                }
                // --- END CHANGE 2 ---

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      shape: OutlineInputBorder(
                          // Explicitly use OutlineInputBorder
                          borderRadius: inputBorderRadius,
                          borderSide: formFieldState.hasError
                              ? errorSide
                              : theme.inputDecorationTheme.enabledBorder
                                      ?.borderSide ??
                                  BorderSide(color: theme.dividerColor)),
                      leading: Icon(Icons.category_outlined,
                          color: formFieldState.hasError
                              ? theme.colorScheme.error
                              : null),
                      title: Text(
                          _selectedCategoryIds.isEmpty
                              ? 'Select Categories *'
                              : '${_selectedCategoryIds.length} Categories Selected',
                          style: TextStyle(
                              color: formFieldState.hasError
                                  ? theme.colorScheme.error
                                  : null)),
                      subtitle: _selectedCategoryIds.isNotEmpty
                          ? Text(
                              selectedNames.join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: () => _showCategoryMultiSelect(context),
                    ),
                    if (formFieldState.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0, top: 8.0),
                        child: Text(
                          formFieldState.errorText!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.error),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // Period Type Radio
          Text("Period", style: theme.textTheme.titleSmall),
          Row(
            children: [
              Expanded(
                  child: RadioListTile<BudgetPeriodType>(
                title: Text(BudgetPeriodType.recurringMonthly.displayName,
                    style: theme.textTheme.bodyMedium),
                value: BudgetPeriodType.recurringMonthly,
                groupValue: _selectedPeriod,
                onChanged: (v) => setState(() {
                  _selectedPeriod = v!;
                  _selectedStartDate = null;
                  _selectedEndDate = null;
                  WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _formKey.currentState?.validate());
                }),
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: VisualDensity.compact,
              )),
              Expanded(
                  child: RadioListTile<BudgetPeriodType>(
                title: Text(BudgetPeriodType.oneTime.displayName,
                    style: theme.textTheme.bodyMedium),
                value: BudgetPeriodType.oneTime,
                groupValue: _selectedPeriod,
                onChanged: (v) => setState(() {
                  _selectedPeriod = v!;
                  WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _formKey.currentState?.validate());
                }),
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: VisualDensity.compact,
              )),
            ],
          ),
          const SizedBox(height: 8),

          // Date Pickers (Conditional)
          if (_selectedPeriod == BudgetPeriodType.oneTime) ...[
            FormField<bool>(
              key: ValueKey(
                  'date_picker_$_selectedPeriod'), // Rebuild on period change
              // Validate based on _selectedStartDate and _selectedEndDate directly
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
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.date_range_outlined),
                          title: Text(
                              _selectedStartDate == null
                                  ? 'Start Date *'
                                  : DateFormatter.formatDate(
                                      _selectedStartDate!),
                              style: theme.textTheme.bodyMedium),
                          trailing: _selectedStartDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => setState(() {
                                    _selectedStartDate = null;
                                    formFieldState.didChange(false);
                                  }), // Update FormField state
                                  tooltip: "Clear Start Date",
                                  visualDensity: VisualDensity.compact,
                                )
                              : null,
                          onTap: () => _selectDate(context, true).then((_) =>
                              formFieldState
                                  .didChange(true)), // Update FormField state
                          dense: true,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('-', style: theme.textTheme.titleMedium),
                      ),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.date_range),
                          title: Text(
                              _selectedEndDate == null
                                  ? 'End Date *'
                                  : DateFormatter.formatDate(_selectedEndDate!),
                              style: theme.textTheme.bodyMedium),
                          trailing: _selectedEndDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => setState(() {
                                        _selectedEndDate = null;
                                        formFieldState.didChange(false);
                                      }), // Update FormField state
                                  tooltip: "Clear End Date",
                                  visualDensity: VisualDensity.compact)
                              : null,
                          onTap: () => _selectDate(context, false).then((_) =>
                              formFieldState
                                  .didChange(true)), // Update FormField state
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                  if (formFieldState.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0, top: 8.0),
                      child: Text(
                        formFieldState.errorText!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Notes
          AppTextFormField(
            controller: _notesController,
            labelText: 'Notes (Optional)',
            prefixIconData: Icons.note_alt_outlined,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 32),

          // Submit Button
          ElevatedButton.icon(
            icon: Icon(widget.initialBudget == null
                ? Icons.add_circle_outline
                : Icons.save_outlined),
            label: Text(
                widget.initialBudget == null ? 'Add Budget' : 'Update Budget'),
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
