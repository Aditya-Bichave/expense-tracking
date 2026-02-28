import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_bloc.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_event.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_nav_bar.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_fab.dart';

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
    final kit = context.kit;

    return AppScaffold(
      appBar: const AppNavBar(title: 'Enter Amount', centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                _amountStr,
                style: kit.typography.display.copyWith(
                  fontWeight: FontWeight.bold,
                  color: kit.colors.primary,
                ),
              ),
            ),
          ),
          _buildNumpad(context),
          kit.spacing.gapLg,
        ],
      ),
      floatingActionButton: AppFAB(
        onPressed: (double.tryParse(_amountStr) ?? 0) > 0
            ? widget.onNext
            : null,
        label: 'Next',
        icon: const Icon(Icons.arrow_forward),
        extended: true,
      ),
    );
  }

  Widget _buildNumpad(BuildContext context) {
    final kit = context.kit;
    return Container(
      padding: kit.spacing.hXxl,
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
    final kit = context.kit;

    if (key == '<') {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleBackspace,
          borderRadius: BorderRadius.circular(50),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              color: kit.colors.textPrimary,
              size: 28,
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleInput(key),
        borderRadius: BorderRadius.circular(50),
        child: Center(
          child: Text(
            key,
            style: kit.typography.display.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w400,
              color: kit.colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
