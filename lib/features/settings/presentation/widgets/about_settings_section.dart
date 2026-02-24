import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/core/widgets/settings_list_tile.dart'; // Fixed import
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
    final bool isInDemoMode = state.isInDemoMode;
    final bool isEnabled = !isLoading; // About allowed in demo? Yes.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'About'),
        SettingsListTile(
          enabled: isEnabled,
          leadingIcon: Icons.info_outline_rounded,
          title: 'About App',
          subtitle: state.packageInfoStatus == PackageInfoStatus.loading
              ? 'Loading version...'
              : state.packageInfoStatus == PackageInfoStatus.error
              ? state.packageInfoError ?? 'Error loading version'
              : state.appVersion ?? 'N/A',
          trailing: Icon(
            Icons.chevron_right,
            color: !isEnabled
                ? theme.disabledColor
                : theme.colorScheme.onSurfaceVariant,
          ),
          onTap: isLoading
              ? null
              : () {
                  /* TODO: Navigate to a dedicated About screen if needed */
                },
        ),
        SettingsListTile(
          enabled: !isLoading && !isInDemoMode,
          leadingIcon: Icons.logout_rounded,
          title: 'Logout',
          subtitle: isInDemoMode ? 'Disabled in Demo Mode' : null,
          onTap: isLoading || isInDemoMode
              ? null
              : () {
                  log.warning("Logout functionality not implemented.");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Logout (Not Implemented)")),
                  );
                },
        ),
      ],
    );
  }
}
