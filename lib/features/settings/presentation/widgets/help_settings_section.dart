// lib/features/settings/presentation/widgets/help_settings_section.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import SettingsBloc
import 'package:expense_tracker/features/settings/presentation/widgets/settings_list_tile.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import context.watch
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
    // --- Check Demo Mode ---
    final bool isInDemoMode = context.watch<SettingsBloc>().state.isInDemoMode;
    final bool isEnabled = !isLoading && !isInDemoMode;
    // --- End Check ---

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Help & Feedback'),
        SettingsListTile(
          enabled: isEnabled, // Use combined state
          leadingIcon: Icons.feedback_outlined,
          title: 'Send Feedback',
          subtitle: isInDemoMode ? 'Disabled in Demo Mode' : null,
          trailing: Icon(Icons.chevron_right,
              color: !isEnabled // Use combined state
                  ? theme.disabledColor
                  : theme.colorScheme.onSurfaceVariant),
          onTap: !isEnabled // Use combined state
              ? null
              : () {
                  log.warning(
                      "Send Feedback navigation/action not implemented.");
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Feedback (Coming Soon)")));
                  // context.pushNamed(RouteNames.settingsFeedback) // Keep navigation if screen exists
                },
        ),
        SettingsListTile(
          enabled: isEnabled, // Use combined state
          leadingIcon: Icons.help_outline_rounded,
          title: 'FAQ / Help Center',
          trailing: Icon(Icons.open_in_new,
              size: 18,
              color: !isEnabled // Use combined state
                  ? theme.disabledColor
                  : theme.colorScheme.secondary),
          onTap: !isEnabled // Use combined state
              ? null
              : () => launchUrlCallback(
                  context, 'https://example.com/help'), // Replace URL
        ),
        SettingsListTile(
          enabled: isEnabled, // Use combined state
          leadingIcon: Icons.share_outlined,
          title: 'Tell a Friend',
          subtitle:
              isInDemoMode ? 'Disabled in Demo Mode' : 'Help spread the word!',
          trailing: Icon(Icons.chevron_right,
              color: !isEnabled // Use combined state
                  ? theme.disabledColor
                  : theme.colorScheme.onSurfaceVariant),
          onTap: !isEnabled // Use combined state
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
