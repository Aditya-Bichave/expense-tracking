import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/entities/income_category.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart'; // logger
// Import reusable form fields
import 'package:expense_tracker/core/widgets/app_text_form_field.dart';
import 'package:expense_tracker/core/widgets/app_dropdown_form_field.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart'; // For themed padding

class IncomeForm extends StatefulWidget {
  final Income? initialIncome;
  // Callback expects category NAME string now
  final Function(String title, double amount, String categoryName,
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
  IncomeCategory? _selectedCategory; // Store the IncomeCategory object
  String? _selectedAccountId;

  final List<IncomeCategory> _incomeCategories = PredefinedIncomeCategory.values
      .map((e) => IncomeCategory.fromPredefined(e))
      .toList();

  @override
  void initState() {
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

    if (initial != null) {
      try {
        _selectedCategory = _incomeCategories
            .firstWhere((cat) => cat.name == initial.category.name);
        log.info(
            "[IncomeForm] Initial category set to: ${_selectedCategory?.name}");
      } catch (e) {
        log.warning(
            "[IncomeForm] Could not find initial category '${initial.category.name}' in predefined list.");
        _selectedCategory = null;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    // ... (selectDate logic remains the same) ...
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
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

  void _submitForm() {
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
      final title = _titleController.text.trim();
      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      final notes = _notesController.text.trim();
      final categoryName = _selectedCategory!.name; // Pass name string
      final accountId = _selectedAccountId!;

      log.info("[IncomeForm] Form validated. Calling onSubmit callback.");
      widget.onSubmit(
        title,
        amount,
        categoryName,
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
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: modeTheme?.pagePadding ??
            const EdgeInsets.all(16.0), // Themed padding
        children: [
          // --- Use AppTextFormField ---
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
            prefixIconData: Icons
                .attach_money, // Consider a different icon color for income?
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
          // --- Use AppDropdownFormField ---
          AppDropdownFormField<IncomeCategory>(
            value: _selectedCategory,
            labelText: 'Category',
            hintText: 'Select income category',
            prefixIconData: Icons.category_outlined,
            items: _incomeCategories.map((IncomeCategory category) {
              return DropdownMenuItem<IncomeCategory>(
                  value: category, child: Text(category.name));
            }).toList(),
            onChanged: (IncomeCategory? newValue) {
              setState(() {
                _selectedCategory = newValue;
              });
              log.info(
                  "[IncomeForm] Category selected: ${_selectedCategory?.name}");
            },
            validator: (value) =>
                value == null ? 'Please select a category' : null,
          ),
          const SizedBox(height: 16),
          // AccountSelectorDropdown remains custom
          AccountSelectorDropdown(
            selectedAccountId: _selectedAccountId,
            onChanged: (String? newValue) {
              setState(() {
                _selectedAccountId = newValue;
              });
              log.info("[IncomeForm] Account selected: $_selectedAccountId");
            },
            validator: (value) =>
                value == null ? 'Please select an account' : null,
          ),
          const SizedBox(height: 16),
          // Date/Time Picker ListTile
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12), // Match dropdown padding
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
          // --- Use AppTextFormField for Notes ---
          AppTextFormField(
            controller: _notesController,
            labelText: 'Notes (Optional)',
            hintText: 'Add any extra details',
            prefixIconData: Icons.note_alt_outlined,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            // No validator needed for optional field
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
