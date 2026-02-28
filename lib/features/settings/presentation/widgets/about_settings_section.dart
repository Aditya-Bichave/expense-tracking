import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_section.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_toast.dart';
import 'package:expense_tracker/ui_bridge/bridge_list_tile.dart';

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
    final kit = context.kit;
    final bool isInDemoMode = state.isInDemoMode;
    final bool isEnabled = !isLoading;

    return AppSection(
      title: 'About',
      child: Column(
        children: [
          AppBridgeListTile(
            leading: Icon(
              Icons.info_outline_rounded,
              color: kit.colors.textPrimary,
            ),
            title: Text('About App'),
            subtitle: Text(
              state.packageInfoStatus == PackageInfoStatus.loading
                  ? 'Loading version...'
                  : state.packageInfoStatus == PackageInfoStatus.error
                  ? state.packageInfoError ?? 'Error loading version'
                  : state.appVersion ?? 'N/A',
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: !isEnabled
                  ? kit.colors.textMuted
                  : kit.colors.textSecondary,
            ),
            onTap: isLoading
                ? null
                : () {
                    /* TODO: Navigate to a dedicated About screen if needed */
                  },
          ),
          AppBridgeListTile(
            leading: Icon(Icons.logout_rounded, color: kit.colors.textPrimary),
            title: Text('Logout'),
            subtitle: isInDemoMode ? Text('Disabled in Demo Mode') : null,
            trailing: Icon(
              Icons.chevron_right,
              color: !isEnabled
                  ? kit.colors.textMuted
                  : kit.colors.textSecondary,
            ),
            onTap: isLoading || isInDemoMode
                ? null
                : () {
                    log.warning("Logout functionality not implemented.");
                    AppToast.show(
                      context,
                      "Logout (Not Implemented)",
                      type: AppToastType.info,
                    );
                  },
          ),
        ],
      ),
    );
  }
}
