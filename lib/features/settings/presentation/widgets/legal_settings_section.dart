import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/core/widgets/settings_list_tile.dart'; // Changed import
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    final bool isInDemoMode = context.watch<SettingsBloc>().state.isInDemoMode;
    final bool isEnabled = !isLoading && !isInDemoMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Legal'),
        SettingsListTile(
          enabled: isEnabled,
          leadingIcon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          trailing: Icon(
            Icons.open_in_new,
            size: 18,
            color: !isEnabled
                ? theme.disabledColor
                : theme.colorScheme.secondary,
          ),
          onTap: !isEnabled
              ? null
              : () => launchUrlCallback(context, 'https://example.com/privacy'),
        ),
        SettingsListTile(
          enabled: isEnabled,
          leadingIcon: Icons.gavel_outlined,
          title: 'Terms of Service',
          trailing: Icon(
            Icons.open_in_new,
            size: 18,
            color: !isEnabled
                ? theme.disabledColor
                : theme.colorScheme.secondary,
          ),
          onTap: !isEnabled
              ? null
              : () => launchUrlCallback(context, 'https://example.com/terms'),
        ),
        SettingsListTile(
          enabled: isEnabled,
          leadingIcon: Icons.article_outlined,
          title: 'Open Source Licenses',
          trailing: Icon(
            Icons.chevron_right,
            color: !isEnabled
                ? theme.disabledColor
                : theme.colorScheme.onSurfaceVariant,
          ),
          onTap: !isEnabled ? null : () => showLicensePage(context: context),
        ),
      ],
    );
  }
}
