// lib/features/goals/presentation/widgets/goal_form.dart
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/widgets/app_text_form_field.dart';
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart'; // Reuse icon picker
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef GoalSubmitCallback = Function(
  String name,
  double targetAmount,
  DateTime? targetDate,
  String? iconName,
  String? description,
);

class GoalForm extends StatefulWidget {
  final Goal? initialGoal;
  final GoalSubmitCallback onSubmit;

  const GoalForm({
    super.key,
    this.initialGoal,
    required this.onSubmit,
  });

  @override
  State<GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<GoalForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  DateTime? _selectedTargetDate;
  String? _selectedIconName; // Nullable

  @override
  void initState() {
    super.initState();
    final initial = widget.initialGoal;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _amountController = TextEditingController(
        text: initial?.targetAmount.toStringAsFixed(2) ?? '');
    _descriptionController =
        TextEditingController(text: initial?.description ?? '');
    _selectedTargetDate = initial?.targetDate;
    _selectedIconName = initial?.iconName ?? 'savings'; // Default icon if null

    log.info(
        "[GoalForm] initState. Icon: $_selectedIconName, Date: $_selectedTargetDate");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectTargetDate(BuildContext context) async {
    final DateTime initial =
        _selectedTargetDate ?? DateTime.now().add(const Duration(days: 30));
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime.now()
            .subtract(const Duration(days: 30)), // Allow slightly past dates
        lastDate: DateTime(2101));
    if (picked != null && mounted) {
      setState(() => _selectedTargetDate =
          DateTime(picked.year, picked.month, picked.day));
      log.info("[GoalForm] Target Date selected: $_selectedTargetDate");
    }
  }

  void _showIconPicker(BuildContext context) async {
    final String? selectedIcon =
        await showIconPicker(context, _selectedIconName ?? 'savings');
    if (selectedIcon != null && mounted) {
      setState(() => _selectedIconName = selectedIcon);
      log.info("[GoalForm] Icon selected: $_selectedIconName");
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      log.info("[GoalForm] Form validated, calling onSubmit.");
      widget.onSubmit(
        _nameController.text.trim(),
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0,
        _selectedTargetDate,
        _selectedIconName,
        _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
    } else {
      log.warning("[GoalForm] Form validation failed.");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please correct the errors.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;
    final bool isEditing = widget.initialGoal != null;

    final IconData displayIconData =
        availableIcons[_selectedIconName] ?? Icons.savings_outlined;

    return Form(
      key: _formKey,
      child: ListView(
        padding: modeTheme?.pagePadding ?? const EdgeInsets.all(16.0),
        children: [
          // Goal Name
          AppTextFormField(
            controller: _nameController,
            labelText: 'Goal Name',
            hintText: 'e.g., New Car Down Payment, Emergency Fund',
            prefixIconData: Icons.flag_outlined,
            textCapitalization: TextCapitalization.words,
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Enter a name' : null,
          ),
          const SizedBox(height: 16),

          // Target Amount
          AppTextFormField(
            controller: _amountController,
            labelText: 'Target Amount',
            prefixText: '$currencySymbol ',
            prefixIconData: Icons.track_changes_outlined,
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

          // Target Date (Optional)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: theme.inputDecorationTheme.enabledBorder ??
                const OutlineInputBorder(),
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Target Date (Optional)'),
            subtitle: Text(_selectedTargetDate == null
                ? 'No target date set'
                : DateFormatter.formatDate(_selectedTargetDate!)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedTargetDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() => _selectedTargetDate = null),
                    tooltip: "Clear Target Date",
                    visualDensity: VisualDensity.compact,
                  )
                else
                  const SizedBox(width: 40), // Placeholder to keep alignment
                const Icon(Icons.edit_calendar_outlined),
              ],
            ),
            onTap: () => _selectTargetDate(context),
          ),
          const SizedBox(height: 16),

          // Icon Picker
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            shape: theme.inputDecorationTheme.enabledBorder ??
                const OutlineInputBorder(),
            leading: Icon(displayIconData,
                color: theme.colorScheme.primary, size: 28),
            title: const Text('Goal Icon'),
            subtitle: Text(_selectedIconName ?? 'Default'),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: () => _showIconPicker(context),
          ),
          const SizedBox(height: 16),

          // Description (Optional)
          AppTextFormField(
            controller: _descriptionController,
            labelText: 'Description / Notes (Optional)',
            hintText: 'Add details about your goal',
            prefixIconData: Icons.note_alt_outlined,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 32),

          // Submit Button
          ElevatedButton.icon(
            icon: Icon(isEditing ? Icons.save : Icons.add_circle_outline),
            label: Text(isEditing ? 'Update Goal' : 'Add Goal'),
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
