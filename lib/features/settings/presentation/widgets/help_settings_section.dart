// lib/features/settings/presentation/widgets/help_settings_section.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/settings_list_tile.dart'; // Updated import
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HelpSettingsSection extends StatelessWidget {
  final bool isLoading;
  final Function(BuildContext, String) launchUrlCallback;

  const HelpSettingsSection({
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
        const SectionHeader(title: 'Help & Feedback'),
        SettingsListTile(
          enabled: !isLoading,
          leadingIcon: Icons.feedback_outlined,
          title: 'Send Feedback',
          trailing: Icon(Icons.chevron_right,
              color: isLoading
                  ? theme.disabledColor
                  : theme.colorScheme.onSurfaceVariant),
          onTap: isLoading
              ? null
              : () => context.pushNamed(RouteNames.settingsFeedback),
        ),
        SettingsListTile(
          enabled: !isLoading,
          leadingIcon: Icons.help_outline_rounded,
          title: 'FAQ / Help Center',
          trailing: Icon(Icons.open_in_new,
              size: 18,
              color: isLoading
                  ? theme.disabledColor
                  : theme.colorScheme.secondary),
          onTap: isLoading
              ? null
              : () => launchUrlCallback(
                  context, 'https://example.com/help'), // Replace URL
        ),
        SettingsListTile(
          enabled: !isLoading,
          leadingIcon: Icons.share_outlined,
          title: 'Tell a Friend',
          subtitle: 'Help spread the word!',
          trailing: Icon(Icons.chevron_right,
              color: isLoading
                  ? theme.disabledColor
                  : theme.colorScheme.onSurfaceVariant),
          onTap: isLoading
              ? null
              : () {
                  log.warning("Share functionality not implemented.");
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Share (Not Implemented)")));
                },
        ),
      ],
    );
  }
}
