// lib/features/settings/presentation/widgets/data_management_settings_section.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
// Removed Bloc import as it's no longer needed directly here
import 'package:expense_tracker/features/settings/presentation/widgets/settings_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DataManagementSettingsSection extends StatelessWidget {
  final bool isDataManagementLoading;
  final bool isSettingsLoading; // Use this combined loading state
  final VoidCallback onBackup;
  final VoidCallback onRestore;
  final VoidCallback onClearData;

  const DataManagementSettingsSection({
    super.key,
    required this.isDataManagementLoading,
    required this.isSettingsLoading, // Receive this from parent
    required this.onBackup,
    required this.onRestore,
    required this.onClearData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // --- Use the passed-in combined loading state ---
    final bool isOverallLoading = isDataManagementLoading || isSettingsLoading;
    // --- End Use ---

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Data Management'),
        SettingsListTile(
          // --- Use combined loading state ---
          enabled: !isOverallLoading,
          // --- End Use ---
          leadingIcon: Icons.backup_outlined,
          title: 'Backup Data',
          subtitle: 'Save all data to a file',
          trailing: Icon(Icons.chevron_right,
              color: isOverallLoading
                  ? theme.disabledColor
                  : theme.colorScheme.onSurfaceVariant),
          onTap: isOverallLoading ? null : onBackup, // Use callback
        ),
        SettingsListTile(
          // --- Use combined loading state ---
          enabled: !isOverallLoading,
          // --- End Use ---
          leadingIcon: Icons.restore_page_outlined,
          title: 'Restore Data',
          subtitle: 'Load data from a backup file',
          trailing: Icon(Icons.chevron_right,
              color: isOverallLoading
                  ? theme.disabledColor
                  : theme.colorScheme.onSurfaceVariant),
          onTap: isOverallLoading ? null : onRestore, // Use callback
        ),
        SettingsListTile(
          enabled: !isOverallLoading,
          leadingIcon: Icons.upload_file_outlined,
          title: 'Export Data',
          subtitle: 'Export data to CSV/JSON (Coming Soon)',
          trailing: Icon(Icons.chevron_right,
              color: isOverallLoading
                  ? theme.disabledColor
                  : theme.colorScheme.onSurfaceVariant),
          onTap: isOverallLoading
              ? null
              : () => context.pushNamed(RouteNames.settingsExport),
        ),
        SettingsListTile(
          enabled: !isDataManagementLoading, // Only disable during data op
          leadingIcon: Icons.delete_sweep_outlined,
          title: 'Clear All Data',
          subtitle: 'Permanently delete all accounts & transactions',
          trailing: Icon(Icons.chevron_right,
              color: isDataManagementLoading
                  ? theme.disabledColor
                  : theme.colorScheme.error),
          onTap: isDataManagementLoading ? null : onClearData, // Use callback
        ),
        SettingsListTile(
          enabled: !isOverallLoading,
          leadingIcon: Icons.restore_from_trash_outlined,
          title: 'Trash Bin',
          subtitle: 'View recently deleted items (Coming Soon)',
          trailing: Icon(Icons.chevron_right,
              color: isOverallLoading
                  ? theme.disabledColor
                  : theme.colorScheme.onSurfaceVariant),
          onTap: isOverallLoading
              ? null
              : () => context.pushNamed(RouteNames.settingsTrash),
        ),
      ],
    );
  }
}
