import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_section.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:expense_tracker/ui_bridge/bridge_list_tile.dart';

class DataManagementSettingsSection extends StatelessWidget {
  final bool isDataManagementLoading;
  final bool isSettingsLoading;
  final VoidCallback onBackup;
  final VoidCallback onRestore;
  final VoidCallback onClearData;

  const DataManagementSettingsSection({
    super.key,
    required this.isDataManagementLoading,
    required this.isSettingsLoading,
    required this.onBackup,
    required this.onRestore,
    required this.onClearData,
  });

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final bool isInDemoMode = context.watch<SettingsBloc>().state.isInDemoMode;
    final bool isOverallLoading = isDataManagementLoading || isSettingsLoading;
    final bool isEnabled = !isOverallLoading && !isInDemoMode;

    return AppSection(
      title: 'Data Management',
      child: Column(
        children: [
          AppBridgeListTile(
            leading: Icon(Icons.backup_outlined, color: kit.colors.textPrimary),
            title: Text('Backup Data'),
            subtitle: Text(
              isInDemoMode
                  ? 'Disabled in Demo Mode'
                  : 'Save all data to a file',
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: !isEnabled
                  ? kit.colors.textMuted
                  : kit.colors.textSecondary,
            ),
            onTap: !isEnabled ? null : onBackup,
          ),
          AppBridgeListTile(
            leading: Icon(
              Icons.restore_page_outlined,
              color: kit.colors.textPrimary,
            ),
            title: Text('Restore Data'),
            subtitle: Text(
              isInDemoMode
                  ? 'Disabled in Demo Mode'
                  : 'Load data from a backup file',
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: !isEnabled
                  ? kit.colors.textMuted
                  : kit.colors.textSecondary,
            ),
            onTap: !isEnabled ? null : onRestore,
          ),
          AppBridgeListTile(
            leading: Icon(
              Icons.upload_file_outlined,
              color: kit.colors.textPrimary,
            ),
            title: Text('Export Data'),
            subtitle: Text(
              isInDemoMode
                  ? 'Disabled in Demo Mode'
                  : 'Export data to CSV/JSON (Coming Soon)',
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: !isEnabled
                  ? kit.colors.textMuted
                  : kit.colors.textSecondary,
            ),
            onTap: !isEnabled
                ? null
                : () => context.pushNamed(RouteNames.settingsExport),
          ),
          AppBridgeListTile(
            leading: Icon(
              Icons.delete_sweep_outlined,
              color: kit.colors.textPrimary,
            ),
            title: Text('Clear All Data'),
            subtitle: Text(
              isInDemoMode
                  ? 'Disabled in Demo Mode'
                  : 'Permanently delete all accounts & transactions',
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: isDataManagementLoading || isInDemoMode
                  ? kit.colors.textMuted
                  : kit.colors.error,
            ),
            onTap: isDataManagementLoading || isInDemoMode ? null : onClearData,
          ),
          AppBridgeListTile(
            leading: Icon(
              Icons.restore_from_trash_outlined,
              color: kit.colors.textPrimary,
            ),
            title: Text('Trash Bin'),
            subtitle: Text(
              isInDemoMode
                  ? 'Disabled in Demo Mode'
                  : 'View recently deleted items (Coming Soon)',
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
                    // TODO: Navigate to Trash Bin Screen
                  },
          ),
        ],
      ),
    );
  }
}
