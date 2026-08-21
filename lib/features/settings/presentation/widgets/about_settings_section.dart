import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_section.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';

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
          AppListTile(
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
            onTap: isLoading ? null : () => context.pushNamed(RouteNames.about),
          ),
          AppListTile(
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
                : () async {
                    final confirmed = await AppDialogs.showConfirmation(
                      context,
                      title: 'Logout',
                      content:
                          'Are you sure you want to logout? This will clear your local session.',
                      confirmText: 'Logout',
                    );
                    if (confirmed == true && context.mounted) {
                      context.read<AuthBloc>().add(AuthLogoutRequested());
                    }
                  },
          ),
        ],
      ),
    );
  }
}
