import 'package:flutter/material.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_section.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';

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
    final kit = context.kit;
    final bool isInDemoMode = context.watch<SettingsBloc>().state.isInDemoMode;
    final bool isEnabled = !isLoading && !isInDemoMode;

    return AppSection(
      title: 'Help & Feedback',
      child: Column(
        children: [
          AppListTile(
            leading: Icon(
              Icons.help_outline_rounded,
              color: kit.colors.textPrimary,
            ),
            title: Text('Help Center'),
            trailing: Icon(
              Icons.open_in_new,
              size: 18,
              color: !isEnabled ? kit.colors.textMuted : kit.colors.primary,
            ),
            onTap: !isEnabled
                ? null
                : () => launchUrlCallback(context, 'https://example.com/help'),
          ),
          Builder(
            builder: (context) {
              return AppListTile(
                leading: Icon(
                  Icons.share_outlined,
                  color: kit.colors.textPrimary,
                ),
                title: Text('Tell a Friend'),
                subtitle: Text(
                  isInDemoMode
                      ? 'Disabled in Demo Mode'
                      : 'Help spread the word!',
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: !isEnabled
                      ? kit.colors.textMuted
                      : kit.colors.textSecondary,
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
      ),
    );
  }
}
