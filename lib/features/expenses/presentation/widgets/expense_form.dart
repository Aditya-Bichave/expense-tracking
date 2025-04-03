// lib/features/expenses/presentation/widgets/expense_form.dart
// MODIFIED FILE
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/widgets/app_text_form_field.dart';
// --- ADDED Import ---
import 'package:expense_tracker/features/categories/presentation/widgets/category_picker_dialog.dart';
// --- END ADDED ---
import 'package:expense_tracker/core/theme/app_mode_theme.dart';

class ExpenseForm extends StatefulWidget {
  final Expense? initialExpense;
  final Function(String title, double amount, Category category,
      String accountId, DateTime date) onSubmit;

  const ExpenseForm({
    super.key,
    this.initialExpense,
    required this.onSubmit,
  });

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  String? _selectedAccountId;

  @override
  void initState() {
    /* ... initState logic ... */
    super.initState();
    final initial = widget.initialExpense;
    log.info(
        "[ExpenseForm] initState. Initial Expense provided: ${initial != null}");
    _titleController = TextEditingController(text: initial?.title ?? '');
    _amountController =
        TextEditingController(text: initial?.amount.toStringAsFixed(2) ?? '');
    _selectedDate = initial?.date ?? DateTime.now();
    _selectedAccountId = initial?.accountId;
    _selectedCategory = initial?.category;
    log.info(
        "[ExpenseForm] Initial Category from entity: ${_selectedCategory?.name} (ID: ${_selectedCategory?.id})");
  }

  @override
  void dispose() {
    /* ... dispose logic ... */
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    /* ... date selection logic ... */
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101));
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
          context: context, initialTime: TimeOfDay.fromDateTime(_selectedDate));
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime?.hour ?? _selectedDate.hour,
          pickedTime?.minute ?? _selectedDate.minute,
        );
        log.info("[ExpenseForm] Date selected: $_selectedDate");
      });
    }
  }

  Future<void> _selectCategory(BuildContext context) async {
    /* ... category selection logic ... */
    final Category? result =
        await showCategoryPicker(context, CategoryTypeFilter.expense);
    if (result != null) {
      setState(() => _selectedCategory = result);
      log.info("[ExpenseForm] Category selected via picker: ${result.name}");
    }
  }

  void _submitForm() {
    /* ... submit logic ... */
    log.info("[ExpenseForm] Submit button pressed.");
    if (_formKey.currentState!.validate()) {
      if (_selectedAccountId == null || _selectedCategory == null) {
        log.warning(
            "[ExpenseForm] Validation failed: Account or Category not selected.");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select both Account and Category.'),
            backgroundColor: Colors.red));
        return;
      }
      if (_selectedCategory!.id == Category.uncategorized.id) {
        log.warning(
            "[ExpenseForm] Validation failed: Cannot submit 'Uncategorized'.");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select a specific category.'),
            backgroundColor: Colors.red));
        return;
      }
      final title = _titleController.text.trim();
      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      final category = _selectedCategory!;
      final accountId = _selectedAccountId!;
      log.info("[ExpenseForm] Form validated. Calling onSubmit callback.");
      widget.onSubmit(title, amount, category, accountId, _selectedDate);
    } else {
      log.warning("[ExpenseForm] Form validation failed.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please correct the errors in the form.'),
          backgroundColor: Colors.orange));
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (build method logic remains the same, using _selectCategory in onTap) ...
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;
    return Form(
      key: _formKey,
      child: ListView(
        padding: modeTheme?.pagePadding ?? const EdgeInsets.all(16.0),
        children: [
          AppTextFormField(
            controller: _titleController,
            labelText: 'Title / Description',
            prefixIconData: Icons.description_outlined,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Please enter a title'
                : null,
          ),
          const SizedBox(height: 16),
          AppTextFormField(
            controller: _amountController,
            labelText: 'Amount',
            prefixText: '$currencySymbol ',
            prefixIconData: Icons.attach_money,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Please enter an amount';
              final number = double.tryParse(value.replaceAll(',', '.'));
              if (number == null) return 'Please enter a valid number';
              if (number <= 0) return 'Amount must be positive';
              return null;
            },
          ),
          const SizedBox(height: 16),
          FormField<Category>(
            initialValue: _selectedCategory,
            validator: (value) {
              if (value == null) return 'Please select a category';
              if (value.id == Category.uncategorized.id)
                return 'Please select a specific category';
              return null;
            },
            builder: (formFieldState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      shape: theme.inputDecorationTheme.enabledBorder ??
                          const OutlineInputBorder(),
                      leading: Icon(Icons.category_outlined,
                          color: formFieldState.hasError
                              ? theme.colorScheme.error
                              : theme.inputDecorationTheme.prefixIconColor),
                      title: Text(_selectedCategory?.name ?? 'Select Category',
                          style: TextStyle(
                              color: formFieldState.hasError
                                  ? theme.colorScheme.error
                                  : null)),
                      subtitle: formFieldState.hasError
                          ? Text(formFieldState.errorText!,
                              style: TextStyle(
                                  color: theme.colorScheme.error, fontSize: 12))
                          : null,
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: () async {
                        await _selectCategory(context);
                        formFieldState.didChange(_selectedCategory);
                      }),
                ],
              );
            },
            onSaved: (value) => _selectedCategory = value,
          ),
          const SizedBox(height: 16),
          AccountSelectorDropdown(
            selectedAccountId: _selectedAccountId,
            onChanged: (String? newValue) {
              setState(() => _selectedAccountId = newValue);
              log.info("[ExpenseForm] Account selected: $_selectedAccountId");
            },
            validator: (value) =>
                value == null ? 'Please select an account' : null,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: theme.inputDecorationTheme.enabledBorder ??
                const OutlineInputBorder(),
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date & Time'),
            subtitle: Text(DateFormatter.formatDateTime(_selectedDate)),
            trailing: IconButton(
              icon: const Icon(Icons.edit_calendar_outlined),
              onPressed: () => _selectDate(context),
              tooltip: 'Change Date/Time',
            ),
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: Icon(widget.initialExpense == null ? Icons.add : Icons.save),
            label: Text(widget.initialExpense == null
                ? 'Add Expense'
                : 'Update Expense'),
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
