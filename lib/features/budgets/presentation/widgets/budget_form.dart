// lib/features/budgets/presentation/widgets/budget_form.dart
import 'package:collection/collection.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/widgets/app_text_form_field.dart';
import 'package:expense_tracker/core/widgets/app_dropdown_form_field.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

extension StringExtensionCapitalize on String {
  String capitalizeForm() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
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

  final GlobalKey<FormFieldState<List<String>>> _categoryFieldKey =
      GlobalKey<FormFieldState<List<String>>>();

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
    _selectedCategoryIds = initial?.categoryIds
            ?.where(
                (id) => widget.availableCategories.any((cat) => cat.id == id))
            .toList() ??
        [];
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
        lastDate: DateTime(2101));
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
      _formKey.currentState?.validate();
    }
  }

  void _showCategoryMultiSelect(BuildContext context) {
    final theme = Theme.of(context);
    final expenseCategories = widget.availableCategories
        .where((cat) =>
            cat.type == CategoryType.expense &&
            cat.id != Category.uncategorized.id)
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
            selectedItemsTextStyle: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.primary),
            itemsTextStyle: theme.textTheme.bodyMedium,
            searchHint: "Search Categories",
            searchIcon:
                Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
            searchTextStyle: theme.textTheme.bodyMedium,
            confirmText: Text('CONFIRM',
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold)),
            cancelText: Text('CANCEL',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            searchable: true,
            onConfirm: (values) {
              final newSelection = values.map((e) => e.toString()).toList();
              setState(() {
                _selectedCategoryIds = newSelection;
              });
              _categoryFieldKey.currentState?.didChange(newSelection);
              log.info(
                  "[BudgetForm] Selected Category IDs: $_selectedCategoryIds");
              WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _categoryFieldKey.currentState?.validate());
            },
            maxChildSize: 0.7,
          );
        });
  }

  void _submitForm() {
    log.info("[BudgetForm] Submit button pressed.");
    bool isCategoryValid = true;
    if (_selectedType == BudgetType.categorySpecific &&
        _selectedCategoryIds.isEmpty) {
      isCategoryValid = false;
      _categoryFieldKey.currentState?.validate();
    }

    if (_formKey.currentState!.validate() && isCategoryValid) {
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
          "[BudgetForm] Form validation failed (Form valid: ${_formKey.currentState!.validate()}, Category valid: $isCategoryValid).");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please correct the errors.")));
    }
  }

  Widget? _getPrefixIcon(
      BuildContext context, String iconKey, IconData fallbackIcon) {
    final modeTheme = context.modeTheme;
    final theme = Theme.of(context);
    if (modeTheme != null) {
      String svgPath = modeTheme.assets.getCommonIcon(iconKey, defaultPath: '');
      if (svgPath.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: SvgPicture.asset(svgPath,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                  theme.colorScheme.onSurfaceVariant, BlendMode.srcIn)),
        );
      }
    }
    return Icon(fallbackIcon);
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
        padding: modeTheme?.pagePadding
                .copyWith(left: 16, right: 16, bottom: 40, top: 16) ??
            const EdgeInsets.all(16.0).copyWith(bottom: 40),
        children: [
          // Name
          AppTextFormField(
            controller: _nameController,
            labelText: 'Budget Name',
            hintText: 'e.g., Monthly Groceries, Vacation Fund',
            prefixIcon: _getPrefixIcon(context, 'label', Icons.label_outline),
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
            prefixIcon:
                _getPrefixIcon(context, 'target', Icons.track_changes_outlined),
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

          // Budget Type Dropdown
          AppDropdownFormField<BudgetType>(
            // Use AppDropdownFormField
            value: _selectedType,
            labelText: 'Budget Type',
            // --- FIX: Use prefixIcon ---
            prefixIcon:
                _getPrefixIcon(context, 'type', Icons.merge_type_outlined),
            // --- END FIX ---
            items: BudgetType.values.map((BudgetType type) {
              return DropdownMenuItem<BudgetType>(
                  value: type, child: Text(type.displayName));
            }).toList(),
            onChanged: (BudgetType? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedType = newValue;
                  if (newValue == BudgetType.overall) {
                    _selectedCategoryIds = [];
                    _categoryFieldKey.currentState?.didChange([]);
                  }
                  WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _categoryFieldKey.currentState?.validate());
                });
              }
            },
            validator: (value) => value == null ? 'Please select a type' : null,
          ),
          const SizedBox(height: 16),

          // Category MultiSelect (Conditional)
          if (_selectedType == BudgetType.categorySpecific) ...[
            FormField<List<String>>(
              key: _categoryFieldKey,
              initialValue: _selectedCategoryIds,
              validator: (value) {
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
                BorderRadius inputBorderRadius = BorderRadius.circular(8.0);
                final borderConfig = theme.inputDecorationTheme.enabledBorder;
                InputBorder? errorBorderConfig =
                    theme.inputDecorationTheme.errorBorder;
                BorderSide errorSide =
                    BorderSide(color: theme.colorScheme.error, width: 1.5);
                if (borderConfig is OutlineInputBorder)
                  inputBorderRadius = borderConfig.borderRadius;
                if (errorBorderConfig is OutlineInputBorder)
                  errorSide = errorBorderConfig.borderSide;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      shape: OutlineInputBorder(
                          borderRadius: inputBorderRadius,
                          borderSide: formFieldState.hasError
                              ? errorSide
                              : theme.inputDecorationTheme.enabledBorder
                                      ?.borderSide ??
                                  BorderSide(color: theme.dividerColor)),
                      leading: _getPrefixIcon(
                          context, 'category', Icons.category_outlined),
                      title: Text(
                          _selectedCategoryIds.isEmpty
                              ? 'Select Expense Categories *'
                              : '${_selectedCategoryIds.length} Categories Selected',
                          style: TextStyle(
                              color: formFieldState.hasError
                                  ? theme.colorScheme.error
                                  : null)),
                      subtitle: _selectedCategoryIds.isNotEmpty
                          ? Text(selectedNames.join(', '),
                              maxLines: 1, overflow: TextOverflow.ellipsis)
                          : null,
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: () => _showCategoryMultiSelect(context),
                    ),
                    if (formFieldState.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0, top: 8.0),
                        child: Text(formFieldState.errorText!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.error)),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // Period Type Dropdown
          AppDropdownFormField<BudgetPeriodType>(
            // Use AppDropdownFormField
            value: _selectedPeriod,
            labelText: 'Period',
            // --- FIX: Use prefixIcon ---
            prefixIcon:
                _getPrefixIcon(context, 'repeat', Icons.repeat_outlined),
            // --- END FIX ---
            items: BudgetPeriodType.values.map((BudgetPeriodType type) {
              return DropdownMenuItem<BudgetPeriodType>(
                  value: type, child: Text(type.displayName));
            }).toList(),
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
              key: ValueKey('date_picker_$_selectedPeriod'),
              validator: (value) {
                if (_selectedPeriod == BudgetPeriodType.oneTime) {
                  if (_selectedStartDate == null || _selectedEndDate == null)
                    return 'Please select start and end dates.';
                  if (_selectedEndDate!.isBefore(_selectedStartDate!))
                    return 'End date must be on or after start date.';
                }
                return null;
              },
              builder: (formFieldState) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _getPrefixIcon(
                            context, 'calendar', Icons.date_range_outlined),
                        title: Text(
                            _selectedStartDate == null
                                ? 'Start Date *'
                                : DateFormatter.formatDate(_selectedStartDate!),
                            style: theme.textTheme.bodyMedium),
                        trailing: _selectedStartDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => setState(() {
                                  _selectedStartDate = null;
                                  formFieldState.didChange(false);
                                }),
                                tooltip: "Clear Start Date",
                                visualDensity: VisualDensity.compact,
                              )
                            : null,
                        onTap: () => _selectDate(context, true)
                            .then((_) => formFieldState.didChange(true)),
                        dense: true,
                      ),
                    ),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('-', style: TextStyle(fontSize: 16))),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _getPrefixIcon(
                            context, 'calendar', Icons.date_range),
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
                                    }),
                                tooltip: "Clear End Date",
                                visualDensity: VisualDensity.compact)
                            : null,
                        onTap: () => _selectDate(context, false)
                            .then((_) => formFieldState.didChange(true)),
                        dense: true,
                      ),
                    ),
                  ]),
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
            prefixIcon:
                _getPrefixIcon(context, 'notes', Icons.note_alt_outlined),
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
                textStyle: theme.textTheme.titleMedium),
            onPressed: _submitForm,
          ),
        ],
      ),
    );
  }
}
