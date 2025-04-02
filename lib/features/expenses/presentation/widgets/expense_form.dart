import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/entities/category.dart'; // Your Expense Category definition
import 'package:expense_tracker/core/utils/date_formatter.dart';

class ExpenseForm extends StatefulWidget {
  final Expense? initialExpense; // For editing
  // Updated onSubmit signature
  final Function(String title, double amount, String categoryId,
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
  Category? _selectedCategory; // Your expense Category entity/model
  String? _selectedAccountId; // State for selected account

  // Assuming PredefinedCategory enum exists and Category has id/name
  // You would fetch custom categories or combine them here in a real app
  final List<Category> _expenseCategories = PredefinedCategory.values
      .map(
          (e) => Category(name: _formatCategoryName(e.name))) // Example mapping
      .toList();

  // Helper to make enum names more readable (optional)
  static String _formatCategoryName(String enumName) {
    if (enumName.isEmpty) return '';
    return enumName[0].toUpperCase() +
        enumName.substring(1).replaceAll('_', ' ');
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialExpense;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _amountController =
        TextEditingController(text: initial?.amount.toStringAsFixed(2) ?? '');
    _selectedDate = initial?.date ?? DateTime.now();
    _selectedAccountId = initial?.accountId; // Initialize selected account ID

    // Find initial category if editing
    if (initial != null) {
      try {
        _selectedCategory = _expenseCategories
            .firstWhere((cat) => cat.name == initial.category);
      } catch (e) {
        // Category might no longer exist or is a custom one not in the default list
        _selectedCategory = null;
        // Consider adding logic here to handle potentially missing categories
        // e.g., display the old ID or a placeholder.
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
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

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        // If only date is picked, keep the time but update the date
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _selectedDate.hour, // Keep original time
            _selectedDate.minute,
          );
        });
      }
    }
  }

  void _submitForm() {
    // Validate all form fields including dropdowns
    if (_formKey.currentState!.validate()) {
      // Null checks are important here, validators should prevent them but good practice
      if (_selectedAccountId == null || _selectedCategory == null) {
        // This case should ideally be caught by validators, but handle defensively
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please ensure all fields are selected.')));
        return;
      }

      final title = _titleController.text.trim();
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final category = _selectedCategory!.name;
      final accountId = _selectedAccountId!;

      widget.onSubmit(
        title,
        amount,
        category,
        accountId, // Pass the account ID
        _selectedDate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = NumberFormat.simpleCurrency()
        .currencySymbol; // Get device's currency symbol

    return Form(
      key: _formKey,
      child: ListView(
        // Using ListView for better scrolling on small devices
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title / Description'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title or description';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '$currencySymbol ', // Use device currency symbol
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              final number = double.tryParse(value);
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
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              hintText: 'Select expense category',
            ),
            isExpanded: true,
            items: _expenseCategories.map((Category category) {
              return DropdownMenuItem<Category>(
                value: category,
                child: Text(category.name),
              );
            }).toList(),
            onChanged: (Category? newValue) {
              setState(() {
                _selectedCategory = newValue;
              });
            },
            validator: (value) =>
                value == null ? 'Please select a category' : null,
          ),
          const SizedBox(height: 16),
          // --- Account Selector ---
          AccountSelectorDropdown(
            selectedAccountId: _selectedAccountId,
            onChanged: (String? newValue) {
              setState(() {
                _selectedAccountId = newValue;
              });
            },
            // Use internal validator of AccountSelectorDropdown
            validator: (value) =>
                value == null ? 'Please select an account' : null,
          ),
          // --- End Account Selector ---
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date & Time'),
            subtitle: Text(DateFormatter.formatDateTime(
                _selectedDate)), // Use your formatter
            onTap: () => _selectDate(context),
            trailing: IconButton(
              // Added button for clarity
              icon: const Icon(Icons.edit),
              onPressed: () => _selectDate(context),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'Add any extra details here',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _submitForm,
            child: Text(widget.initialExpense == null
                ? 'Add Expense'
                : 'Update Expense'),
          ),
        ],
      ),
    );
  }
}
