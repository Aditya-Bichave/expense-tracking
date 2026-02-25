import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_event.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';

class NumpadScreen extends StatefulWidget {
  final VoidCallback onNext;

  const NumpadScreen({super.key, required this.onNext});

  @override
  State<NumpadScreen> createState() => _NumpadScreenState();
}

class _NumpadScreenState extends State<NumpadScreen> {
  String _amountStr = '0';

  @override
  void initState() {
    super.initState();
    final stateAmount = context.read<AddExpenseWizardBloc>().state.amountTotal;
    if (stateAmount > 0) {
      _amountStr = stateAmount.toStringAsFixed(2);
      if (_amountStr.endsWith('.00')) {
        _amountStr = _amountStr.substring(0, _amountStr.length - 3);
      }
    }
  }

  void _handleInput(String input) {
    setState(() {
      if (_amountStr == '0' && input != '.') {
        _amountStr = input;
      } else {
        if (input == '.' && _amountStr.contains('.')) return;
        // Limit decimals to 2
        if (_amountStr.contains('.')) {
          final parts = _amountStr.split('.');
          if (parts.length > 1 && parts[1].length >= 2) return;
        }
        _amountStr += input;
      }
    });
    _updateBloc();
  }

  void _handleBackspace() {
    setState(() {
      if (_amountStr.length > 1) {
        _amountStr = _amountStr.substring(0, _amountStr.length - 1);
      } else {
        _amountStr = '0';
      }
    });
    _updateBloc();
  }

  void _updateBloc() {
    final amount = double.tryParse(_amountStr) ?? 0.0;
    context.read<AddExpenseWizardBloc>().add(AmountChanged(amount));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Amount'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                // Simply display what we typed, formatted lightly?
                // Or stick to _amountStr for raw feedback
                '$_amountStr',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          _buildNumpad(context),
          const SizedBox(height: 20),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (double.tryParse(_amountStr) ?? 0) > 0
            ? widget.onNext
            : null,
        label: const Text('Next'),
        icon: const Icon(Icons.arrow_forward),
      ),
    );
  }

  Widget _buildNumpad(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      height: 350,
      child: Column(
        children: [
          _row(context, ['1', '2', '3']),
          _row(context, ['4', '5', '6']),
          _row(context, ['7', '8', '9']),
          _row(context, ['.', '0', '<']),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, List<String> keys) {
    return Expanded(
      child: Row(
        children: keys.map((k) => Expanded(child: _key(context, k))).toList(),
      ),
    );
  }

  Widget _key(BuildContext context, String key) {
    if (key == '<') {
      return InkWell(
        onTap: _handleBackspace,
        borderRadius: BorderRadius.circular(50),
        child: const Center(child: Icon(Icons.backspace_outlined)),
      );
    }
    return InkWell(
      onTap: () => _handleInput(key),
      borderRadius: BorderRadius.circular(50),
      child: Center(
        child: Text(key, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
