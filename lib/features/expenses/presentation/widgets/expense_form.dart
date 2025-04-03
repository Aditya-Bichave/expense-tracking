import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/entities/category.dart'; // Import Category entity
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart'; // Import logger

class ExpenseForm extends StatefulWidget {
  final Expense? initialExpense;
  // Callback now expects category NAME (String)
  final Function(String title, double amount, String categoryName,
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
  // Removed notes controller - add back if notes are added to Expense entity/onSubmit
  // late TextEditingController _notesController;

  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory; // Store the Category object
  String? _selectedAccountId;

  // Use PredefinedCategory enum to generate Category objects
  final List<Category> _expenseCategories =
      PredefinedCategory.values.map((e) => Category.fromPredefined(e)).toList();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialExpense;
    log.info(
        "[ExpenseForm] initState. Initial Expense provided: ${initial != null}");
    _titleController = TextEditingController(text: initial?.title ?? '');
    _amountController =
        TextEditingController(text: initial?.amount.toStringAsFixed(2) ?? '');
    // _notesController = TextEditingController(); // Initialize if notes field is added
    _selectedDate = initial?.date ?? DateTime.now();
    _selectedAccountId = initial?.accountId;

    if (initial != null) {
      // Find the initial category object based on its name
      try {
        _selectedCategory = _expenseCategories
            .firstWhere((cat) => cat.name == initial.category.name);
        log.info(
            "[ExpenseForm] Initial category set to: ${_selectedCategory?.name}");
      } catch (e) {
        log.warning(
            "[ExpenseForm] Could not find initial category '${initial.category.name}' in predefined list.");
        _selectedCategory =
            null; // Or default to Category.fromPredefined(PredefinedCategory.other)
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    // _notesController.dispose(); // Dispose if added
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101), // Allow future dates? Or DateTime.now()?
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      // Combine date and time safely
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

  void _submitForm() {
    log.info("[ExpenseForm] Submit button pressed.");
    // Validate the form
    if (_formKey.currentState!.validate()) {
      // Additional checks for dropdowns (though validator should handle it)
      if (_selectedAccountId == null) {
        log.warning("[ExpenseForm] Validation failed: Account not selected.");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select an account.'),
            backgroundColor: Colors.red));
        return;
      }
      if (_selectedCategory == null) {
        log.warning("[ExpenseForm] Validation failed: Category not selected.");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select a category.'),
            backgroundColor: Colors.red));
        return;
      }

      // Parse values safely
      final title = _titleController.text.trim();
      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      final categoryName = _selectedCategory!.name; // Pass the name string
      final accountId = _selectedAccountId!;
      // final notes = _notesController.text.trim(); // Get notes if field exists

      log.info("[ExpenseForm] Form validated. Calling onSubmit callback.");
      widget.onSubmit(
        title,
        amount,
        categoryName, // Pass name string
        accountId,
        _selectedDate,
        // notes.isEmpty ? null : notes, // Pass notes if added
      );
    } else {
      log.warning("[ExpenseForm] Form validation failed.");
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

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title / Description',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.description_outlined),
              // Add clear button
              suffixIcon: _titleController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _titleController.clear(),
                      tooltip: 'Clear',
                    )
                  : null,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title or description';
              }
              return null;
            },
            onChanged: (_) => setState(() {}), // Update clear button visibility
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: 'Amount',
              border: const OutlineInputBorder(),
              prefixText: '$currencySymbol ',
              prefixIcon:
                  Icon(Icons.attach_money, color: theme.colorScheme.error),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(
                  r'^\d*[,.]?\d{0,2}')), // Allow digits, optional comma/dot, up to 2 decimal places
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              final number =
                  double.tryParse(value.replaceAll(',', '.')); // Allow comma
              if (number == null) {
                return 'Please enter a valid number';
              }
              if (number <= 0) {
                return 'Amount must be positive';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Category>(
            // Use Category object
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              hintText: 'Select expense category',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            isExpanded: true,
            items: _expenseCategories.map((Category category) {
              return DropdownMenuItem<Category>(
                value: category,
                child: Text(category.name), // Display name
              );
            }).toList(),
            onChanged: (Category? newValue) {
              setState(() {
                _selectedCategory = newValue;
              });
              log.info(
                  "[ExpenseForm] Category selected: ${_selectedCategory?.name}");
            },
            validator: (value) =>
                value == null ? 'Please select a category' : null,
          ),
          const SizedBox(height: 16),
          AccountSelectorDropdown(
            selectedAccountId: _selectedAccountId,
            onChanged: (String? newValue) {
              setState(() {
                _selectedAccountId = newValue;
              });
              log.info("[ExpenseForm] Account selected: $_selectedAccountId");
            },
            // Validator is included in the dropdown widget itself
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
                // Add border like text fields
                borderRadius: BorderRadius.circular(4.0),
                side: BorderSide(color: theme.colorScheme.outline)),
            leading: const Padding(
              padding: EdgeInsets.only(
                  left: 12.0), // Align icon with text field prefix icons
              child: Icon(Icons.calendar_today),
            ),
            title: const Text('Date & Time'),
            subtitle: Text(DateFormatter.formatDateTime(_selectedDate)),
            trailing: IconButton(
              icon: const Icon(Icons.edit_calendar_outlined),
              onPressed: () => _selectDate(context),
              tooltip: 'Change Date/Time',
            ),
            onTap: () => _selectDate(context), // Make whole tile tappable
          ),
          const SizedBox(height: 16),
          // Example Notes Field (Uncomment if needed)
          /*
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'Add any extra details here',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note_alt_outlined),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          */
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
