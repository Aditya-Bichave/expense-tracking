// lib/features/settings/presentation/widgets/security_settings_section.dart
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/settings_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';

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
        SectionHeader(title: AppLocalizations.of(context)!.security),
        SwitchListTile(
          secondary: Icon(
            Icons.security_outlined,
            color: !isEnabled // Use combined state
                ? theme.disabledColor
                : theme.listTileTheme.iconColor,
          ),
          title: Text(
            AppLocalizations.of(context)!.appLock,
            style: TextStyle(color: !isEnabled ? theme.disabledColor : null),
          ), // Use combined state
          subtitle: Text(
            AppLocalizations.of(context)!.appLockSubtitle,
            style: TextStyle(color: !isEnabled ? theme.disabledColor : null),
          ), // Use combined state
          value: state.isAppLockEnabled,
          onChanged: !isEnabled // Use combined state
              ? null
              : (bool value) => onAppLockToggle(context, value),
          activeColor: theme.colorScheme.primary,
        ),
        SettingsListTile(
          enabled: false, // Disabled always for now (and in demo)
          leadingIcon: Icons.password_outlined,
          title: AppLocalizations.of(context)!.changePassword,
          subtitle: state.isInDemoMode
              ? AppLocalizations.of(context)!.disabledInDemoMode
              : AppLocalizations.of(context)!.featureComingSoon,
          trailing: Icon(
            Icons.chevron_right,
            color: theme.disabledColor,
          ), // Always disabled color
          onTap: null, // Always disabled
        ),
      ],
    );
  }
}
