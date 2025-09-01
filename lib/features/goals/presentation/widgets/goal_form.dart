// lib/features/goals/presentation/widgets/goal_form.dart
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
// Keep for direct use if needed
import 'package:expense_tracker/core/widgets/common_form_fields.dart'; // Import common builders
import 'package:expense_tracker/features/categories/presentation/widgets/icon_picker_dialog.dart'; // Keep for icon picker
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
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
  String? _selectedIconName;

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
    _selectedIconName = initial?.iconName ?? 'savings_outlined';
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
        _selectedTargetDate ?? DateTime.now().add(const Duration(days: 90));
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101));
    if (picked != null && mounted) {
      setState(() => _selectedTargetDate =
          DateTime(picked.year, picked.month, picked.day));
      log.info("[GoalForm] Target Date selected: $_selectedTargetDate");
    }
  }

  void _showIconPicker(BuildContext context) async {
    final String? selectedIcon =
        await showIconPicker(context, _selectedIconName ?? 'savings_outlined');
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

  // _getPrefixIcon is now in CommonFormFields

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
        padding: modeTheme?.pagePadding
                .copyWith(left: 16, right: 16, bottom: 40, top: 16) ??
            const EdgeInsets.all(16.0).copyWith(bottom: 40),
        children: [
          // Goal Name - Using Common Builder
          CommonFormFields.buildNameField(
            context: context,
            controller: _nameController,
            labelText: 'Goal Name',
            hintText: 'e.g., New Car Down Payment, Emergency Fund',
            iconKey: 'flag',
            fallbackIcon: Icons.flag_outlined,
          ),
          const SizedBox(height: 16),

          // Target Amount - Using Common Builder
          CommonFormFields.buildAmountField(
            context: context,
            controller: _amountController,
            labelText: 'Target Amount',
            currencySymbol: currencySymbol,
            iconKey: 'target',
            fallbackIcon: Icons.track_changes_outlined,
          ),
          const SizedBox(height: 16),

          // Target Date (Optional) - Using Common Builder
          CommonFormFields.buildDatePickerTile(
            context: context,
            selectedDate: _selectedTargetDate,
            label: 'Target Date (Optional)',
            onTap: () async {
              await _selectTargetDate(context);
            },
            onClear: () => setState(() => _selectedTargetDate = null),
            iconKey: 'calendar',
            fallbackIcon: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 16),

          // Icon Picker - Kept Specific ListTile for now
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

          // Description (Optional) - Using Common Builder
          CommonFormFields.buildNotesField(
            context: context,
            controller: _descriptionController,
            labelText: 'Description / Notes (Optional)',
            hintText: 'Add details about your goal',
            iconKey: 'notes',
            fallbackIcon: Icons.note_alt_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 32),

          // Submit Button
          ElevatedButton.icon(
            key: const ValueKey('button_submit'),
            icon: Icon(
                isEditing ? Icons.save_outlined : Icons.add_circle_outline),
            label: Text(isEditing ? 'Update' : 'Create'),
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
