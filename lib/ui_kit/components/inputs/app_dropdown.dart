import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;

  const AppDropdown({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.label,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: kit.typography.labelMedium.copyWith(
              color: kit.colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          kit.spacing.gapXs,
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: kit.colors.surfaceContainer,
            borderRadius: kit.radii.medium,
            border: Border.all(color: kit.colors.borderSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              hint: hint != null
                  ? Text(
                      hint!,
                      style: kit.typography.body.copyWith(
                        color: kit.colors.textSecondary,
                      ),
                    )
                  : null,
              style: kit.typography.body.copyWith(
                color: kit.colors.textPrimary,
              ),
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: kit.colors.textSecondary,
              ),
              isExpanded: true,
              dropdownColor: kit.colors.surfaceContainer,
            ),
          ),
        ),
      ],
    );
  }
}
