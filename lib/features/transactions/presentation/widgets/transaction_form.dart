import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/widgets/app_text_form_field.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_picker_dialog.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart'; // For icon lookup
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toggle_switch/toggle_switch.dart'; // Ensure this dependency is added

// Callback includes the selected type
typedef TransactionSubmitCallback = void Function(
  TransactionType type,
  String title,
  double amount,
  DateTime date,
  Category category, // Pass the selected Category object (or Uncategorized)
  String accountId,
  String? notes,
);

class TransactionForm extends StatefulWidget {
  final TransactionEntity? initialTransaction;
  final TransactionSubmitCallback onSubmit;
  final TransactionType initialType;
  final Category? initialCategory; // Added to accept pre-filled category

  const TransactionForm({
    super.key,
    required this.onSubmit,
    this.initialTransaction,
    this.initialType = TransactionType.expense,
    this.initialCategory,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  Category? _selectedCategory;
  String? _selectedAccountId;
  late TransactionType _transactionType;

  final GlobalKey<FormFieldState<Category>> _categoryFormFieldKey =
      GlobalKey<FormFieldState<Category>>();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTransaction;
    _transactionType = initial?.type ?? widget.initialType;
    log.info(
        "[TransactionForm] initState. Initial Txn: ${initial != null}, Type: ${_transactionType.name}");

    _titleController = TextEditingController(text: initial?.title ?? '');
    _amountController =
        TextEditingController(text: initial?.amount.toStringAsFixed(2) ?? '');
    _notesController = TextEditingController(text: initial?.notes ?? '');
    _selectedDate = initial?.date ?? DateTime.now();
    _selectedAccountId = initial?.accountId;
    _selectedCategory = widget.initialCategory ?? initial?.category;

    log.info(
        "[TransactionForm] Initial Category set in form state: ${_selectedCategory?.name} (ID: ${_selectedCategory?.id})");
  }

  @override
  void didUpdateWidget(covariant TransactionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != oldWidget.initialCategory) {
      log.info(
          "[TransactionForm] didUpdateWidget: initialCategory changed to ${widget.initialCategory?.name}");
      setState(() {
        _selectedCategory = widget.initialCategory;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _categoryFormFieldKey.currentState?.didChange(_selectedCategory);
          // Don't auto-validate here, let submit handle it
          // _categoryFormFieldKey.currentState?.validate();
        }
      });
    }
    if (widget.initialType != oldWidget.initialType &&
        widget.initialTransaction == null) {
      log.info(
          "[TransactionForm] didUpdateWidget: initialType changed to ${widget.initialType.name}");
      setState(() {
        _transactionType = widget.initialType;
        _selectedCategory = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _categoryFormFieldKey.currentState?.didChange(null);
          // Don't auto-validate here
          // _categoryFormFieldKey.currentState?.validate();
        }
      });
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
        lastDate: DateTime(2101));
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
          context: context, initialTime: TimeOfDay.fromDateTime(_selectedDate));
      if (mounted) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime?.hour ?? _selectedDate.hour,
            pickedTime?.minute ?? _selectedDate.minute,
          );
          log.info("[TransactionForm] Date selected: $_selectedDate");
        });
      }
    }
  }

  Future<void> _selectCategory(BuildContext context) async {
    final categoryFilter = _transactionType == TransactionType.expense
        ? CategoryTypeFilter.expense
        : CategoryTypeFilter.income;
    log.info(
        "[TransactionForm] Showing category picker for type: ${categoryFilter.name}");

    final Category? result = await showCategoryPicker(context, categoryFilter);
    if (result != null && mounted) {
      setState(() => _selectedCategory = result);
      log.info(
          "[TransactionForm] Category selected via picker: ${result.name} (ID: ${result.id})");
      // Update FormField state AFTER setting state
      _categoryFormFieldKey.currentState?.didChange(_selectedCategory);
      // Optionally validate only this field after selection
      _categoryFormFieldKey.currentState?.validate();
    }
  }

  void _submitForm() {
    log.info("[TransactionForm] Submit button pressed.");

    // --- MODIFIED: Validate all fields EXCEPT category initially ---
    // We manually validate category later if needed
    bool otherFieldsValid = _formKey.currentState?.validate() ?? false;
    // Find the category field state and temporarily clear its error if validation failed overall
    final categoryFieldState = _categoryFormFieldKey.currentState;
    bool categoryWasInvalid = categoryFieldState?.hasError ?? false;
    if (!otherFieldsValid && categoryWasInvalid) {
      // If the only error was the category field (which we initially allow to be null)
      // consider the rest of the form valid for now.
      // This is a bit heuristic, might need refinement.
      final errorTextBefore = categoryFieldState?.errorText;
      categoryFieldState?.validate(); // Re-validate category field
      if (categoryFieldState?.isValid ?? false) {
        // If category is actually valid now, or was just null
        otherFieldsValid = true; // Assume other fields were okay
      } else {
        categoryFieldState?.setState(() {
          // Manually clear error if needed for now
          // This is hacky, BLoC should drive error display
        });
      }
    }

    if (otherFieldsValid) {
      // Now check category specifically
      final categoryToSubmit = _selectedCategory ?? Category.uncategorized;
      // Account ID validation still relies on AccountSelectorDropdown validator
      if (_selectedAccountId == null) {
        log.warning(
            "[TransactionForm] Submit prevented: Account not selected (Validation Error).");
        // Error snackbar shown by general validation fail below
        return;
      }

      // --- Call onSubmit, BLoC will handle the uncategorized case ---
      final title = _titleController.text.trim();
      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      final notes = _notesController.text.trim();
      final accountId = _selectedAccountId!;

      log.info(
          "[TransactionForm] Form fields validated (excluding initial category check). Calling onSubmit callback.");
      widget.onSubmit(
        _transactionType, title, amount, _selectedDate,
        categoryToSubmit, // Pass selected or Uncategorized
        accountId,
        notes.isEmpty ? null : notes,
      );
    } else {
      log.warning("[TransactionForm] Form validation failed (other fields).");
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
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
    final isExpense = _transactionType == TransactionType.expense;

    return Form(
      key: _formKey,
      child: ListView(
        padding: modeTheme?.pagePadding ?? const EdgeInsets.all(16.0),
        children: [
          // Transaction Type Toggle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Center(
              child: ToggleSwitch(
                minWidth: 130.0,
                initialLabelIndex: _transactionType.index,
                cornerRadius: 20.0,
                activeFgColor: Colors.white,
                inactiveBgColor: theme.colorScheme.surfaceContainerHighest,
                inactiveFgColor: theme.colorScheme.onSurfaceVariant,
                totalSwitches: 2,
                labels: const ['Expense', 'Income'],
                icons: const [Icons.remove, Icons.add],
                iconSize: 20.0,
                activeBgColors: [
                  [theme.colorScheme.error],
                  [Colors.green.shade600]
                ],
                animate: true,
                curve: Curves.easeInOut,
                onToggle: (index) {
                  if (index != null && index != _transactionType.index) {
                    final newType = TransactionType.values[index];
                    log.info(
                        "[TransactionForm] Toggled type to: ${newType.name}");
                    setState(() {
                      _transactionType = newType;
                      _selectedCategory = null;
                      _categoryFormFieldKey.currentState?.didChange(null);
                      _categoryFormFieldKey.currentState
                          ?.validate(); // Re-validate after type change
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title / Source
          AppTextFormField(
            controller: _titleController,
            labelText: isExpense ? 'Title / Description' : 'Title / Source',
            prefixIconData:
                isExpense ? Icons.description_outlined : Icons.source_outlined,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Please enter a title'
                : null,
          ),
          const SizedBox(height: 16),

          // Amount
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

          // --- Category Picker using FormField ---
          FormField<Category>(
            key: _categoryFormFieldKey,
            initialValue: _selectedCategory,
            // --- MODIFIED VALIDATOR: Always return null initially ---
            validator: (value) {
              // Let the _submitForm logic handle the check after suggestion flow
              return null;
            },
            // --- END MODIFIED ---
            builder: (formFieldState) {
              Category? displayCategory = _selectedCategory;
              Color displayColor =
                  displayCategory?.displayColor ?? theme.disabledColor;
              IconData displayIcon = Icons.category_outlined;
              if (displayCategory != null) {
                displayIcon = availableIcons[displayCategory.iconName] ??
                    Icons.help_outline;
              }
              final BorderRadius defaultRadius = BorderRadius.circular(12.0);
              BorderRadius inputBorderRadius = defaultRadius;
              final borderConfig = theme.inputDecorationTheme.enabledBorder;
              if (borderConfig is OutlineInputBorder) {
                inputBorderRadius = borderConfig.borderRadius;
              }
              // --- Check error state from the field itself ---
              bool hasError = formFieldState.hasError;
              // --- End Check ---

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InputDecorator(
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      // --- Show error text if validation failed ---
                      errorText: hasError ? formFieldState.errorText : null,
                      // --- End Show ---
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      isDense: true,
                    ),
                    child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        shape: OutlineInputBorder(
                            borderRadius: inputBorderRadius,
                            borderSide: hasError
                                ? BorderSide(
                                    color: theme.colorScheme.error, width: 1.5)
                                : theme.inputDecorationTheme.enabledBorder
                                        ?.borderSide ??
                                    BorderSide(color: theme.dividerColor)),
                        leading: Icon(displayIcon,
                            color: hasError
                                ? theme.colorScheme.error
                                : displayColor),
                        title: Text(displayCategory?.name ?? 'Select Category',
                            style: TextStyle(
                                color:
                                    hasError ? theme.colorScheme.error : null)),
                        trailing: const Icon(Icons.arrow_drop_down),
                        onTap: () async {
                          await _selectCategory(context);
                          // formFieldState.didChange(_selectedCategory); // Already happens in _selectCategory
                        }),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Account Selector
          AccountSelectorDropdown(
            selectedAccountId: _selectedAccountId,
            onChanged: (String? newValue) {
              setState(() => _selectedAccountId = newValue);
              log.info(
                  "[TransactionForm] Account selected: $_selectedAccountId");
            },
            validator: (value) =>
                value == null ? 'Please select an account' : null,
          ),
          const SizedBox(height: 16),

          // Date Picker
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

          // Notes (Optional)
          AppTextFormField(
            controller: _notesController,
            labelText: 'Notes (Optional)',
            hintText: 'Add any extra details',
            prefixIconData: Icons.note_alt_outlined,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 32),

          // Submit Button
          ElevatedButton.icon(
            icon: Icon(
                widget.initialTransaction == null ? Icons.add : Icons.save),
            label: Text(widget.initialTransaction == null
                ? 'Add Transaction'
                : 'Update Transaction'),
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
