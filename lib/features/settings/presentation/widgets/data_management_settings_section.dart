// lib/features/settings/presentation/widgets/data_management_settings_section.dart
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import SettingsBloc
import 'package:expense_tracker/features/settings/presentation/widgets/settings_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import context.watch
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
    // --- Get Demo Mode status ---
    final bool isInDemoMode = context.watch<SettingsBloc>().state.isInDemoMode;
    // --- End Get ---

    // --- Use the passed-in combined loading state ---
    final bool isOverallLoading = isDataManagementLoading || isSettingsLoading;
    // --- End Use ---

    // --- Determine if actions should be enabled ---
    final bool isEnabled = !isOverallLoading && !isInDemoMode;
    // --- End Determine ---

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Data Management'),
        SettingsListTile(
          // --- Use combined enabled state ---
          enabled: isEnabled,
          // --- End Use ---
          leadingIcon: Icons.backup_outlined,
          title: 'Backup Data',
          subtitle: isInDemoMode
              ? 'Disabled in Demo Mode'
              : 'Save all data to a file', // Demo message
          trailing: Icon(
            Icons.chevron_right,
            color:
                !isEnabled // Use combined state
                ? theme.disabledColor
                : theme.colorScheme.onSurfaceVariant,
          ),
          onTap: !isEnabled ? null : onBackup, // Use combined state
        ),
        SettingsListTile(
          // --- Use combined enabled state ---
          enabled: isEnabled,
          // --- End Use ---
          leadingIcon: Icons.restore_page_outlined,
          title: 'Restore Data',
          subtitle: isInDemoMode
              ? 'Disabled in Demo Mode'
              : 'Load data from a backup file', // Demo message
          trailing: Icon(
            Icons.chevron_right,
            color:
                !isEnabled // Use combined state
                ? theme.disabledColor
                : theme.colorScheme.onSurfaceVariant,
          ),
          onTap: !isEnabled ? null : onRestore, // Use combined state
        ),
        SettingsListTile(
          enabled: !isEnabled, // Export is separate, disable in demo/loading
          leadingIcon: Icons.upload_file_outlined,
          title: 'Export Data',
          subtitle: isInDemoMode
              ? 'Disabled in Demo Mode'
              : 'Export data to CSV/JSON (Coming Soon)', // Demo message
          trailing: Icon(
            Icons.chevron_right,
            color:
                !isEnabled // Use combined state
                ? theme.disabledColor
                : theme.colorScheme.onSurfaceVariant,
          ),
          onTap:
              !isEnabled // Use combined state
              ? null
              : () => context.pushNamed(
                  RouteNames.settingsExport,
                ), // Keep nav for now
        ),
        SettingsListTile(
          // --- Use combined enabled state, but specifically allow clear when NOT loading data ops ---
          enabled: !isDataManagementLoading && !isInDemoMode,
          // --- End Use ---
          leadingIcon: Icons.delete_sweep_outlined,
          title: 'Clear All Data',
          subtitle: isInDemoMode
              ? 'Disabled in Demo Mode'
              : 'Permanently delete all accounts & transactions',
          trailing: Icon(
            Icons.chevron_right,
            color:
                isDataManagementLoading ||
                    isInDemoMode // Check both
                ? theme.disabledColor
                : theme.colorScheme.error,
          ),
          onTap:
              isDataManagementLoading ||
                  isInDemoMode // Check both
              ? null
              : onClearData, // Use callback
        ),
        SettingsListTile(
          enabled: !isOverallLoading && !isInDemoMode, // Check both
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
                  /* TODO: Navigate to Trash Bin Screen */
                },
        ),
      ],
    );
  }
}
