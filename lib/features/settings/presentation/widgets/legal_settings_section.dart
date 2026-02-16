// lib/features/settings/presentation/widgets/legal_settings_section.dart
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import SettingsBloc
import 'package:expense_tracker/features/settings/presentation/widgets/settings_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import context.watch

class LegalSettingsSection extends StatelessWidget {
  final bool isLoading;
  final Function(BuildContext, String) launchUrlCallback;

  const LegalSettingsSection({
    super.key,
    required this.isLoading,
    required this.launchUrlCallback,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // --- Check Demo Mode ---
    final bool isInDemoMode = context.watch<SettingsBloc>().state.isInDemoMode;
    final bool isEnabled = !isLoading && !isInDemoMode;
    // --- End Check ---

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Legal'),
        SettingsListTile(
          enabled: isEnabled, // Use combined state
          leadingIcon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          trailing: Icon(
            Icons.open_in_new,
            size: 18,
            color:
                !isEnabled // Use combined state
                ? theme.disabledColor
                : theme.colorScheme.secondary,
          ),
          onTap:
              !isEnabled // Use combined state
              ? null
              : () => launchUrlCallback(
                  context,
                  'https://example.com/privacy',
                ), // Replace URL
        ),
        SettingsListTile(
          enabled: isEnabled, // Use combined state
          leadingIcon: Icons.gavel_outlined,
          title: 'Terms of Service',
          trailing: Icon(
            Icons.open_in_new,
            size: 18,
            color:
                !isEnabled // Use combined state
                ? theme.disabledColor
                : theme.colorScheme.secondary,
          ),
          onTap:
              !isEnabled // Use combined state
              ? null
              : () => launchUrlCallback(
                  context,
                  'https://example.com/terms',
                ), // Replace URL
        ),
        SettingsListTile(
          enabled: isEnabled, // Use combined state
          leadingIcon: Icons.article_outlined,
          title: 'Open Source Licenses',
          trailing: Icon(
            Icons.chevron_right,
            color:
                !isEnabled // Use combined state
                ? theme.disabledColor
                : theme.colorScheme.onSurfaceVariant,
          ),
          onTap:
              !isEnabled // Use combined state
              ? null
              : () => showLicensePage(context: context),
        ),
      ],
    );
  }
}
