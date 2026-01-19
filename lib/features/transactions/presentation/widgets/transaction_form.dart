// lib/features/transactions/presentation/widgets/transaction_form.dart
// ignore_for_file: deprecated_member_use

import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/widgets/common_form_fields.dart'; // Import common builders
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_picker_dialog.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/utils/currency_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef TransactionSubmitCallback = void Function(
  TransactionType type,
  String title,
  double amount,
  DateTime date,
  Category category,
  String accountId,
  String? notes,
);

class TransactionForm extends StatefulWidget {
  final TransactionEntity? initialTransaction;
  final TransactionSubmitCallback onSubmit;
  final TransactionType initialType;
  final Category? initialCategory;
  final String? initialTitle;
  final double? initialAmount;
  final DateTime? initialDate;
  final String? initialAccountId;
  final String? initialNotes;

  const TransactionForm({
    super.key,
    required this.onSubmit,
    this.initialTransaction,
    this.initialType = TransactionType.expense,
    this.initialCategory,
    this.initialTitle,
    this.initialAmount,
    this.initialDate,
    this.initialAccountId,
    this.initialNotes,
  });

  @override
  State<TransactionForm> createState() => TransactionFormState();
}

class TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  Category? _selectedCategory;
  String? _selectedAccountId;
  late TransactionType _transactionType;

  String get currentTitle => _titleController.text;
  String get currentAmountRaw => _amountController.text;
  DateTime get currentDate => _selectedDate;
  String? get currentAccountId => _selectedAccountId;
  String get currentNotes => _notesController.text;
  Category? get selectedCategory => _selectedCategory;

  // Removed _categoryFormFieldKey

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTransaction;
    _transactionType = initial?.type ?? widget.initialType;
    log.info(
      "[TransactionForm] initState. Initial Txn: ${initial != null}, Type: ${_transactionType.name}",
    );

    _titleController = TextEditingController(
      text: widget.initialTitle ?? initial?.title ?? '',
    );
    _amountController = TextEditingController(
      text: (widget.initialAmount ?? initial?.amount)?.toStringAsFixed(2) ?? '',
    );
    _notesController = TextEditingController(
      text: widget.initialNotes ?? initial?.notes ?? '',
    );
    _selectedDate = widget.initialDate ?? initial?.date ?? DateTime.now();
    _selectedAccountId = widget.initialAccountId ?? initial?.accountId;
    _selectedCategory = widget.initialCategory ?? initial?.category;

    log.info(
      "[TransactionForm] Initial Category set in form state: ${_selectedCategory?.name} (ID: ${_selectedCategory?.id})",
    );
  }

  @override
  void didUpdateWidget(covariant TransactionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != oldWidget.initialCategory) {
      log.info(
        "[TransactionForm] didUpdateWidget: initialCategory changed to ${widget.initialCategory?.name}",
      );
      setState(() {
        _selectedCategory = widget.initialCategory;
      });
    }
    if (widget.initialType != oldWidget.initialType &&
        widget.initialTransaction == null) {
      log.info(
        "[TransactionForm] didUpdateWidget: initialType changed to ${widget.initialType.name}",
      );
      setState(() {
        _transactionType = widget.initialType;
        _selectedCategory = null;
      });
      context.read<AddEditTransactionBloc>().add(
            TransactionTypeChanged(_transactionType),
          );
    }
    if (widget.initialTitle != oldWidget.initialTitle &&
        widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialAmount != oldWidget.initialAmount &&
        widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(2);
    }
    if (widget.initialDate != oldWidget.initialDate &&
        widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
    if (widget.initialAccountId != oldWidget.initialAccountId) {
      _selectedAccountId = widget.initialAccountId;
    }
    if (widget.initialNotes != oldWidget.initialNotes &&
        widget.initialNotes != null) {
      _notesController.text = widget.initialNotes!;
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
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (mounted) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime?.hour ?? _selectedDate.hour,
            pickedTime?.minute ?? _selectedDate.minute,
          );
        });
        log.info("[TransactionForm] Date selected: $_selectedDate");
      }
    }
  }

  Future<void> _selectCategory(BuildContext context) async {
    final categoryFilter = _transactionType == TransactionType.expense
        ? CategoryTypeFilter.expense
        : CategoryTypeFilter.income;
    final categoryState = context.read<CategoryManagementBloc>().state;
    final categories = categoryFilter == CategoryTypeFilter.expense
        ? categoryState.allExpenseCategories
        : categoryState.allIncomeCategories;
    log.info(
      "[TransactionForm] Showing category picker for type: ${categoryFilter.name}",
    );
    final Category? result = await showCategoryPicker(
      context,
      categoryFilter,
      categories,
    );
    if (result != null && mounted) {
      setState(() => _selectedCategory = result);
      log.info(
        "[TransactionForm] Category selected via picker: ${result.name} (ID: ${result.id})",
      );
    }
  }

  void _submitForm() {
    log.info("[TransactionForm] Submit button pressed.");
    if (_formKey.currentState!.validate()) {
      final categoryToSubmit = _selectedCategory ?? Category.uncategorized;
      if (_selectedAccountId == null) {
        log.warning(
          "[TransactionForm] Submit prevented: Account not selected.",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an account.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      final title = _titleController.text.trim();
      final locale = context.read<SettingsBloc>().state.selectedCountryCode;
      final amount = parseCurrency(_amountController.text, locale);
      final notes = _notesController.text.trim();
      final accountId = _selectedAccountId!;
      log.info(
        "[TransactionForm] Form fields validated. Calling onSubmit callback with Category: ${categoryToSubmit.name}",
      );
      widget.onSubmit(
        _transactionType,
        title,
        amount,
        _selectedDate,
        categoryToSubmit,
        accountId,
        notes.isEmpty ? null : notes,
      );
    } else {
      log.warning("[TransactionForm] Form validation failed.");
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Please correct the errors in the form.'),
            backgroundColor: Colors.orange,
          ),
        );
    }
  }

  // Removed _getPrefixIcon

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;
    final isExpense = _transactionType == TransactionType.expense;

    final List<Color> expenseColors = [
      theme.colorScheme.errorContainer.withOpacity(0.7),
      theme.colorScheme.errorContainer,
    ];
    final List<Color> incomeColors = [
      theme.colorScheme.primaryContainer,
      theme.colorScheme.primaryContainer.withOpacity(0.7),
    ];

    return Form(
      key: _formKey,
      child: ListView(
        padding: modeTheme?.pagePadding.copyWith(
              left: 16,
              right: 16,
              bottom: 40,
              top: 16,
            ) ??
            const EdgeInsets.all(16.0).copyWith(bottom: 40),
        children: [
          // Transaction Type Toggle
          CommonFormFields.buildTypeToggle(
            context: context,
            initialIndex: isExpense ? 0 : 1,
            labels: const ['Expense', 'Income'],
            activeBgColors: [expenseColors, incomeColors],
            onToggle: (index) {
              if (index != null) {
                log.info("[TransactionForm] Toggle switched to index: $index");
                final newType = index == 0
                    ? TransactionType.expense
                    : TransactionType.income;
                if (_transactionType != newType) {
                  setState(() {
                    _transactionType = newType;
                    _selectedCategory = null;
                  });
                  context.read<AddEditTransactionBloc>().add(
                        TransactionTypeChanged(newType),
                      );
                }
              }
            },
          ),
          const SizedBox(height: 16),

          // Title / Source
          CommonFormFields.buildNameField(
            context: context,
            controller: _titleController,
            labelText: isExpense ? 'Title / Description' : 'Title / Source',
            fallbackIcon:
                isExpense ? Icons.description_outlined : Icons.source_outlined,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // Amount
          CommonFormFields.buildAmountField(
            context: context,
            controller: _amountController,
            labelText: 'Amount',
            currencySymbol: currencySymbol,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),

          // Category Picker
          CommonFormFields.buildCategorySelector(
            context: context,
            selectedCategory: _selectedCategory,
            onTap: () async {
              await _selectCategory(context);
            },
            transactionType: _transactionType,
          ),
          const SizedBox(height: 16),

          // Account Selector
          CommonFormFields.buildAccountSelector(
            context: context,
            selectedAccountId: _selectedAccountId,
            onChanged: (String? newValue) {
              setState(() => _selectedAccountId = newValue);
              log.info(
                "[TransactionForm] Account selected: $_selectedAccountId",
              );
            },
          ),
          const SizedBox(height: 16),

          // Date Picker
          CommonFormFields.buildDatePickerTile(
            context: context,
            selectedDate: _selectedDate,
            label: 'Date & Time',
            onTap: () async {
              await _selectDate(context);
            },
          ),
          const SizedBox(height: 16),

          // Notes (Optional)
          CommonFormFields.buildNotesField(
            context: context,
            controller: _notesController,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 32),

          // Submit Button
          ElevatedButton.icon(
            key: const ValueKey('button_transactionForm_submit'),
            icon: Icon(
              widget.initialTransaction == null
                  ? Icons.add_circle_outline
                  : Icons.save_outlined,
            ),
            label: Text(
              widget.initialTransaction == null
                  ? 'Add Transaction'
                  : 'Update Transaction',
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
