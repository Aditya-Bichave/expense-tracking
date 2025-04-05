// lib/features/transactions/presentation/widgets/transaction_form.dart
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/widgets/app_text_form_field.dart';
import 'package:expense_tracker/core/widgets/app_dropdown_form_field.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/category_picker_dialog.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull

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
        if (mounted)
          _categoryFormFieldKey.currentState?.didChange(_selectedCategory);
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
          _categoryFormFieldKey.currentState?.validate();
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
              pickedTime?.minute ?? _selectedDate.minute);
        });
        log.info("[TransactionForm] Date selected: $_selectedDate");
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
      _categoryFormFieldKey.currentState?.didChange(_selectedCategory);
      _categoryFormFieldKey.currentState?.validate();
    }
  }

  void _submitForm() {
    log.info("[TransactionForm] Submit button pressed.");
    if (_formKey.currentState!.validate()) {
      final categoryToSubmit = _selectedCategory ?? Category.uncategorized;
      if (_selectedAccountId == null) {
        log.warning(
            "[TransactionForm] Submit prevented: Account not selected.");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Please select an account.'),
            backgroundColor: Colors.orange));
        return;
      }
      final title = _titleController.text.trim();
      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      final notes = _notesController.text.trim();
      final accountId = _selectedAccountId!;
      log.info(
          "[TransactionForm] Form fields validated. Calling onSubmit callback with Category: ${categoryToSubmit.name}");
      widget.onSubmit(_transactionType, title, amount, _selectedDate,
          categoryToSubmit, accountId, notes.isEmpty ? null : notes);
    } else {
      log.warning("[TransactionForm] Form validation failed.");
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Please correct the errors in the form.'),
            backgroundColor: Colors.orange));
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
    final isExpense = _transactionType == TransactionType.expense;

    return Form(
      key: _formKey,
      child: ListView(
        padding: modeTheme?.pagePadding
                .copyWith(left: 16, right: 16, bottom: 40, top: 16) ??
            const EdgeInsets.all(16.0).copyWith(bottom: 40),
        children: [
          // Transaction Type Toggle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Center(
              child: ToggleSwitch(
                minWidth: 120.0,
                cornerRadius: 20.0,
                activeBgColor: [
                  theme.colorScheme.errorContainer,
                  theme.colorScheme.primaryContainer
                ],
                activeFgColor: isExpense
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onPrimaryContainer,
                inactiveBgColor: theme.colorScheme.surfaceContainerHighest,
                inactiveFgColor: theme.colorScheme.onSurfaceVariant,
                initialLabelIndex: isExpense ? 0 : 1,
                totalSwitches: 2,
                labels: const ['Expense', 'Income'],
                radiusStyle: true,
                onToggle: (index) {
                  if (index != null) {
                    log.info(
                        "[TransactionForm] Toggle switched to index: $index");
                    final newType = index == 0
                        ? TransactionType.expense
                        : TransactionType.income;
                    if (_transactionType != newType) {
                      setState(() {
                        _transactionType = newType;
                        _selectedCategory = null;
                      });
                      context
                          .read<AddEditTransactionBloc>()
                          .add(TransactionTypeChanged(newType));
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _categoryFormFieldKey.currentState?.didChange(null);
                        _categoryFormFieldKey.currentState?.validate();
                      });
                    }
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
            prefixIcon: _getPrefixIcon(context, 'label',
                isExpense ? Icons.description_outlined : Icons.source_outlined),
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
            prefixIcon: _getPrefixIcon(context, 'amount', Icons.attach_money),
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
          const SizedBox(height: 16),

          // Category Picker using FormField
          FormField<Category>(
            key: _categoryFormFieldKey,
            initialValue: _selectedCategory,
            validator: (value) => null,
            builder: (formFieldState) {
              final Category? displayCategory =
                  _selectedCategory; // Explicit type
              Color displayColor =
                  displayCategory?.displayColor ?? theme.disabledColor;
              IconData displayIcon = Icons.category_outlined;
              Widget leadingWidget;

              if (displayCategory != null) {
                String? svgPath;
                if (modeTheme != null) {
                  svgPath = modeTheme.assets.getCategoryIcon(
                      displayCategory.iconName,
                      defaultPath: '');
                }
                if (svgPath != null && svgPath.isNotEmpty) {
                  leadingWidget = Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SvgPicture.asset(svgPath,
                          width: 24,
                          height: 24,
                          colorFilter:
                              ColorFilter.mode(displayColor, BlendMode.srcIn)));
                } else {
                  displayIcon = availableIcons[displayCategory.iconName] ??
                      Icons.help_outline;
                  leadingWidget = Icon(displayIcon, color: displayColor);
                }
              } else {
                leadingWidget = _getPrefixIcon(
                        context, 'category', Icons.category_outlined) ??
                    Icon(Icons.category_outlined, color: theme.disabledColor);
              }

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
              bool hasError = formFieldState.hasError;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      shape: OutlineInputBorder(
                          borderRadius: inputBorderRadius,
                          borderSide: hasError
                              ? errorSide
                              : theme.inputDecorationTheme.enabledBorder
                                      ?.borderSide ??
                                  BorderSide(color: theme.dividerColor)),
                      leading: leadingWidget,
                      title: Text(displayCategory?.name ?? 'Select Category',
                          style: TextStyle(
                              color:
                                  hasError ? theme.colorScheme.error : null)),
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: () async {
                        await _selectCategory(context);
                      }),
                  if (hasError)
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
            leading: _getPrefixIcon(context, 'calendar', Icons.calendar_today),
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
            prefixIcon:
                _getPrefixIcon(context, 'notes', Icons.note_alt_outlined),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 32),

          // Submit Button
          ElevatedButton.icon(
            icon: Icon(widget.initialTransaction == null
                ? Icons.add_circle_outline
                : Icons.save_outlined),
            label: Text(widget.initialTransaction == null
                ? 'Add Transaction'
                : 'Update Transaction'),
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
