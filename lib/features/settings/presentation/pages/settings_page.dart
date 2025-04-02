import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For PlatformException
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart'; // Import local_auth

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming SettingsBloc is provided globally via main.dart
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
  // State for dialogs and auth
  // Instantiate LocalAuthentication
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false; // Prevent double-taps during auth check

  static const List<String> _currencySymbols = [
    'USD', 'EUR', 'GBP', 'JPY', 'INR', 'CAD', 'AUD', 'CHF' // Add more as needed
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

  // --- Handle App Lock Toggle ---
  Future<void> _handleAppLockToggle(BuildContext context, bool enable) async {
    if (_isAuthenticating) return; // Prevent concurrent attempts

    if (!mounted) return; // Check mount status before async gap
    setState(() {
      _isAuthenticating = true;
    }); // Indicate processing

    final settingsBloc = context.read<SettingsBloc>();
    String? errorMessage;

    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        errorMessage =
            'Device does not support Biometric or Passcode authentication.';
        if (enable) {
          // Only revert if trying to enable
          // Schedule post-frame callback to safely update BLoC state if needed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) settingsBloc.add(const UpdateAppLock(false));
          });
        }
      } else if (enable) {
        // --- Enabling App Lock ---
        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to enable App Lock',
          options: const AuthenticationOptions(
            stickyAuth: true,
            // biometricOnly: false // Allow device credential fallback
          ),
        );

        if (didAuthenticate && mounted) {
          // Check mount status again after await
          settingsBloc.add(const UpdateAppLock(true));
        } else if (!didAuthenticate) {
          errorMessage = 'Authentication failed. App Lock remains disabled.';
          // No need to dispatch event, switch state didn't change
        }
      } else {
        // --- Disabling App Lock ---
        if (mounted) {
          // Check mount status
          settingsBloc.add(const UpdateAppLock(false));
        }
      }
    } on PlatformException catch (e) {
      errorMessage =
          'Platform Error: ${e.code} - ${e.message ?? 'Unknown error'}';
      // Schedule post-frame callback if trying to enable failed
      if (enable) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) settingsBloc.add(const UpdateAppLock(false));
        });
      }
    } catch (e) {
      errorMessage = 'An unexpected error occurred: $e';
      if (enable) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) settingsBloc.add(const UpdateAppLock(false));
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
        // Show error message if any occurred
        if (errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
        }
      }
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
            final bool isOverallLoading = isDataManagementLoading ||
                _isAuthenticating; // Combine loading states

            // Show full page loader only if initial load is happening
            if ((state.status == SettingsStatus.loading ||
                    state.status == SettingsStatus.initial) &&
                (state.packageInfoStatus == PackageInfoStatus.loading ||
                    state.packageInfoStatus == PackageInfoStatus.initial) &&
                !isOverallLoading) {
              // Don't show full loader if DM/Auth is loading
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
                      enabled: !isOverallLoading, // Use combined loading state
                      leading: const Icon(Icons.color_lens_outlined),
                      title: const Text('Theme'),
                      subtitle: Text(state.themeMode.name.capitalize()),
                      trailing: PopupMenuButton<ThemeMode>(
                        enabled:
                            !isOverallLoading, // Use combined loading state
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
                              !isOverallLoading, // Use combined loading state
                        ),
                        hint: const Text('Select Currency'),
                        isExpanded: true,
                        items: _currencySymbols.map((String symbol) {
                          return DropdownMenuItem<String>(
                              value: symbol, child: Text(symbol));
                        }).toList(),
                        onChanged: isOverallLoading
                            ? null
                            : (String? newValue) {
                                // Use combined loading state
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
                      enabled: !isOverallLoading, // Use combined loading state
                      leading: const Icon(Icons.storage_outlined),
                      title: const Text('Backup Data'),
                      subtitle: const Text('Save data to a local file'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: isOverallLoading
                          ? null
                          : () => _handleBackup(context), // Disable onTap
                    ),
                    // Restore
                    ListTile(
                      enabled: !isOverallLoading, // Use combined loading state
                      leading: const Icon(Icons.restore_outlined),
                      title: const Text('Restore Data'),
                      subtitle: const Text('Load data from a backup file'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: isOverallLoading
                          ? null
                          : () => _handleRestore(context), // Disable onTap
                    ),
                    // Clear Data
                    ListTile(
                      enabled: !isOverallLoading, // Use combined loading state
                      leading: Icon(Icons.delete_forever_outlined,
                          color: isOverallLoading
                              ? Colors.grey
                              : Theme.of(context).colorScheme.error),
                      title: Text('Clear All Data',
                          style: TextStyle(
                              color: isOverallLoading
                                  ? Colors.grey
                                  : Theme.of(context).colorScheme.error)),
                      subtitle: Text(
                          'Permanently delete all accounts & transactions',
                          style: TextStyle(
                              color: isOverallLoading ? Colors.grey : null)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: isOverallLoading
                          ? null
                          : () => _handleClearData(context), // Disable onTap
                    ),
                    const Divider(),

                    // App Lock
                    SwitchListTile(
                      secondary: Icon(
                        Icons.security_outlined,
                        // Optionally change icon color when disabled
                        color: isOverallLoading
                            ? Theme.of(context).disabledColor
                            : null,
                      ),
                      title: Text(
                        'App Lock',
                        // Optionally change text color when disabled
                        style: TextStyle(
                            color: isOverallLoading
                                ? Theme.of(context).disabledColor
                                : null),
                      ),
                      subtitle: Text(
                        'Require authentication on launch/resume',
                        style: TextStyle(
                            color: isOverallLoading
                                ? Theme.of(context).disabledColor
                                : null),
                      ),
                      value: state.isAppLockEnabled,
                      // Set onChanged to null to disable interaction
                      onChanged: isOverallLoading
                          ? null
                          : (bool value) =>
                              _handleAppLockToggle(context, value),
                    ),
                    const Divider(),

                    // App Version
                    ListTile(
                      enabled: !isOverallLoading, // Use combined loading state
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
                      enabled: !isOverallLoading, // Use combined loading state
                      leading: const Icon(Icons.article_outlined),
                      title: const Text('Open Source Licenses'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: isOverallLoading
                          ? null
                          : () {
                              // Disable onTap
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

                // Loading Overlay for Data Management OR Authentication
                if (isOverallLoading)
                  Container(
                    color: Colors.black
                        .withOpacity(0.3), // Semi-transparent overlay
                    child: Center(
                      child: Card(
                        // Show indicator inside a card
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 15),
                              Text(
                                  // Show appropriate message
                                  _isAuthenticating
                                      ? "Authenticating..."
                                      : "Processing data...",
                                  style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
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
