// lib/features/goals/presentation/widgets/log_contribution_sheet.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/widgets/app_text_form_field.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Function to show the sheet
Future<bool> showLogContributionSheet(BuildContext context, String goalId,
    {GoalContribution? initialContribution}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true, // Important for keyboard handling
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (builderContext) {
          // Provide the LogContributionBloc specifically for this sheet
          return BlocProvider(
            create: (_) => sl<LogContributionBloc>()
              ..add(InitializeContribution(
                  goalId: goalId, initialContribution: initialContribution)),
            child: Padding(
              // Add padding to account for keyboard
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(builderContext).viewInsets.bottom),
              child: LogContributionSheetContent(
                  initialContribution: initialContribution),
            ),
          );
        },
      ) ??
      false; // Return false if sheet is dismissed
}

// Content of the sheet
class LogContributionSheetContent extends StatefulWidget {
  final GoalContribution? initialContribution;

  const LogContributionSheetContent({super.key, this.initialContribution});

  @override
  State<LogContributionSheetContent> createState() =>
      _LogContributionSheetContentState();
}

class _LogContributionSheetContentState
    extends State<LogContributionSheetContent> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialContribution;
    _isEditing = initial != null;
    _amountController =
        TextEditingController(text: initial?.amount.toStringAsFixed(2) ?? '');
    _noteController = TextEditingController(text: initial?.note ?? '');
    _selectedDate = initial?.date ?? DateTime.now();
    log.info("[LogContribSheet] initState. Editing: $_isEditing");
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101));
    if (picked != null && mounted) {
      setState(() =>
          _selectedDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      log.info(
          "[LogContribSheet] Form validated, dispatching SaveContribution.");
      context.read<LogContributionBloc>().add(SaveContribution(
            amount:
                double.tryParse(_amountController.text.replaceAll(',', '.')) ??
                    0.0,
            date: _selectedDate,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          ));
    } else {
      log.warning("[LogContribSheet] Form validation failed.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;
    final settingsState = context.watch<SettingsBloc>().state;
    final currencySymbol = settingsState.currencySymbol;

    return BlocListener<LogContributionBloc, LogContributionState>(
      listener: (context, state) {
        if (state.status == LogContributionStatus.success) {
          log.info("[LogContribSheet] Save successful. Popping sheet.");
          Navigator.of(context).pop(true); // Pop sheet and return true
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content:
                  Text('Contribution ${_isEditing ? 'updated' : 'added'}!'),
              backgroundColor: Colors.green,
            ));
        } else if (state.status == LogContributionStatus.error &&
            state.errorMessage != null) {
          log.warning("[LogContribSheet] Save error: ${state.errorMessage}");
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text('Error: ${state.errorMessage}'),
              backgroundColor: theme.colorScheme.error,
            ));
          context
              .read<LogContributionBloc>()
              .add(const ClearContributionMessage());
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle & Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ],
              ),
              Text(_isEditing ? 'Edit Contribution' : 'Log Contribution',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),

              // Amount
              AppTextFormField(
                controller: _amountController,
                labelText: 'Amount Contributed',
                prefixText: '$currencySymbol ',
                prefixIconData: Icons.savings_outlined,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*[,.]?\d{0,2}')),
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

              // Date
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                shape: theme.inputDecorationTheme.enabledBorder ??
                    const OutlineInputBorder(),
                leading: const Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Icon(Icons.calendar_today)),
                title: const Text('Contribution Date'),
                subtitle: Text(DateFormatter.formatDate(_selectedDate)),
                trailing: const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.edit_calendar_outlined)),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),

              // Note
              AppTextFormField(
                controller: _noteController,
                labelText: 'Note (Optional)',
                prefixIconData: Icons.note_alt_outlined,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // Save Button
              BlocBuilder<LogContributionBloc, LogContributionState>(
                builder: (context, state) {
                  return ElevatedButton.icon(
                    icon: state.status == LogContributionStatus.loading
                        ? Container(
                            width: 20,
                            height: 20,
                            padding: const EdgeInsets.all(2),
                            child: const CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(_isEditing ? Icons.save : Icons.add),
                    label: Text(_isEditing
                        ? 'Update Contribution'
                        : 'Add Contribution'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: theme.textTheme.titleMedium,
                    ),
                    onPressed: state.status == LogContributionStatus.loading
                        ? null
                        : _submitForm,
                  );
                },
              ),
              const SizedBox(height: 8), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
