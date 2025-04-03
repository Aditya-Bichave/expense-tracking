// lib/features/income/presentation/widgets/income_form.dart
// MODIFIED FILE
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/widgets/app_text_form_field.dart';
// --- ADDED Import ---
import 'package:expense_tracker/features/categories/presentation/widgets/category_picker_dialog.dart';
// --- END ADDED ---
import 'package:expense_tracker/core/theme/app_mode_theme.dart';

class IncomeForm extends StatefulWidget {
  final Income? initialIncome;
  final Function(String title, double amount, Category category,
      String accountId, DateTime date, String? notes) onSubmit;

  const IncomeForm({
    super.key,
    this.initialIncome,
    required this.onSubmit,
  });

  @override
  State<IncomeForm> createState() => _IncomeFormState();
}

class _IncomeFormState extends State<IncomeForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  String? _selectedAccountId;

  @override
  void initState() {
    /* ... initState logic ... */
    super.initState();
    final initial = widget.initialIncome;
    log.info(
        "[IncomeForm] initState. Initial Income provided: ${initial != null}");
    _titleController = TextEditingController(text: initial?.title ?? '');
    _amountController =
        TextEditingController(text: initial?.amount.toStringAsFixed(2) ?? '');
    _notesController = TextEditingController(text: initial?.notes ?? '');
    _selectedDate = initial?.date ?? DateTime.now();
    _selectedAccountId = initial?.accountId;
    _selectedCategory = initial?.category;
    log.info(
        "[IncomeForm] Initial Category from entity: ${_selectedCategory?.name} (ID: ${_selectedCategory?.id})");
  }

  @override
  void dispose() {
    /* ... dispose logic ... */
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
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
        log.info("[IncomeForm] Date selected: $_selectedDate");
      });
    }
  }

  Future<void> _selectCategory(BuildContext context) async {
    /* ... category selection logic ... */
    final Category? result = await showCategoryPicker(
        context, CategoryTypeFilter.income); // Specify Income type
    if (result != null) {
      setState(() => _selectedCategory = result);
      log.info("[IncomeForm] Category selected via picker: ${result.name}");
    }
  }

  void _submitForm() {
    /* ... submit logic ... */
    log.info("[IncomeForm] Submit button pressed.");
    if (_formKey.currentState!.validate()) {
      if (_selectedAccountId == null || _selectedCategory == null) {
        log.warning(
            "[IncomeForm] Validation failed: Account or Category not selected.");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select both Account and Category.'),
            backgroundColor: Colors.red));
        return;
      }
      if (_selectedCategory!.id == Category.uncategorized.id) {
        log.warning(
            "[IncomeForm] Validation failed: Cannot submit 'Uncategorized'.");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select a specific category.'),
            backgroundColor: Colors.red));
        return;
      }
      final title = _titleController.text.trim();
      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      final notes = _notesController.text.trim();
      final category = _selectedCategory!;
      final accountId = _selectedAccountId!;
      log.info("[IncomeForm] Form validated. Calling onSubmit callback.");
      widget.onSubmit(
        title,
        amount,
        category,
        accountId,
        _selectedDate,
        notes.isEmpty ? null : notes,
      );
    } else {
      log.warning("[IncomeForm] Form validation failed.");
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
            labelText: 'Title / Source',
            prefixIconData: Icons.label_outline,
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
              log.info("[IncomeForm] Account selected: $_selectedAccountId");
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
          const SizedBox(height: 16),
          AppTextFormField(
            controller: _notesController,
            labelText: 'Notes (Optional)',
            hintText: 'Add any extra details',
            prefixIconData: Icons.note_alt_outlined,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: Icon(widget.initialIncome == null ? Icons.add : Icons.save),
            label: Text(
                widget.initialIncome == null ? 'Add Income' : 'Update Income'),
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
