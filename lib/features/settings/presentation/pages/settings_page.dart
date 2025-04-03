// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For PlatformException
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart'; // Import Theme Extension & helper
import 'package:flutter_svg/flutter_svg.dart'; // Import SVG

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
  // (_showConfirmationDialog and _showStrongConfirmationDialog remain unchanged)
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
                          isDense: true),
                      validator: (value) => (value != confirmationPhrase)
                          ? 'Incorrect phrase'
                          : null,
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
  // (_handleBackup, _handleRestore, _handleClearData, _handleAppLockToggle remain unchanged)
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
    final confirmed = await _showStrongConfirmationDialog(
      context: context,
      title: "Confirm Clear All Data",
      content:
          "This action will permanently delete ALL accounts, expenses, and income data. This cannot be undone.",
      confirmText: "Clear Data",
      confirmationPhrase: "DELETE",
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
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    try {
      bool canAuth = false;
      if (enable) {
        canAuth = await _localAuth.canCheckBiometrics ||
            await _localAuth.isDeviceSupported();
        if (!canAuth) {
          log.warning(
              "[SettingsPage] Cannot enable App Lock: Biometrics/Device lock not available/setup.");
          if (mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: const Text(
                    "Cannot enable App Lock. Please set up device screen lock or biometrics first."),
                backgroundColor: Theme.of(context).colorScheme.error,
              ));
          }
          setState(() => _isAuthenticating = false); // Reset loading state
          return; // Exit early
        }
      }
      log.info(
          "[SettingsPage] Dispatching UpdateAppLock event. IsEnabled: $enable");
      context.read<SettingsBloc>().add(UpdateAppLock(enable));
    } on PlatformException catch (e, s) {
      log.severe(
          "[SettingsPage] PlatformException checking/setting App Lock$e$s");
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text("Error setting App Lock: ${e.message}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
      }
    } catch (e, s) {
      log.severe(
          "[SettingsPage] Unexpected error checking/setting App Lock$e$s");
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

  // Helper to get relevant palettes for the current UI mode
  List<String> _getRelevantPaletteIdentifiers(UIMode uiMode) {
    switch (uiMode) {
      case UIMode.elemental:
        return [
          AppTheme.elementalPalette1,
          AppTheme.elementalPalette2,
          AppTheme.elementalPalette3,
          AppTheme.elementalPalette4,
        ];
      case UIMode.quantum:
        return [
          AppTheme.quantumPalette1,
          AppTheme.quantumPalette2,
          AppTheme.quantumPalette3,
          AppTheme.quantumPalette4,
        ];
      case UIMode.aether:
        return [
          AppTheme.aetherPalette1,
          AppTheme.aetherPalette2,
          AppTheme.aetherPalette3,
          AppTheme.aetherPalette4,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;

    // --- Define Default Paths Here ---
    const String defaultThemeIconPath =
        'assets/elemental/icons/common/ic_theme.svg';
    const String defaultInfoIconPath =
        'assets/elemental/icons/common/ic_settings.svg'; // Placeholder
    const String defaultLicenseIconPath =
        'assets/elemental/icons/common/ic_settings.svg'; // Placeholder
    const String defaultBackupIconPath =
        'assets/elemental/icons/common/ic_settings.svg'; // Placeholder
    const String defaultRestoreIconPath =
        'assets/elemental/icons/common/ic_settings.svg'; // Placeholder
    const String defaultClearIconPath =
        'assets/elemental/icons/common/ic_delete.svg';

    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        // Feedback messages... (unchanged)
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
            // Define loading state within build scope
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

            // Helper function defined inside build to capture 'isOverallLoading'
            Widget buildLeadingIconScoped(
                String semanticName, String defaultPath) {
              final String iconPath = modeTheme?.assets
                      .getCommonIcon(semanticName, defaultPath: '') ??
                  '';
              final Color iconColor = isOverallLoading
                  ? theme.disabledColor
                  : theme.listTileTheme.iconColor ??
                      theme.colorScheme.onSurfaceVariant;

              if (iconPath.isNotEmpty &&
                  iconPath.toLowerCase().endsWith('.svg')) {
                try {
                  if (iconPath.startsWith('assets/')) {
                    return SvgPicture.asset(iconPath,
                        width: 24,
                        height: 24,
                        colorFilter:
                            ColorFilter.mode(iconColor, BlendMode.srcIn));
                  }
                } catch (e) {
                  log.warning("Failed to load SVG asset '$iconPath': $e");
                }
              }
              // Fallback logic using the map
              // FIX: Use direct string keys instead of AppModeTheme constants
              const Map<String, IconData> fallbackIcons = {
                'settings': Icons.settings_outlined,
                'theme': Icons.color_lens_outlined,
                'brightness': Icons.brightness_6_outlined,
                'ui_mode': Icons.view_quilt_outlined,
                'country': Icons.public_outlined,
                'security': Icons.security_outlined,
                'backup': Icons.backup_outlined,
                'restore': Icons.restore_page_outlined,
                'delete': Icons.delete_sweep_outlined,
                'info': Icons.info_outline,
                'license': Icons.article_outlined,
              };
              return Icon(fallbackIcons[semanticName] ?? Icons.help_outline,
                  color: iconColor);
            }

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  children: [
                    _buildSectionHeader(context, 'Appearance'),
                    ListTile(
                      // UI Mode
                      enabled: !isOverallLoading,
                      leading: buildLeadingIconScoped('ui_mode', ''),
                      title: Text('UI Mode',
                          style: TextStyle(
                              color: isOverallLoading
                                  ? theme.disabledColor
                                  : null)),
                      subtitle: Text(AppTheme.uiModeNames[state.uiMode] ??
                          StringExtension(state.uiMode.name).capitalize()),
                      trailing: PopupMenuButton<UIMode>(
                        enabled: !isOverallLoading,
                        icon: const Icon(Icons.arrow_drop_down),
                        tooltip: "Select UI Mode",
                        initialValue: state.uiMode,
                        onSelected: (UIMode newMode) {
                          final newPalettes =
                              _getRelevantPaletteIdentifiers(newMode);
                          String nextPalette = state.paletteIdentifier;
                          if (!newPalettes.contains(nextPalette) &&
                              newPalettes.isNotEmpty) {
                            switch (newMode) {
                              case UIMode.elemental:
                                nextPalette = AppTheme.elementalPalette1;
                                break;
                              case UIMode.quantum:
                                nextPalette = AppTheme.quantumPalette1;
                                break;
                              case UIMode.aether:
                                nextPalette = AppTheme.aetherPalette1;
                                break;
                            }
                            context
                                .read<SettingsBloc>()
                                .add(UpdatePaletteIdentifier(nextPalette));
                          }
                          context
                              .read<SettingsBloc>()
                              .add(UpdateUIMode(newMode));
                        },
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
                    ListTile(
                      // Palette
                      enabled: !isOverallLoading &&
                          relevantPaletteIdentifiers.isNotEmpty,
                      leading: buildLeadingIconScoped(
                          'theme', defaultThemeIconPath), // FIX: Use string key
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
                    ListTile(
                      // Brightness
                      enabled: !isOverallLoading,
                      leading: buildLeadingIconScoped('brightness', ''),
                      title: Text('Brightness Mode',
                          style: TextStyle(
                              color: isOverallLoading
                                  ? theme.disabledColor
                                  : null)),
                      subtitle: Text(
                          StringExtension(state.themeMode.name).capitalize()),
                      trailing: PopupMenuButton<ThemeMode>(
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
                    Padding(
                      // Country / Currency
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: DropdownButtonFormField<String>(
                        value: SettingsState.availableCountries
                                .any((c) => c.code == state.selectedCountryCode)
                            ? state.selectedCountryCode
                            : null,
                        decoration: InputDecoration(
                            labelText: 'Country / Currency',
                            icon: buildLeadingIconScoped('country', ''),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            enabled: !isOverallLoading),
                        hint: const Text('Select Country'),
                        isExpanded: true,
                        items: SettingsState.availableCountries
                            .map((CountryInfo country) => DropdownMenuItem<
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
                    SwitchListTile(
                      secondary: buildLeadingIconScoped('security', ''),
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
                    ListTile(
                      // Backup
                      enabled: !isOverallLoading,
                      leading: buildLeadingIconScoped('backup',
                          defaultBackupIconPath), // FIX: Use string key
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
                    ListTile(
                      // Restore
                      enabled: !isOverallLoading,
                      leading: buildLeadingIconScoped('restore',
                          defaultRestoreIconPath), // FIX: Use string key
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
                          : () => _handleRestore(context),
                    ),
                    ListTile(
                      // Clear Data
                      enabled: !isOverallLoading,
                      leading: buildLeadingIconScoped('delete',
                          defaultClearIconPath), // FIX: Use string key
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
                          : () => _handleClearData(context),
                    ),
                    const Divider(),
                    _buildSectionHeader(context, 'About'),
                    ListTile(
                      // App Version
                      enabled: !isOverallLoading,
                      leading: buildLeadingIconScoped(
                          'info', defaultInfoIconPath), // FIX: Use string key
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
                    ListTile(
                      // Licenses
                      enabled: !isOverallLoading,
                      leading: buildLeadingIconScoped('license',
                          defaultLicenseIconPath), // FIX: Use string key
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
                  ],
                ),
                if (isOverallLoading) // Loading Overlay
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
                                          : "Loading settings...",
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
} // End of _SettingsViewState

// Capitalize extension
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
