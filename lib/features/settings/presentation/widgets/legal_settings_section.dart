import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_section.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:expense_tracker/ui_bridge/bridge_list_tile.dart';

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
    final kit = context.kit;
    final bool isInDemoMode = context.watch<SettingsBloc>().state.isInDemoMode;
    final bool isEnabled = !isLoading && !isInDemoMode;

    return AppSection(
      title: 'Legal',
      child: Column(
        children: [
          AppBridgeListTile(
            leading: Icon(
              Icons.privacy_tip_outlined,
              color: kit.colors.textPrimary,
            ),
            title: Text('Privacy Policy'),
            trailing: Icon(
              Icons.open_in_new,
              size: 18,
              color: !isEnabled ? kit.colors.textMuted : kit.colors.primary,
            ),
            onTap: !isEnabled
                ? null
                : () =>
                      launchUrlCallback(context, 'https://example.com/privacy'),
          ),
          AppBridgeListTile(
            leading: Icon(Icons.gavel_outlined, color: kit.colors.textPrimary),
            title: Text('Terms of Service'),
            trailing: Icon(
              Icons.open_in_new,
              size: 18,
              color: !isEnabled ? kit.colors.textMuted : kit.colors.primary,
            ),
            onTap: !isEnabled
                ? null
                : () => launchUrlCallback(context, 'https://example.com/terms'),
          ),
          AppBridgeListTile(
            leading: Icon(
              Icons.article_outlined,
              color: kit.colors.textPrimary,
            ),
            title: Text('Open Source Licenses'),
            trailing: Icon(
              Icons.chevron_right,
              color: !isEnabled
                  ? kit.colors.textMuted
                  : kit.colors.textSecondary,
            ),
            onTap: !isEnabled ? null : () => showLicensePage(context: context),
          ),
        ],
      ),
    );
  }
}
