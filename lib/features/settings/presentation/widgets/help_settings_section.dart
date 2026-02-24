import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/core/widgets/settings_list_tile.dart';

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
    final bool isInDemoMode = context.watch<SettingsBloc>().state.isInDemoMode;
    final bool isEnabled = !isLoading && !isInDemoMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Help & Feedback'),
        SettingsListTile(
          enabled: isEnabled,
          leadingIcon: Icons.feedback_outlined,
          title: 'Send Feedback',
          subtitle: isInDemoMode ? 'Disabled in Demo Mode' : null,
          trailing: Icon(
            Icons.chevron_right,
            color: !isEnabled
                ? theme.disabledColor
                : theme.colorScheme.onSurfaceVariant,
          ),
          onTap: !isEnabled
              ? null
              : () {
                  log.warning(
                    "Send Feedback navigation/action not implemented.",
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Feedback (Coming Soon)")),
                  );
                },
        ),
        SettingsListTile(
          enabled: isEnabled,
          leadingIcon: Icons.help_outline_rounded,
          title: 'FAQ / Help Center',
          trailing: Icon(
            Icons.open_in_new,
            size: 18,
            color: !isEnabled
                ? theme.disabledColor
                : theme.colorScheme.secondary,
          ),
          onTap: !isEnabled
              ? null
              : () => launchUrlCallback(context, 'https://example.com/help'),
        ),
        Builder(
          builder: (context) {
            return SettingsListTile(
              enabled: isEnabled,
              leadingIcon: Icons.share_outlined,
              title: 'Tell a Friend',
              subtitle: isInDemoMode
                  ? 'Disabled in Demo Mode'
                  : 'Help spread the word!',
              trailing: Icon(
                Icons.chevron_right,
                color: !isEnabled
                    ? theme.disabledColor
                    : theme.colorScheme.onSurfaceVariant,
              ),
              onTap: !isEnabled
                  ? null
                  : () {
                      log.info("Share button tapped.");
                      final box = context.findRenderObject() as RenderBox?;
                      Share.share(
                        'Check out Spend Savvy! It helps me track my expenses and stay on budget.',
                        subject: 'Spend Savvy - Expense Tracker',
                        sharePositionOrigin: box != null
                            ? box.localToGlobal(Offset.zero) & box.size
                            : null,
                      );
                    },
            );
          },
        ),
      ],
    );
  }
}
