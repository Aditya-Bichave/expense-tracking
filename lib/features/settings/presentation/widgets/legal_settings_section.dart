// lib/features/settings/presentation/widgets/legal_settings_section.dart
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/settings_list_tile.dart'; // Updated import
import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Legal'),
        SettingsListTile(
          enabled: !isLoading,
          leadingIcon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          trailing: Icon(Icons.open_in_new,
              size: 18,
              color: isLoading
                  ? theme.disabledColor
                  : theme.colorScheme.secondary),
          onTap: isLoading
              ? null
              : () => launchUrlCallback(
                  context, 'https://example.com/privacy'), // Replace URL
        ),
        SettingsListTile(
          enabled: !isLoading,
          leadingIcon: Icons.gavel_outlined,
          title: 'Terms of Service',
          trailing: Icon(Icons.open_in_new,
              size: 18,
              color: isLoading
                  ? theme.disabledColor
                  : theme.colorScheme.secondary),
          onTap: isLoading
              ? null
              : () => launchUrlCallback(
                  context, 'https://example.com/terms'), // Replace URL
        ),
        SettingsListTile(
          enabled: !isLoading,
          leadingIcon: Icons.article_outlined,
          title: 'Open Source Licenses',
          trailing: Icon(Icons.chevron_right,
              color: isLoading
                  ? theme.disabledColor
                  : theme.colorScheme.onSurfaceVariant),
          onTap: isLoading ? null : () => showLicensePage(context: context),
        ),
      ],
    );
  }
}
