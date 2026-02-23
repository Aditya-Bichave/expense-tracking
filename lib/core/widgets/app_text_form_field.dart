// lib/core/widgets/app_text_form_field.dart
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final String? prefixText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool obscureText;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextCapitalization textCapitalization;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final bool isRequired;

  // --- ADDED: Accessibility & Action Props ---
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  // --- END ADDED ---

  const AppTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.prefixText,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.obscureText = false,
    this.readOnly = false,
    this.onTap,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.onChanged,
    this.isRequired = false,
    // --- ADDED ---
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
    // --- END ADDED ---
  });

  @override
  State<AppTextFormField> createState() => _AppTextFormFieldState();
}

class _AppTextFormFieldState extends State<AppTextFormField> {
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _showClearButton = widget.controller.text.isNotEmpty && !widget.readOnly;
    widget.controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    super.dispose();
  }

  void _handleTextChange() {
    if (mounted) {
      final shouldShow = widget.controller.text.isNotEmpty && !widget.readOnly;
      if (_showClearButton != shouldShow) {
        setState(() {
          _showClearButton = shouldShow;
        });
      }
    }
  }

  void _clearText() {
    widget.controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputTheme = theme.inputDecorationTheme;
    final modeTheme = context.modeTheme;

    final Widget? labelWidget = widget.isRequired
        ? Text.rich(
            TextSpan(
              text: widget.labelText,
              children: [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
            ),
          )
        : null;

    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.isRequired ? null : widget.labelText,
        label: labelWidget,
        hintText: widget.hintText,
        border: inputTheme.border ?? const OutlineInputBorder(),
        enabledBorder: inputTheme.enabledBorder,
        focusedBorder: inputTheme.focusedBorder,
        errorBorder: inputTheme.errorBorder,
        focusedErrorBorder: inputTheme.focusedErrorBorder,
        filled: inputTheme.filled,
        fillColor: inputTheme.fillColor,
        contentPadding:
            inputTheme.contentPadding ??
            modeTheme?.listItemPadding.copyWith(top: 14, bottom: 14),
        isDense: inputTheme.isDense,
        floatingLabelBehavior: inputTheme.floatingLabelBehavior,
        floatingLabelStyle: inputTheme.floatingLabelStyle,
        prefixIcon: widget.prefixIcon,
        prefixText: widget.prefixText,
        suffixIcon: _showClearButton
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                tooltip: 'Clear',
                onPressed: _clearText,
              )
            : null,
      ),
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      obscureText: widget.obscureText,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      textCapitalization: widget.textCapitalization,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      onChanged: widget.onChanged,
      // --- ADDED ---
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      // --- END ADDED ---
    );
  }
}
