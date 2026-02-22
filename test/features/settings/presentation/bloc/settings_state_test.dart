import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';

void main() {
  test('SettingsState supports equality', () {
    expect(const SettingsState(), equals(const SettingsState()));
  });
}
