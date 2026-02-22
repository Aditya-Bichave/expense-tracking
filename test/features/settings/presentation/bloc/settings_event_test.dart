import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/core/theme/app_theme.dart'; // For UIMode? No, UIMode might be in settings_state or separate.
// Check settings_bloc.dart imports to see where UIMode/ThemeMode come from.
// ThemeMode is material.
// UIMode needs to be found.

void main() {
  test('UpdateTheme supports value equality', () {
    expect(
      const UpdateTheme(ThemeMode.dark),
      equals(const UpdateTheme(ThemeMode.dark)),
    );
  });
}
