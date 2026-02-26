import 'package:flutter/cupertino.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';

class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AppSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: kit.colors.primary,
      trackColor: kit.colors.borderSubtle,
    );
  }
}
