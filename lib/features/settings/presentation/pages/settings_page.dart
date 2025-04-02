import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsView();
  }
}

class SettingsView extends StatefulWidget {
  // Convert to StatefulWidget
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  // State for dialogs
  static const List<String> _currencySymbols = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'INR',
    'CAD',
    'AUD',
    'CHF'
  ];

  List<PopupMenuEntry<ThemeMode>> _buildThemeMenuItems(BuildContext context) {
    return ThemeMode.values
        .map((mode) => PopupMenuItem<ThemeMode>(
              value: mode,
              child: Text(mode.name.capitalize(),
                  style: Theme.of(context).textTheme.bodyMedium),
            ))
        .toList();
  }

  // --- Dialog Functions ---
  Future<bool?> _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required Widget content,
    required String confirmText,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(title),
          content: content,
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: isDestructive ? Colors.red : null),
              child: Text(confirmText),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showStrongConfirmationDialog({
    required BuildContext context,
    required String title,
    required String confirmationText, // e.g., "DELETE"
  }) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(title),
          content: Form(
            // Use a Form for validation
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This action is irreversible. Please type "$confirmationText" below to confirm.',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Type "$confirmationText" to confirm',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim() != confirmationText) {
                      return 'Incorrect confirmation text';
                    }
                    return null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Confirm'),
              onPressed: () {
                // Validate the input before popping
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(ctx).pop(true);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- Event Handlers ---
  void _handleBackup(BuildContext context) async {
    final confirmed = await _showConfirmationDialog(
      context: context,
      title: 'Confirm Backup',
      content: const Text('Create a local backup file of your data?'),
      confirmText: 'Backup',
    );
    if (confirmed == true && context.mounted) {
      // Check if mounted after await
      context.read<SettingsBloc>().add(const BackupRequested());
    }
  }

  void _handleRestore(BuildContext context) async {
    final confirmed = await _showStrongConfirmationDialog(
      context: context,
      title: 'Confirm Restore',
      confirmationText: 'RESTORE', // Require typing RESTORE
    );
    if (confirmed == true && context.mounted) {
      context.read<SettingsBloc>().add(const RestoreRequested());
    }
  }

  void _handleClearData(BuildContext context) async {
    final confirmed = await _showStrongConfirmationDialog(
      context: context,
      title: 'Confirm Clear All Data',
      confirmationText: 'DELETE', // Require typing DELETE
    );
    if (confirmed == true && context.mounted) {
      context.read<SettingsBloc>().add(const ClearDataRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        // Show Snackbars for Data Management Success/Failure
        if (state.dataManagementStatus == DataManagementStatus.success &&
            state.dataManagementMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.dataManagementMessage!),
                backgroundColor: Colors.green, // Success color
              ),
            );
        } else if (state.dataManagementStatus == DataManagementStatus.error &&
            state.dataManagementMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.dataManagementMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
        }

        // --- Keep existing listeners for other errors ---
        if (state.status == SettingsStatus.error &&
            state.errorMessage != null) {
          // Avoid double-showing data management errors if they also set main status
          if (state.dataManagementStatus != DataManagementStatus.error) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text('Settings Error: ${state.errorMessage}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
          }
        } else if (state.packageInfoStatus == PackageInfoStatus.error &&
            state.packageInfoError != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Version Error: ${state.packageInfoError}'),
                backgroundColor: Colors.orange,
              ),
            );
        }
        // ----------------------------------------------------
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            // Determine if a data management operation is in progress
            final bool isDataManagementLoading =
                state.dataManagementStatus == DataManagementStatus.loading;

            // Show full page loader only if initial load is happening
            if ((state.status == SettingsStatus.loading ||
                    state.status == SettingsStatus.initial) &&
                (state.packageInfoStatus == PackageInfoStatus.loading ||
                    state.packageInfoStatus == PackageInfoStatus.initial) &&
                !isDataManagementLoading) {
              // Don't show full loader if only DM is loading
              return const Center(child: CircularProgressIndicator());
            }

            // Build the settings list, disable items if data management is loading
            return Stack(
              // Use Stack to overlay loading indicator
              children: [
                ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  children: [
                    // Theme
                    ListTile(
                      enabled:
                          !isDataManagementLoading, // Disable during DM ops
                      leading: const Icon(Icons.color_lens_outlined),
                      title: const Text('Theme'),
                      subtitle: Text(state.themeMode.name.capitalize()),
                      trailing: PopupMenuButton<ThemeMode>(
                        enabled: !isDataManagementLoading,
                        icon: const Icon(Icons.arrow_drop_down),
                        tooltip: "Select Theme",
                        onSelected: (ThemeMode newMode) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateTheme(newMode));
                        },
                        itemBuilder: _buildThemeMenuItems,
                      ),
                    ),
                    const Divider(),

                    // Currency
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: DropdownButtonFormField<String>(
                        value: _currencySymbols.contains(state.currencySymbol)
                            ? state.currencySymbol
                            : null,
                        decoration: InputDecoration(
                          labelText: 'Currency Symbol',
                          icon: const Icon(Icons.attach_money_outlined),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          enabled:
                              !isDataManagementLoading, // Disable during DM ops
                        ),
                        hint: const Text('Select Currency'),
                        isExpanded: true,
                        items: _currencySymbols.map((String symbol) {
                          return DropdownMenuItem<String>(
                              value: symbol, child: Text(symbol));
                        }).toList(),
                        onChanged: isDataManagementLoading
                            ? null
                            : (String? newValue) {
                                // Disable during DM ops
                                if (newValue != null) {
                                  context
                                      .read<SettingsBloc>()
                                      .add(UpdateCurrency(newValue));
                                }
                              },
                        validator: (value) =>
                            value == null ? 'Please select a currency' : null,
                      ),
                    ),
                    const Divider(),

                    // Backup
                    ListTile(
                      enabled: !isDataManagementLoading,
                      leading: const Icon(Icons.storage_outlined),
                      title: const Text('Backup Data'),
                      subtitle: const Text('Save data to a local file'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _handleBackup(context),
                    ),
                    // Restore
                    ListTile(
                      enabled: !isDataManagementLoading,
                      leading: const Icon(Icons.restore_outlined),
                      title: const Text('Restore Data'),
                      subtitle: const Text('Load data from a backup file'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _handleRestore(context),
                    ),
                    // Clear Data
                    ListTile(
                      enabled: !isDataManagementLoading,
                      leading: Icon(Icons.delete_forever_outlined,
                          color: isDataManagementLoading
                              ? Colors.grey
                              : Theme.of(context).colorScheme.error),
                      title: Text('Clear All Data',
                          style: TextStyle(
                              color: isDataManagementLoading
                                  ? Colors.grey
                                  : Theme.of(context).colorScheme.error)),
                      subtitle: Text(
                          'Permanently delete all accounts & transactions',
                          style: TextStyle(
                              color: isDataManagementLoading
                                  ? Colors.grey
                                  : null)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _handleClearData(context),
                    ),
                    const Divider(),

                    // App Lock
                    SwitchListTile(
                      secondary: const Icon(Icons.security_outlined),
                      title: const Text('App Lock'),
                      value: state.isAppLockEnabled,
                      onChanged: isDataManagementLoading
                          ? null
                          : (bool value) {
                              // Disable during DM ops
                              context
                                  .read<SettingsBloc>()
                                  .add(UpdateAppLock(value));
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(const SnackBar(
                                    content: Text(
                                        'App Lock requires restart (Not fully implemented yet)')));
                            },
                    ),
                    const Divider(),

                    // App Version
                    ListTile(
                      enabled: !isDataManagementLoading,
                      leading: const Icon(Icons.info_outline),
                      title: const Text('App Version'),
                      subtitle: Text(state.packageInfoStatus ==
                              PackageInfoStatus.loading
                          ? 'Loading...'
                          : state.packageInfoStatus == PackageInfoStatus.error
                              ? 'Error loading version'
                              : state.appVersion ?? 'N/A'),
                    ),

                    // Licenses
                    ListTile(
                      enabled: !isDataManagementLoading,
                      leading: const Icon(Icons.article_outlined),
                      title: const Text('Open Source Licenses'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) =>
                                const LicensePage(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                  ],
                ),

                // --- Loading Overlay for Data Management ---
                if (isDataManagementLoading)
                  Container(
                    color: Colors.black
                        .withOpacity(0.3), // Semi-transparent overlay
                    child: const Center(
                      child: Card(
                        // Show indicator inside a card
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 15),
                              Text("Processing data...",
                                  style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // -----------------------------------------
              ],
            );
          },
        ),
      ),
    );
  }
}

// Capitalize extension (keep this)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
