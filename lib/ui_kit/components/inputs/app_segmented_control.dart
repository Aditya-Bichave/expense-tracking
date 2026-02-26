import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppSegmentedControl<T extends Object> extends StatelessWidget {
  final Map<T, Widget> children;
  final T? groupValue;
  final ValueChanged<T?> onValueChanged;

  const AppSegmentedControl({
    super.key,
    required this.children,
    required this.groupValue,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<T>(
        children: children,
        groupValue: groupValue,
        onValueChanged: onValueChanged,
        backgroundColor: kit.colors.surfaceContainer,
        thumbColor: kit.colors.surface,
        padding: const EdgeInsets.all(4),
      ),
    );
  }
}
