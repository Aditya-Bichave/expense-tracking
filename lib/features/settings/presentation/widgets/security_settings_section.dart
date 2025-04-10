// lib/features/settings/presentation/widgets/security_settings_section.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/settings_list_tile.dart'; // Updated import
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Security'),
        SwitchListTile(
          secondary: Icon(Icons.security_outlined,
              color: isLoading
                  ? theme.disabledColor
                  : theme.listTileTheme.iconColor),
          title: Text('App Lock',
              style: TextStyle(color: isLoading ? theme.disabledColor : null)),
          subtitle: Text('Require authentication on launch/resume',
              style: TextStyle(color: isLoading ? theme.disabledColor : null)),
          value: state.isAppLockEnabled,
          onChanged: isLoading
              ? null
              : (bool value) => onAppLockToggle(context, value),
          activeColor: theme.colorScheme.primary,
        ),
        SettingsListTile(
          enabled:
              !isLoading, // TODO: Enable based on actual auth implementation
          leadingIcon: Icons.password_outlined,
          title: 'Change Password',
          subtitle: 'Feature coming soon',
          trailing: Icon(Icons.chevron_right,
              color: isLoading
                  ? theme.disabledColor
                  : theme.colorScheme.onSurfaceVariant),
          onTap: isLoading
              ? null
              : () => context.pushNamed(RouteNames.settingsSecurity),
        ),
      ],
    );
  }
}
