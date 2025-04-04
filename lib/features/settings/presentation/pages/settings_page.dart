// lib/features/settings/presentation/pages/settings_page.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

// Core / DI / Bloc
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For PlatformException
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';

// Utils / Constants / Data
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/data/countries.dart'; // Import AppCountries
import 'package:expense_tracker/core/utils/app_dialogs.dart'; // Import AppDialogs

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
  bool _isAuthenticating = false;

  // --- Event Handlers using AppDialogs ---
  void _handleBackup(BuildContext context) {
    log.info("[SettingsPage] Backup requested.");
    context.read<SettingsBloc>().add(const BackupRequested());
  }

  void _handleRestore(BuildContext context) async {
    log.info("[SettingsPage] Restore requested.");
    // --- Use AppDialogs (Context is first argument) ---
    final confirmed = await AppDialogs.showConfirmation(
      context, // Pass context as the first argument
      title: "Confirm Restore",
      content:
          "Restoring from backup will overwrite all current data. Are you sure you want to proceed?",
      confirmText: "Restore",
      confirmColor: Colors.orange[700],
    );
    // --------------------------------------------------
    if (confirmed == true) {
      log.info("[SettingsPage] Restore confirmed by user.");
      context.read<SettingsBloc>().add(const RestoreRequested());
    } else {
      log.info("[SettingsPage] Restore cancelled by user.");
    }
  }

  void _handleClearData(BuildContext context) async {
    log.info("[SettingsPage] Clear All Data requested.");
    // --- Use AppDialogs (Context is first argument) ---
    final confirmed = await AppDialogs.showStrongConfirmation(
      context, // Pass context as the first argument
      title: "Confirm Clear All Data",
      content:
          "This action will permanently delete ALL accounts, expenses, and income data. This cannot be undone.",
      confirmText: "Clear Data",
      confirmationPhrase: "DELETE",
      confirmColor: Theme.of(context).colorScheme.error,
    );
    // --------------------------------------------------
    if (confirmed == true) {
      log.info("[SettingsPage] Clear All Data confirmed by user.");
      context.read<SettingsBloc>().add(const ClearDataRequested());
    } else {
      log.info("[SettingsPage] Clear All Data cancelled by user.");
    }
  }

  Future<void> _handleAppLockToggle(BuildContext context, bool enable) async {
    log.info("[SettingsPage] App Lock toggle requested. Enable: $enable");
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    try {
      bool canAuth = false;
      if (enable) {
        canAuth = await _localAuth.canCheckBiometrics ||
            await _localAuth.isDeviceSupported();
        if (!canAuth && mounted) {
          // Added mounted check before showing SnackBar
          log.warning(
              "[SettingsPage] Cannot enable App Lock: Biometrics/Device lock not available/setup.");
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: const Text(
                  "Cannot enable App Lock. Please set up device screen lock or biometrics first."),
              backgroundColor: Theme.of(context).colorScheme.error,
            ));
          // Important: Reset _isAuthenticating if we return early
          setState(() => _isAuthenticating = false);
          return; // Exit early
        }
      }
      // Only proceed if canAuth is true (when enabling) or if disabling
      if (mounted) {
        // Check mounted before accessing context
        log.info(
            "[SettingsPage] Dispatching UpdateAppLock event. IsEnabled: $enable");
        context.read<SettingsBloc>().add(UpdateAppLock(enable));
      }
    } on PlatformException catch (e, s) {
      log.severe("[SettingsPage] PlatformException checking/setting App Lock");
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text("Error setting App Lock: ${e.message}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
      }
    } catch (e, s) {
      log.severe("[SettingsPage] Unexpected error checking/setting App Lock");
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content:
                const Text("An unexpected error occurred setting App Lock."),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  // --- Helper Functions (Remain the same) ---
  List<String> _getRelevantPaletteIdentifiers(UIMode uiMode) {
    switch (uiMode) {
      case UIMode.elemental:
        return [
          AppTheme.elementalPalette1,
          AppTheme.elementalPalette2,
          AppTheme.elementalPalette3,
          AppTheme.elementalPalette4
        ];
      case UIMode.quantum:
        return [
          AppTheme.quantumPalette1,
          AppTheme.quantumPalette2,
          AppTheme.quantumPalette3,
          AppTheme.quantumPalette4
        ];
      case UIMode.aether:
        return [
          AppTheme.aetherPalette1,
          AppTheme.aetherPalette2,
          AppTheme.aetherPalette3,
          AppTheme.aetherPalette4
        ];
    }
  }

  Widget _buildLeadingIcon(
      BuildContext context, String semanticName, bool isDisabled) {
    final theme = Theme.of(context);
    final color = isDisabled
        ? theme.disabledColor
        : theme.listTileTheme.iconColor ?? theme.colorScheme.onSurfaceVariant;
    const Map<String, IconData> standardIcons = {
      'settings': Icons.settings_outlined,
      'ui_mode': Icons.view_quilt_outlined,
      'theme': Icons.palette_outlined,
      'brightness': Icons.brightness_6_outlined,
      'country': Icons.public_outlined,
      'security': Icons.security_outlined,
      'backup': Icons.backup_outlined,
      'restore': Icons.restore_page_outlined,
      'delete': Icons.delete_sweep_outlined,
      'info': Icons.info_outline,
      'license': Icons.article_outlined,
    };
    return Icon(standardIcons[semanticName] ?? Icons.help_outline,
        color: color);
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;

    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        // Feedback messages
        if (state.dataManagementStatus == DataManagementStatus.success &&
            state.dataManagementMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
                content: Text(state.dataManagementMessage!),
                backgroundColor: Colors.green));
        } else if (state.dataManagementStatus == DataManagementStatus.error &&
            state.dataManagementMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
                content: Text(state.dataManagementMessage!),
                backgroundColor: theme.colorScheme.error));
        }
        if (state.status == SettingsStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
                content: Text("Settings Error: ${state.errorMessage!}"),
                backgroundColor: theme.colorScheme.error));
        } else if (state.packageInfoStatus == PackageInfoStatus.error &&
            state.packageInfoError != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
                content: Text("Version Info Error: ${state.packageInfoError!}"),
                backgroundColor: theme.colorScheme.error));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
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

            if (state.status == SettingsStatus.initial ||
                state.packageInfoStatus == PackageInfoStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<String> relevantPaletteIdentifiers =
                _getRelevantPaletteIdentifiers(state.uiMode);
            final AppCountry? currentCountry =
                AppCountries.findCountryByCode(state.selectedCountryCode);

            return Stack(
              children: [
                ListView(
                  padding: modeTheme?.pagePadding.copyWith(top: 8, bottom: 8) ??
                      const EdgeInsets.symmetric(vertical: 8.0),
                  children: [
                    _buildSectionHeader(context, 'Appearance'),
                    // UI Mode ListTile
                    ListTile(
                      enabled: !isOverallLoading,
                      leading: _buildLeadingIcon(
                          context, 'ui_mode', isOverallLoading),
                      title: Text('UI Mode',
                          style: TextStyle(
                              color: isOverallLoading
                                  ? theme.disabledColor
                                  : null)),
                      subtitle: Text(AppTheme.uiModeNames[state.uiMode] ??
                          StringExtension(state.uiMode.name).capitalize()),
                      trailing: PopupMenuButton<UIMode>(
                        /* ... */
                        enabled: !isOverallLoading,
                        icon: const Icon(Icons.arrow_drop_down),
                        tooltip: "Select UI Mode",
                        initialValue: state.uiMode,
                        onSelected: (UIMode newMode) => context
                            .read<SettingsBloc>()
                            .add(UpdateUIMode(newMode)),
                        itemBuilder: (context) => UIMode.values
                            .map((mode) => PopupMenuItem<UIMode>(
                                  value: mode,
                                  child: Text(
                                      AppTheme.uiModeNames[mode] ??
                                          StringExtension(mode.name)
                                              .capitalize(),
                                      style: theme.textTheme.bodyMedium),
                                ))
                            .toList(),
                      ),
                    ),
                    // Palette ListTile
                    ListTile(
                      enabled: !isOverallLoading &&
                          relevantPaletteIdentifiers.isNotEmpty,
                      leading: _buildLeadingIcon(
                          context,
                          'theme',
                          isOverallLoading ||
                              relevantPaletteIdentifiers.isEmpty),
                      title: Text('Palette / Variant',
                          style: TextStyle(
                              color: isOverallLoading ||
                                      relevantPaletteIdentifiers.isEmpty
                                  ? theme.disabledColor
                                  : null)),
                      subtitle: Text(
                          AppTheme.paletteNames[state.paletteIdentifier] ??
                              state.paletteIdentifier),
                      trailing: relevantPaletteIdentifiers.isEmpty
                          ? null
                          : PopupMenuButton<String>(
                              /* ... */
                              enabled: !isOverallLoading,
                              icon: const Icon(Icons.arrow_drop_down),
                              tooltip: "Select Palette",
                              initialValue: state.paletteIdentifier,
                              onSelected: (String newIdentifier) => context
                                  .read<SettingsBloc>()
                                  .add(UpdatePaletteIdentifier(newIdentifier)),
                              itemBuilder: (context) =>
                                  relevantPaletteIdentifiers
                                      .map((id) => PopupMenuItem<String>(
                                            value: id,
                                            child: Text(
                                                AppTheme.paletteNames[id] ?? id,
                                                style:
                                                    theme.textTheme.bodyMedium),
                                          ))
                                      .toList(),
                            ),
                    ),
                    // Brightness ListTile
                    ListTile(
                      enabled: !isOverallLoading,
                      leading: _buildLeadingIcon(
                          context, 'brightness', isOverallLoading),
                      title: Text('Brightness Mode',
                          style: TextStyle(
                              color: isOverallLoading
                                  ? theme.disabledColor
                                  : null)),
                      subtitle: Text(
                          StringExtension(state.themeMode.name).capitalize()),
                      trailing: PopupMenuButton<ThemeMode>(
                        /* ... */
                        enabled: !isOverallLoading,
                        icon: const Icon(Icons.arrow_drop_down),
                        tooltip: "Select Brightness Mode",
                        initialValue: state.themeMode,
                        onSelected: (ThemeMode newMode) => context
                            .read<SettingsBloc>()
                            .add(UpdateTheme(newMode)),
                        itemBuilder: (context) => ThemeMode.values
                            .map((mode) => PopupMenuItem<ThemeMode>(
                                  value: mode,
                                  child: Text(
                                      StringExtension(mode.name).capitalize(),
                                      style: theme.textTheme.bodyMedium),
                                ))
                            .toList(),
                      ),
                    ),

                    const Divider(),
                    _buildSectionHeader(context, 'Regional'),
                    // Country Dropdown
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: DropdownButtonFormField<String>(
                        value: currentCountry?.code,
                        decoration: InputDecoration(
                            labelText: 'Country / Currency',
                            icon: _buildLeadingIcon(
                                context, 'country', isOverallLoading),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            enabled: !isOverallLoading),
                        hint: const Text('Select Country'),
                        isExpanded: true,
                        items: AppCountries.availableCountries
                            .map((AppCountry country) => DropdownMenuItem<
                                    String>(
                                value: country.code,
                                child: Text(
                                    '${country.name} (${country.currencySymbol})')))
                            .toList(),
                        onChanged: isOverallLoading
                            ? null
                            : (String? newValue) {
                                if (newValue != null) {
                                  context
                                      .read<SettingsBloc>()
                                      .add(UpdateCountry(newValue));
                                }
                              },
                      ),
                    ),

                    const Divider(),
                    _buildSectionHeader(context, 'Security'),
                    // App Lock SwitchListTile
                    SwitchListTile(
                      secondary: _buildLeadingIcon(
                          context, 'security', isOverallLoading),
                      title: Text('App Lock',
                          style: TextStyle(
                              color: isOverallLoading
                                  ? theme.disabledColor
                                  : null)),
                      subtitle: Text('Require authentication on launch/resume',
                          style: TextStyle(
                              color: isOverallLoading
                                  ? theme.disabledColor
                                  : null)),
                      value: state.isAppLockEnabled,
                      onChanged: isOverallLoading
                          ? null
                          : (bool value) =>
                              _handleAppLockToggle(context, value),
                    ),

                    const Divider(),
                    _buildSectionHeader(context, 'Data Management'),
                    // Backup ListTile
                    ListTile(
                      enabled: !isOverallLoading,
                      leading: _buildLeadingIcon(
                          context, 'backup', isOverallLoading),
                      title: Text('Backup Data',
                          style: TextStyle(
                              color: isOverallLoading
                                  ? theme.disabledColor
                                  : null)),
                      subtitle: Text('Save all data to a file',
                          style: TextStyle(
                              color: isOverallLoading
                                  ? theme.disabledColor
                                  : null)),
                      trailing: Icon(Icons.chevron_right,
                          color: isOverallLoading ? theme.disabledColor : null),
                      onTap: isOverallLoading
                          ? null
                          : () => _handleBackup(context),
                    ),
                    // Restore ListTile
                    ListTile(
                      enabled: !isOverallLoading,
                      leading: _buildLeadingIcon(
                          context, 'restore', isOverallLoading),
                      title: Text('Restore Data',
                          style: TextStyle(
                              color: isOverallLoading
                                  ? theme.disabledColor
                                  : null)),
                      subtitle: Text('Load data from a backup file',
                          style: TextStyle(
                              color: isOverallLoading
                                  ? theme.disabledColor
                                  : null)),
                      trailing: Icon(Icons.chevron_right,
                          color: isOverallLoading ? theme.disabledColor : null),
                      onTap: isOverallLoading
                          ? null
                          : () =>
                              _handleRestore(context), // Calls updated handler
                    ),
                    // Clear Data ListTile
                    ListTile(
                      enabled: !isOverallLoading,
                      leading: _buildLeadingIcon(
                          context, 'delete', isOverallLoading),
                      title: Text('Clear All Data',
                          style: TextStyle(
                              color: isOverallLoading
                                  ? theme.disabledColor
                                  : theme.colorScheme.error)),
                      subtitle: Text(
                          'Permanently delete all accounts & transactions',
                          style: TextStyle(
                              color: isOverallLoading
                                  ? theme.disabledColor
                                  : null)),
                      trailing: Icon(Icons.chevron_right,
                          color: isOverallLoading ? theme.disabledColor : null),
                      onTap: isOverallLoading
                          ? null
                          : () => _handleClearData(
                              context), // Calls updated handler
                    ),

                    const Divider(),
                    _buildSectionHeader(context, 'About'),
                    // Version ListTile
                    ListTile(
                      enabled: !isOverallLoading,
                      leading:
                          _buildLeadingIcon(context, 'info', isOverallLoading),
                      title: Text('App Version',
                          style: TextStyle(
                              color: isOverallLoading
                                  ? theme.disabledColor
                                  : null)),
                      subtitle: Text(
                          state.packageInfoStatus == PackageInfoStatus.loading
                              ? 'Loading...'
                              : state.packageInfoStatus ==
                                      PackageInfoStatus.error
                                  ? state.packageInfoError ?? 'Error'
                                  : state.appVersion ?? 'N/A',
                          style: TextStyle(
                              color: isOverallLoading
                                  ? theme.disabledColor
                                  : null)),
                    ),
                    // Licenses ListTile
                    ListTile(
                      enabled: !isOverallLoading,
                      leading: _buildLeadingIcon(
                          context, 'license', isOverallLoading),
                      title: Text('Open Source Licenses',
                          style: TextStyle(
                              color: isOverallLoading
                                  ? theme.disabledColor
                                  : null)),
                      trailing: Icon(Icons.chevron_right,
                          color: isOverallLoading ? theme.disabledColor : null),
                      onTap: isOverallLoading
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                  builder: (BuildContext context) =>
                                      const LicensePage())),
                    ),
                    const Divider(),
                    const SizedBox(height: 60), // Bottom padding
                  ],
                ),

                // Loading Overlay
                if (isOverallLoading)
                  Positioned.fill(
                    child: Container(
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
                                            : "Loading settings...",
                                    style: theme.textTheme.titleMedium),
                              ],
                            ),
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

// Keep Capitalize extension local or move to utils
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
