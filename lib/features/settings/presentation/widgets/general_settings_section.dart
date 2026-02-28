import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_section.dart';

class GeneralSettingsSection extends StatelessWidget {
  final SettingsState state;
  final bool isLoading;

  const GeneralSettingsSection({
    super.key,
    required this.state,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    // Notifications and Analytics not yet implemented in SettingsState
    // Removing tiles to fix compilation error.

    return const SizedBox.shrink();

    /*
    // Kept for future reference once state supports it
    final kit = context.kit;
    return AppSection(
      title: 'General',
      child: Column(
        children: [
           // ... tiles ...
        ],
      ),
    );
    */
  }
}
