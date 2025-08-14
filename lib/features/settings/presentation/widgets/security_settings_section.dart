// lib/features/settings/presentation/widgets/security_settings_section.dart
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/settings_list_tile.dart';
import 'package:flutter/material.dart';

class SecuritySettingsSection extends StatelessWidget {
  final SettingsState state;
  final bool isLoading;
  final Function(BuildContext, bool) onAppLockToggle;

  const SecuritySettingsSection({
    super.key,
    required this.state,
    required this.isLoading,
    required this.onAppLockToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // --- Check Demo Mode ---
    final bool isEnabled = !isLoading && !state.isInDemoMode;
    // --- End Check ---

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Security'),
        SwitchListTile(
          secondary: Icon(Icons.security_outlined,
              color: !isEnabled // Use combined state
                  ? theme.disabledColor
                  : theme.listTileTheme.iconColor),
          title: Text('App Lock',
              style: TextStyle(
                  color: !isEnabled
                      ? theme.disabledColor
                      : null)), // Use combined state
          subtitle: Text('Require authentication on launch/resume',
              style: TextStyle(
                  color: !isEnabled
                      ? theme.disabledColor
                      : null)), // Use combined state
          value: state.isAppLockEnabled,
          onChanged: !isEnabled // Use combined state
              ? null
              : (bool value) => onAppLockToggle(context, value),
          activeColor: theme.colorScheme.primary,
        ),
        SettingsListTile(
          enabled: false, // Disabled always for now (and in demo)
          leadingIcon: Icons.password_outlined,
          title: 'Change Password',
          subtitle: state.isInDemoMode
              ? 'Disabled in Demo Mode'
              : 'Feature coming soon',
          trailing: Icon(Icons.chevron_right,
              color: theme.disabledColor), // Always disabled color
          onTap: null, // Always disabled
        ),
      ],
    );
  }
}
