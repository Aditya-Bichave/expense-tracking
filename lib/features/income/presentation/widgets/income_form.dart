import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/entities/income_category.dart'; // Use your IncomeCategory definition
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart'; // Use your DateFormatter

class IncomeForm extends StatefulWidget {
  final Income? initialIncome; // For editing
  final Function(String title, double amount, String categoryId,
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
  IncomeCategory?
      _selectedCategory; // Assuming IncomeCategory holds id and name
  String? _selectedAccountId;

  // TODO: Replace with your actual IncomeCategory source (enum, fetched list, etc.)
  // Example using the Predefined enum from your structure
  List<IncomeCategory> _incomeCategories = PredefinedIncomeCategory.values
      .map((e) => IncomeCategory.fromPredefined(e))
      .toList();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialIncome;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _amountController =
        TextEditingController(text: initial?.amount.toStringAsFixed(2) ?? '');
    _notesController = TextEditingController(text: initial?.notes ?? '');
    _selectedDate = initial?.date ?? DateTime.now();
    _selectedAccountId = initial?.accountId;

    // Find initial category if editing
    if (initial != null) {
      try {
        _selectedCategory = _incomeCategories
            .firstWhere((cat) => cat.name == initial.category.name);
      } catch (e) {
        _selectedCategory = null; // Category might have been deleted
      }
    } else if (_incomeCategories.isNotEmpty) {
      // _selectedCategory = _incomeCategories.first; // Optionally select first category by default
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      // Combine with time if needed, or default to midnight / current time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(picked.year, picked.month, picked.day,
              pickedTime.hour, pickedTime.minute);
        });
      }
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Account and Category selections are validated by their respective widgets
      final title = _titleController.text.trim();
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final notes = _notesController.text.trim();
      final categoryId =
          _selectedCategory!.name; // Assumes validator ensures it's not null
      final accountId =
          _selectedAccountId!; // Assumes validator ensures it's not null

      widget.onSubmit(
        title,
        amount,
        categoryId,
        accountId,
        _selectedDate,
        notes.isEmpty ? null : notes,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '\$', // Or your currency symbol
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              if (double.parse(value) <= 0) {
                return 'Amount must be positive';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<IncomeCategory>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            hint: const Text('Select Category'),
            isExpanded: true,
            items: _incomeCategories.map((IncomeCategory category) {
              return DropdownMenuItem<IncomeCategory>(
                value: category,
                child: Text(category.name), // Assumes IncomeCategory has a name
              );
            }).toList(),
            onChanged: (IncomeCategory? newValue) {
              setState(() {
                _selectedCategory = newValue;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select a category';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AccountSelectorDropdown(
            selectedAccountId: _selectedAccountId,
            onChanged: (String? newValue) {
              setState(() {
                _selectedAccountId = newValue;
              });
            },
            // Validator is implicitly handled within AccountSelectorDropdown
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date & Time'),
            subtitle: Text(DateFormatter.formatDateTime(
                _selectedDate)), // Use your formatter
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _selectDate(context),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _submitForm,
            child: Text(
                widget.initialIncome == null ? 'Add Income' : 'Update Income'),
          ),
        ],
      ),
    );
  }
}
