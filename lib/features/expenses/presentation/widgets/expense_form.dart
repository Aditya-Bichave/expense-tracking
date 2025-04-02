import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
// import 'package:intl/intl.dart'; // No longer needed here
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/entities/category.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import SettingsBloc

class ExpenseForm extends StatefulWidget {
  final Expense? initialExpense;
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
  late TextEditingController _notesController; // Added notes controller

  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  String? _selectedAccountId;

  final List<Category> _expenseCategories = PredefinedCategory.values
      .map((e) => Category(name: _formatCategoryName(e.name)))
      .toList();

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
    _notesController = TextEditingController(); // Initialize notes controller
    _selectedDate = initial?.date ?? DateTime.now();
    _selectedAccountId = initial?.accountId;

    if (initial != null) {
      try {
        _selectedCategory = _expenseCategories
            .firstWhere((cat) => cat.name == initial.category.name);
      } catch (e) {
        _selectedCategory = null;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose(); // Dispose notes controller
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
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime?.hour ??
              _selectedDate.hour, // Use picked time or keep existing
          pickedTime?.minute ?? _selectedDate.minute,
        );
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedAccountId == null || _selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please ensure all fields are selected.')));
        return;
      }
      final title = _titleController.text.trim();
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final categoryId = _selectedCategory!.name;
      final accountId = _selectedAccountId!;
      // Note: Notes are not part of the Expense entity in your current structure
      // If you add 'notes' to the Expense entity, pass _notesController.text here.

      widget.onSubmit(
        title,
        amount,
        categoryId,
        accountId,
        _selectedDate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get currency symbol from SettingsBloc
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol =
        settingsState.currencySymbol ?? '\$'; // Default if null

    return Form(
      key: _formKey,
      child: ListView(
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
              // Use InputDecoration
              labelText: 'Amount',
              prefixText: '$currencySymbol ', // Use dynamic symbol
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
          AccountSelectorDropdown(
            selectedAccountId: _selectedAccountId,
            onChanged: (String? newValue) {
              setState(() {
                _selectedAccountId = newValue;
              });
            },
            validator: (value) =>
                value == null ? 'Please select an account' : null,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date & Time'),
            subtitle: Text(DateFormatter.formatDateTime(_selectedDate)),
            onTap: () => _selectDate(context),
            trailing: IconButton(
              icon: const Icon(Icons.edit_calendar_outlined), // Changed icon
              onPressed: () => _selectDate(context),
              tooltip: 'Change Date/Time',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController, // Use notes controller
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
