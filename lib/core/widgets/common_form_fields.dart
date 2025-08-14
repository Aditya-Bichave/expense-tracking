// lib/core/widgets/common_form_fields.dart
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/utils/currency_parser.dart';
import 'package:expense_tracker/core/widgets/app_text_form_field.dart';
import 'package:expense_tracker/features/accounts/presentation/widgets/account_selector_dropdown.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:expense_tracker/core/widgets/category_selector_tile.dart';

/// A utility class containing static builder methods for common form fields.
class CommonFormFields {
  /// Helper to get a themed prefix icon (SVG or Material).
  static Widget? getPrefixIcon(
    BuildContext context,
    String iconKey,
    IconData fallbackIcon,
  ) {
    final modeTheme = context.modeTheme;
    final theme = Theme.of(context);
    if (modeTheme != null) {
      String svgPath = modeTheme.assets.getCommonIcon(iconKey, defaultPath: '');
      if (svgPath.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: SvgPicture.asset(
            svgPath,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              theme.colorScheme.onSurfaceVariant,
              BlendMode.srcIn,
            ),
          ),
        );
      }
    }
    return Icon(fallbackIcon, color: theme.colorScheme.onSurfaceVariant);
  }

  /// Builds a standard text input field for names or titles.
  static Widget buildNameField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    String iconKey = 'label',
    IconData fallbackIcon = Icons.label_outline,
    TextCapitalization textCapitalization = TextCapitalization.words,
    String? Function(String?)? validator,
  }) {
    return AppTextFormField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: getPrefixIcon(context, iconKey, fallbackIcon),
      textCapitalization: textCapitalization,
      validator:
          validator ??
          (value) => (value == null || value.trim().isEmpty)
              ? 'Please enter a value'
              : null,
    );
  }

  /// Builds a standard text input field for amounts.
  static Widget buildAmountField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelText,
    required String currencySymbol,
    String iconKey = 'amount',
    IconData fallbackIcon = Icons.attach_money,
    String? Function(String?)? validator,
  }) {
    return AppTextFormField(
      controller: controller,
      labelText: labelText,
      prefixText: '$currencySymbol ',
      prefixIcon: getPrefixIcon(context, iconKey, fallbackIcon),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d{0,2}')),
      ],
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) return 'Enter amount';
            final locale = context
                .read<SettingsBloc>()
                .state
                .selectedCountryCode;
            final number = parseCurrency(value, locale);
            if (number.isNaN) return 'Invalid number';
            if (number <= 0) return 'Must be positive';
            return null;
          },
    );
  }

  /// Builds a standard text input field for optional notes.
  static Widget buildNotesField({
    required BuildContext context,
    required TextEditingController controller,
    String labelText = 'Notes (Optional)',
    String hintText = 'Add any extra details',
    int maxLines = 3,
    String iconKey = 'notes',
    IconData fallbackIcon = Icons.note_alt_outlined,
  }) {
    return AppTextFormField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: getPrefixIcon(context, iconKey, fallbackIcon),
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      validator: null,
    );
  }

  /// Builds a ListTile suitable for picking a date.
  static Widget buildDatePickerTile({
    required BuildContext context,
    required DateTime? selectedDate,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onClear,
    String iconKey = 'calendar',
    IconData fallbackIcon = Icons.calendar_today_outlined,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape:
          theme.inputDecorationTheme.enabledBorder ??
          OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
      leading: getPrefixIcon(context, iconKey, fallbackIcon),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        selectedDate == null
            ? 'Not Set'
            : DateFormatter.formatDate(selectedDate),
        style: theme.textTheme.bodyLarge,
      ),
      trailing: selectedDate != null && onClear != null
          ? IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: onClear,
              tooltip: "Clear Date",
              visualDensity: VisualDensity.compact,
            )
          : const Icon(Icons.edit_calendar_outlined, size: 18),
      onTap: onTap,
    );
  }

  /// Builds the Account Selector Dropdown.
  static Widget buildAccountSelector({
    required BuildContext context,
    required String? selectedAccountId,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
    String labelText = 'Account',
    String hintText = 'Select Account',
  }) {
    return AccountSelectorDropdown(
      selectedAccountId: selectedAccountId,
      onChanged: onChanged,
      validator:
          validator ??
          (value) => value == null ? 'Please select an account' : null,
      labelText: labelText,
      hintText: hintText,
    );
  }

  /// Builds the Category Selector Tile.
  static Widget buildCategorySelector({
    required BuildContext context,
    required Category? selectedCategory,
    required VoidCallback onTap,
    String label = 'Category',
    String hint = 'Select Category',
    String? errorText,
    required TransactionType transactionType,
  }) {
    return CategorySelectorTile(
      selectedCategory: selectedCategory,
      onTap: onTap,
      label: label,
      hint: hint,
      errorText: errorText,
      uncategorizedCategory: Category.uncategorized,
    );
  }

  /// Builds the Expense/Income or Asset/Liability ToggleSwitch.
  static Widget buildTypeToggle({
    required BuildContext context,
    required int initialIndex,
    required List<String> labels,
    required List<List<Color>?> activeBgColors,
    required Function(int?) onToggle,
    bool disabled = false,
  }) {
    final theme = Theme.of(context);
    final bool isFirstActive = initialIndex == 0;
    Color activeFgColor;
    // Determine foreground based on context (Expense/Income or Asset/Liability)
    if (labels.length == 2) {
      if (labels[0] == 'Expense') {
        // Transaction Toggle
        activeFgColor = isFirstActive
            ? theme.colorScheme.onErrorContainer
            : theme.colorScheme.onPrimaryContainer;
      } else {
        // Assume Asset/Liability Toggle
        activeFgColor = isFirstActive
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onErrorContainer;
      }
    } else {
      activeFgColor = theme.colorScheme.onPrimaryContainer; // Default fallback
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: IgnorePointer(
          ignoring: disabled,
          child: Opacity(
            opacity: disabled ? 0.5 : 1.0,
            child: ToggleSwitch(
              minWidth: 120.0,
              cornerRadius: 20.0,
              activeBgColors: activeBgColors,
              activeBgColor: null,
              activeFgColor: activeFgColor,
              inactiveBgColor: theme.colorScheme.surfaceContainerHighest,
              inactiveFgColor: theme.colorScheme.onSurfaceVariant,
              initialLabelIndex: initialIndex,
              totalSwitches: labels.length,
              labels: labels,
              radiusStyle: true,
              onToggle: disabled ? null : onToggle,
            ),
          ),
        ),
      ),
    );
  }
}
