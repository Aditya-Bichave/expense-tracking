// lib/features/settings/presentation/widgets/about_settings_section.dart
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/settings_list_tile.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';

class AboutSettingsSection extends StatelessWidget {
  final SettingsState state;
  final bool isLoading;

  const AboutSettingsSection({
    super.key,
    required this.state,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // --- Check Demo Mode ---
    final bool isInDemoMode = state.isInDemoMode;
    final bool isEnabled = !isLoading && !isInDemoMode;
    // --- End Check ---

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'About'),
        SettingsListTile(
          enabled:
              !isLoading, // About info is OK even in demo? Let's keep it enabled unless loading.
          leadingIcon: Icons.info_outline_rounded,
          title: 'About App',
          subtitle: state.packageInfoStatus == PackageInfoStatus.loading
              ? 'Loading version...'
              : state.packageInfoStatus == PackageInfoStatus.error
                  ? state.packageInfoError ?? 'Error loading version'
                  : state.appVersion ?? 'N/A',
          trailing: Icon(Icons.chevron_right,
              color: isLoading
                  ? theme.disabledColor
                  : theme.colorScheme.onSurfaceVariant),
          onTap: isLoading
              ? null
              : () {/* TODO: Navigate to a dedicated About screen if needed */},
        ),
        // Optional Logout
        SettingsListTile(
          enabled: isEnabled, // Use combined state for logout
          leadingIcon: Icons.logout_rounded,
          title: 'Logout',
          subtitle: isInDemoMode
              ? 'Disabled in Demo Mode'
              : null, // Explain why disabled
          onTap: !isEnabled // Use combined state
              ? null
              : () {
                  log.warning("Logout functionality not implemented.");
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Logout (Not Implemented)")));
                },
        ),
      ],
    );
  }
}
