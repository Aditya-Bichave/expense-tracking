import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/core/widgets/settings_list_tile.dart'; // Changed import
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
    final theme = Theme.of(context);
    final bool isInDemoMode = context.watch<SettingsBloc>().state.isInDemoMode;
    final bool isOverallLoading = isDataManagementLoading || isSettingsLoading;
    final bool isEnabled = !isOverallLoading && !isInDemoMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Data Management'),
        SettingsListTile(
          enabled: isEnabled,
          leadingIcon: Icons.backup_outlined,
          title: 'Backup Data',
          subtitle: isInDemoMode
              ? 'Disabled in Demo Mode'
              : 'Save all data to a file',
          trailing: Icon(
            Icons.chevron_right,
            color: !isEnabled
                ? theme.disabledColor
                : theme.colorScheme.onSurfaceVariant,
          ),
          onTap: !isEnabled ? null : onBackup,
        ),
        SettingsListTile(
          enabled: isEnabled,
          leadingIcon: Icons.restore_page_outlined,
          title: 'Restore Data',
          subtitle: isInDemoMode
              ? 'Disabled in Demo Mode'
              : 'Load data from a backup file',
          trailing: Icon(
            Icons.chevron_right,
            color: !isEnabled
                ? theme.disabledColor
                : theme.colorScheme.onSurfaceVariant,
          ),
          onTap: !isEnabled ? null : onRestore,
        ),
        SettingsListTile(
          enabled: !isEnabled,
          leadingIcon: Icons.upload_file_outlined,
          title: 'Export Data',
          subtitle: isInDemoMode
              ? 'Disabled in Demo Mode'
              : 'Export data to CSV/JSON (Coming Soon)',
          trailing: Icon(
            Icons.chevron_right,
            color: !isEnabled
                ? theme.disabledColor
                : theme.colorScheme.onSurfaceVariant,
          ),
          onTap: !isEnabled
              ? null
              : () => context.pushNamed(RouteNames.settingsExport),
        ),
        SettingsListTile(
          enabled: !isDataManagementLoading && !isInDemoMode,
          leadingIcon: Icons.delete_sweep_outlined,
          title: 'Clear All Data',
          subtitle: isInDemoMode
              ? 'Disabled in Demo Mode'
              : 'Permanently delete all accounts & transactions',
          trailing: Icon(
            Icons.chevron_right,
            color: isDataManagementLoading || isInDemoMode
                ? theme.disabledColor
                : theme.colorScheme.error,
          ),
          onTap: isDataManagementLoading || isInDemoMode ? null : onClearData,
        ),
        SettingsListTile(
          enabled: !isOverallLoading && !isInDemoMode,
          leadingIcon: Icons.restore_from_trash_outlined,
          title: 'Trash Bin',
          subtitle: isInDemoMode
              ? 'Disabled in Demo Mode'
              : 'View recently deleted items (Coming Soon)',
          trailing: Icon(
            Icons.chevron_right,
            color: !isEnabled
                ? theme.disabledColor
                : theme.colorScheme.onSurfaceVariant,
          ),
          onTap: !isEnabled
              ? null
              : () {
                  // TODO: Navigate to Trash Bin Screen
                },
        ),
      ],
    );
  }
}
