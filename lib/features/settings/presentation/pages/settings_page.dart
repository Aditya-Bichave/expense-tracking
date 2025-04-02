import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For PlatformException
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/theme/app_theme.dart'; // For theme names/IDs

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming SettingsBloc is provided globally
    return const SettingsView();
  }
}

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false; // For App Lock toggle UI feedback

  // --- Dialog Functions ---
  Future<bool?> _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
    Color? confirmColor,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(content, style: Theme.of(ctx).textTheme.bodyMedium),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(ctx).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor:
                      confirmColor ?? Theme.of(ctx).colorScheme.primary),
              child: Text(confirmText),
              onPressed: () {
                Navigator.of(ctx).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showStrongConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
    required String confirmationPhrase,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(title),
          content: StatefulBuilder(
            // Use StatefulBuilder for text field validation within dialog
            builder: (context, setDialogState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(content,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 15),
                    Text('Please type "$confirmationPhrase" to confirm:',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: confirmationPhrase,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value != confirmationPhrase) {
                          return 'Incorrect phrase';
                        }
                        return null;
                      },
                      // Auto-validate or validate on action press
                      // autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(ctx).colorScheme.error),
              child: Text(confirmText),
              onPressed: () {
                // Validate before closing
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(ctx).pop(true); // Confirmed
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- Event Handlers ---
  void _handleBackup(BuildContext context) {
    log.info("[SettingsPage] Backup requested.");
    context.read<SettingsBloc>().add(const BackupRequested());
  }

  void _handleRestore(BuildContext context) async {
    log.info("[SettingsPage] Restore requested.");
    final confirmed = await _showConfirmationDialog(
      context: context,
      title: "Confirm Restore",
      content:
          "Restoring from backup will overwrite all current data. Are you sure you want to proceed?",
      confirmText: "Restore",
      confirmColor: Colors.orange[700],
    );
    if (confirmed == true) {
      log.info("[SettingsPage] Restore confirmed by user.");
      context.read<SettingsBloc>().add(const RestoreRequested());
    } else {
      log.info("[SettingsPage] Restore cancelled by user.");
    }
  }

  void _handleClearData(BuildContext context) async {
    log.info("[SettingsPage] Clear All Data requested.");
    // Use strong confirmation
    final confirmed = await _showStrongConfirmationDialog(
      context: context,
      title: "Confirm Clear All Data",
      content:
          "This action will permanently delete ALL accounts, expenses, and income data. This cannot be undone.",
      confirmText: "Clear Data",
      confirmationPhrase: "DELETE", // Phrase user must type
    );

    if (confirmed == true) {
      log.info("[SettingsPage] Clear All Data confirmed by user.");
      context.read<SettingsBloc>().add(const ClearDataRequested());
    } else {
      log.info("[SettingsPage] Clear All Data cancelled by user.");
    }
  }

  Future<void> _handleAppLockToggle(BuildContext context, bool enable) async {
    log.info("[SettingsPage] App Lock toggle requested. Enable: $enable");
    if (_isAuthenticating) return; // Prevent double taps

    setState(() => _isAuthenticating = true); // Show loading indicator

    try {
      bool canAuth = false;
      if (enable) {
        // Only check if enabling
        canAuth = await _localAuth.canCheckBiometrics ||
            await _localAuth.isDeviceSupported();
        if (!canAuth) {
          log.warning(
              "[SettingsPage] Cannot enable App Lock: Biometrics/Device lock not available/setup.");
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: const Text(
                  "Cannot enable App Lock. Please set up device screen lock or biometrics first."),
              backgroundColor: Theme.of(context).colorScheme.error,
            ));
          // Revert the state in BLoC if needed (though UI switch will likely revert automatically)
          // context.read<SettingsBloc>().add(UpdateAppLock(false));
          return; // Exit early
        }
        // Optional: Prompt for authentication *before* saving the setting
        // final didAuthenticate = await _localAuth.authenticate(...);
        // if (!didAuthenticate) return;
      }
      log.info(
          "[SettingsPage] Dispatching UpdateAppLock event. IsEnabled: $enable");
      // If checks pass (or disabling), dispatch the event
      context.read<SettingsBloc>().add(UpdateAppLock(enable));
    } on PlatformException catch (e, s) {
      log.severe(
          "[SettingsPage] PlatformException checking/setting App Lock$e$s");
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text("Error setting App Lock: ${e.message}"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
    } catch (e, s) {
      log.severe(
          "[SettingsPage] Unexpected error checking/setting App Lock$e$s");
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text("An unexpected error occurred setting App Lock."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        // Show feedback messages for data operations
        if (state.dataManagementStatus == DataManagementStatus.success &&
            state.dataManagementMessage != null) {
          log.info(
              "[SettingsPage] Data management success: ${state.dataManagementMessage}");
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.dataManagementMessage!),
              backgroundColor: Colors.green,
            ));
        } else if (state.dataManagementStatus == DataManagementStatus.error &&
            state.dataManagementMessage != null) {
          log.warning(
              "[SettingsPage] Data management error: ${state.dataManagementMessage}");
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.dataManagementMessage!),
              backgroundColor: theme.colorScheme.error,
            ));
        }
        // Show errors related to loading main settings or package info
        if (state.status == SettingsStatus.error &&
            state.errorMessage != null) {
          log.warning(
              "[SettingsPage] Main settings error: ${state.errorMessage}");
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text("Settings Error: ${state.errorMessage!}"),
              backgroundColor: theme.colorScheme.error,
            ));
        } else if (state.packageInfoStatus == PackageInfoStatus.error &&
            state.packageInfoError != null) {
          log.warning(
              "[SettingsPage] Package info error: ${state.packageInfoError}");
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text("Version Info Error: ${state.packageInfoError!}"),
              backgroundColor: theme.colorScheme.error,
            ));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            final bool isDataManagementLoading =
                state.dataManagementStatus == DataManagementStatus.loading;
            final bool isSettingsLoading =
                state.status == SettingsStatus.loading ||
                    state.packageInfoStatus == PackageInfoStatus.loading;
            final bool isOverallLoading = isDataManagementLoading ||
                _isAuthenticating ||
                isSettingsLoading;

            // Initial loading indicator for the whole page
            if (state.status == SettingsStatus.initial ||
                state.packageInfoStatus == PackageInfoStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            // Use Stack for overlay loading indicator during data operations
            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  children: [
                    // --- Appearance Section ---
                    _buildSectionHeader(context, 'Appearance'),
                    ListTile(
                      // Theme Identifier Selection
                      enabled: !isOverallLoading,
                      leading: const Icon(Icons.palette_outlined),
                      title: const Text('App Theme'),
                      subtitle: Text(
                          AppTheme.getThemeName(state.selectedThemeIdentifier)),
                      trailing: PopupMenuButton<String>(
                        enabled: !isOverallLoading,
                        icon: const Icon(Icons.arrow_drop_down),
                        tooltip: "Select App Theme",
                        onSelected: (String newIdentifier) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateThemeIdentifier(newIdentifier));
                        },
                        itemBuilder: (context) =>
                            AppTheme.availableThemeIdentifiers
                                .map((id) => PopupMenuItem<String>(
                                      value: id,
                                      child: Text(AppTheme.getThemeName(id),
                                          style: theme.textTheme.bodyMedium),
                                    ))
                                .toList(),
                      ),
                    ),
                    ListTile(
                      // Theme Mode (Light/Dark/System)
                      enabled: !isOverallLoading,
                      leading: const Icon(Icons.brightness_6_outlined),
                      title: const Text('Theme Mode'),
                      subtitle: Text(state.themeMode.name.capitalize()),
                      trailing: PopupMenuButton<ThemeMode>(
                        enabled: !isOverallLoading,
                        icon: const Icon(Icons.arrow_drop_down),
                        tooltip: "Select Theme Mode",
                        onSelected: (ThemeMode newMode) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdateTheme(newMode));
                        },
                        itemBuilder: (context) => ThemeMode.values
                            .map((mode) => PopupMenuItem<ThemeMode>(
                                  value: mode,
                                  child: Text(mode.name.capitalize(),
                                      style: theme.textTheme.bodyMedium),
                                ))
                            .toList(),
                      ),
                    ),
                    const Divider(),

                    // --- Regional Settings Section ---
                    _buildSectionHeader(context, 'Regional'),
                    Padding(
                      // Country / Currency
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: DropdownButtonFormField<String>(
                        value: SettingsState.availableCountries
                                .any((c) => c.code == state.selectedCountryCode)
                            ? state.selectedCountryCode
                            : null, // Ensure value exists in items
                        decoration: InputDecoration(
                          labelText: 'Country / Currency',
                          icon: const Icon(Icons.public_outlined),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          enabled: !isOverallLoading,
                        ),
                        hint: const Text('Select Country'),
                        isExpanded: true,
                        items: SettingsState.availableCountries
                            .map((CountryInfo country) {
                          return DropdownMenuItem<String>(
                            value: country.code,
                            child: Text(
                                '${country.name} (${country.currencySymbol})'),
                          );
                        }).toList(),
                        onChanged: isOverallLoading
                            ? null
                            : (String? newValue) {
                                if (newValue != null) {
                                  context
                                      .read<SettingsBloc>()
                                      .add(UpdateCountry(newValue));
                                }
                              },
                        // validator: (value) => value == null ? 'Please select a country' : null, // Optional validation
                      ),
                    ),
                    const Divider(),

                    // --- Security Section ---
                    _buildSectionHeader(context, 'Security'),
                    SwitchListTile(
                      secondary: Icon(
                        Icons.security_outlined,
                        color: isOverallLoading ? theme.disabledColor : null,
                      ),
                      title: Text(
                        'App Lock',
                        style: TextStyle(
                            color:
                                isOverallLoading ? theme.disabledColor : null),
                      ),
                      subtitle: Text(
                        'Require authentication on launch/resume',
                        style: TextStyle(
                            color:
                                isOverallLoading ? theme.disabledColor : null),
                      ),
                      value: state.isAppLockEnabled,
                      onChanged: isOverallLoading
                          ? null
                          : (bool value) =>
                              _handleAppLockToggle(context, value),
                    ),
                    const Divider(),

                    // --- Data Management Section ---
                    _buildSectionHeader(context, 'Data Management'),
                    ListTile(
                      // Backup
                      enabled: !isOverallLoading,
                      leading:
                          const Icon(Icons.backup_outlined), // Changed icon
                      title: const Text('Backup Data'),
                      subtitle: const Text('Save all data to a file'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: isOverallLoading
                          ? null
                          : () => _handleBackup(context),
                    ),
                    ListTile(
                      // Restore
                      enabled: !isOverallLoading,
                      leading: const Icon(
                          Icons.restore_page_outlined), // Changed icon
                      title: const Text('Restore Data'),
                      subtitle: const Text('Load data from a backup file'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: isOverallLoading
                          ? null
                          : () => _handleRestore(context),
                    ),
                    ListTile(
                      // Clear Data
                      enabled: !isOverallLoading,
                      leading: Icon(Icons.delete_sweep_outlined,
                          color: isOverallLoading
                              ? Colors.grey
                              : theme.colorScheme.error), // Changed icon
                      title: Text('Clear All Data',
                          style: TextStyle(
                              color: isOverallLoading
                                  ? Colors.grey
                                  : theme.colorScheme.error)),
                      subtitle: Text(
                          'Permanently delete all accounts & transactions',
                          style: TextStyle(
                              color: isOverallLoading ? Colors.grey : null)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: isOverallLoading
                          ? null
                          : () => _handleClearData(context),
                    ),
                    const Divider(),

                    // --- About Section ---
                    _buildSectionHeader(context, 'About'),
                    ListTile(
                      // App Version
                      enabled: !isOverallLoading,
                      leading: const Icon(Icons.info_outline),
                      title: const Text('App Version'),
                      subtitle: Text(state.packageInfoStatus ==
                              PackageInfoStatus.loading
                          ? 'Loading...'
                          : state.packageInfoStatus == PackageInfoStatus.error
                              ? state.packageInfoError ?? 'Error'
                              : state.appVersion ?? 'N/A'),
                    ),
                    ListTile(
                      // Licenses
                      enabled: !isOverallLoading,
                      leading: const Icon(Icons.article_outlined),
                      title: const Text('Open Source Licenses'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: isOverallLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                    builder: (BuildContext context) =>
                                        const LicensePage()),
                              );
                            },
                    ),
                    const Divider(),
                  ],
                ),

                // Loading Overlay for Data Ops / Auth Check
                if (isOverallLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: Card(
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                  _isAuthenticating
                                      ? "Authenticating..."
                                      : isDataManagementLoading
                                          ? "Processing data..."
                                          : "Loading settings...", // Generic loading
                                  style: theme.textTheme.titleMedium),
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

  // Helper to build section headers
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

// Capitalize extension (can be moved to utils)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
