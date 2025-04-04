// lib/features/settings/presentation/pages/settings_page.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:expense_tracker/core/widgets/settings_list_tile.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/data/countries.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:expense_tracker/features/categories/presentation/pages/category_management_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming SettingsBloc is provided globally by MultiBlocProvider in main.dart
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

  // --- Event Handlers ---
  void _handleBackup(BuildContext context) {
    log.info("[SettingsPage] Backup requested.");
    context.read<SettingsBloc>().add(const BackupRequested());
  }

  void _handleRestore(BuildContext context) async {
    log.info("[SettingsPage] Restore requested.");
    final confirmed = await AppDialogs.showConfirmation(
      context,
      title: "Confirm Restore",
      content:
          "Restoring from backup will overwrite all current data. Are you sure you want to proceed?",
      confirmText: "Restore",
      confirmColor: Colors.orange[700], // Use a warning color
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
    final confirmed = await AppDialogs.showStrongConfirmation(
      context,
      title: "Confirm Clear All Data",
      content:
          "This action will permanently delete ALL accounts, expenses, and income data. This cannot be undone.",
      confirmText: "Clear Data",
      confirmationPhrase: "DELETE", // Require typing DELETE to confirm
      confirmColor: Theme.of(context).colorScheme.error,
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
    setState(() => _isAuthenticating = true); // Show loading indicator
    try {
      bool canAuth = false;
      if (enable) {
        // Check if authentication is possible BEFORE trying to enable
        canAuth = await _localAuth.canCheckBiometrics ||
            await _localAuth.isDeviceSupported();
        if (!canAuth && mounted) {
          log.warning(
              "[SettingsPage] Cannot enable App Lock: Biometrics/Device lock not available/setup.");
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: const Text(
                  "Cannot enable App Lock. Please set up device screen lock or biometrics first."),
              backgroundColor: Theme.of(context).colorScheme.error,
            ));
          setState(() => _isAuthenticating = false); // Hide loading
          return; // Stop if auth cannot be enabled
        }
      }
      // If checks pass or disabling, proceed to update the setting via BLoC
      if (mounted) {
        log.info(
            "[SettingsPage] Dispatching UpdateAppLock event. IsEnabled: $enable");
        context.read<SettingsBloc>().add(UpdateAppLock(enable));
        // Let the BlocListener handle the final state update and hide loading
      }
    } on PlatformException catch (e, s) {
      log.severe("[SettingsPage] PlatformException checking/setting App Lock");
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text("Error setting App Lock: ${e.message ?? e.code}"),
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
      // Ensure loading indicator is always turned off if mounted
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  // Helper to launch external URLs
  void _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        log.warning(
            "[SettingsPage] Could not launch URL (launchUrl returned false): $urlString");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not open link: $urlString'),
          ));
        }
      }
    } catch (e, s) {
      log.severe("[SettingsPage] Error launching URL $urlString");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error opening link: ${e.toString()}'),
        ));
      }
    }
  }

  // --- Helper Function ---
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;

    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        // Feedback snackbars for data management actions
        final dataMsg = state.dataManagementMessage;
        if (state.dataManagementStatus != DataManagementStatus.initial &&
            dataMsg != null) {
          final isError =
              state.dataManagementStatus == DataManagementStatus.error;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
                content: Text(dataMsg),
                backgroundColor:
                    isError ? theme.colorScheme.error : Colors.green));
          // TODO: Dispatch event to clear message: context.read<SettingsBloc>().add(ClearDataManagementMessage());
        }
        // Feedback for general settings load/save errors
        final errorMsg = state.errorMessage;
        if (state.status == SettingsStatus.error && errorMsg != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
                content: Text("Settings Error: $errorMsg"),
                backgroundColor: theme.colorScheme.error));
          // TODO: Dispatch event to clear message
        }
        // Feedback for package info errors
        final pkgErrorMsg = state.packageInfoError;
        if (state.packageInfoStatus == PackageInfoStatus.error &&
            pkgErrorMsg != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
                content: Text("Version Info Error: $pkgErrorMsg"),
                backgroundColor: theme.colorScheme.error));
          // TODO: Dispatch event to clear message
        }
      },
      child: Scaffold(
        // AppBar might be part of MainShell, so keep it minimal or remove if redundant
        // appBar: AppBar(title: const Text('Settings')),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            // Determine loading states
            final isDataManagementLoading =
                state.dataManagementStatus == DataManagementStatus.loading;
            final isSettingsLoading = state.status == SettingsStatus.loading ||
                state.packageInfoStatus == PackageInfoStatus.loading;
            // Combine all loading states that should disable interaction
            final isOverallLoading = isDataManagementLoading ||
                _isAuthenticating ||
                isSettingsLoading;

            // Show full screen loader only on initial load of settings
            if (state.status == SettingsStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<String> relevantPaletteIdentifiers =
                _getRelevantPaletteIdentifiers(state.uiMode);
            final AppCountry? currentCountry =
                AppCountries.findCountryByCode(state.selectedCountryCode);

            return Stack(
              // Stack allows overlaying the loading indicator
              children: [
                // Main Settings List
                ListView(
                  // Use themed padding or default, adjust top/bottom as needed
                  padding: modeTheme?.pagePadding.copyWith(top: 8, bottom: 8) ??
                      const EdgeInsets.symmetric(vertical: 8.0),
                  children: [
                    const SectionHeader(title: 'Appearance'),
                    SettingsListTile(
                      enabled: !isOverallLoading,
                      leadingIcon: Icons.view_quilt_outlined,
                      title: 'UI Mode',
                      subtitle: AppTheme.uiModeNames[state.uiMode] ??
                          StringExtension(state.uiMode.name).capitalize(),
                      trailing: PopupMenuButton<UIMode>(
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
                    SettingsListTile(
                      enabled: !isOverallLoading &&
                          relevantPaletteIdentifiers.isNotEmpty,
                      leadingIcon: Icons.palette_outlined,
                      title: 'Palette / Variant',
                      subtitle:
                          AppTheme.paletteNames[state.paletteIdentifier] ??
                              state.paletteIdentifier,
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
                    SettingsListTile(
                      enabled: !isOverallLoading,
                      leadingIcon: Icons.brightness_6_outlined,
                      title: 'Brightness Mode',
                      subtitle:
                          StringExtension(state.themeMode.name).capitalize(),
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

                    const SectionHeader(title: 'Management'),
                    SettingsListTile(
                      enabled: !isOverallLoading,
                      leadingIcon: Icons.category_outlined,
                      title: 'Manage Categories',
                      subtitle: 'Add, edit, or delete custom categories',
                      trailing: Icon(Icons.chevron_right,
                          color: isOverallLoading
                              ? theme.disabledColor
                              : theme.colorScheme.onSurfaceVariant),
                      onTap: isOverallLoading
                          ? null
                          : () {
                              log.info(
                                  "[SettingsPage] Navigating to Category Management.");
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) =>
                                    const CategoryManagementScreen(), // Assumes Bloc is provided
                              ));
                            },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: DropdownButtonFormField<String>(
                        value: currentCountry?.code,
                        decoration: InputDecoration(
                          labelText: 'Country / Currency',
                          prefixIcon: Icon(Icons.public_outlined,
                              color: isOverallLoading
                                  ? theme.disabledColor
                                  : theme.inputDecorationTheme.prefixIconColor),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          enabled: !isOverallLoading,
                        ),
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
                                if (newValue != null)
                                  context
                                      .read<SettingsBloc>()
                                      .add(UpdateCountry(newValue));
                              },
                      ),
                    ),

                    const SectionHeader(title: 'Security'),
                    SwitchListTile(
                      secondary: Icon(Icons.security_outlined,
                          color: isOverallLoading
                              ? theme.disabledColor
                              : theme.listTileTheme.iconColor),
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
                      activeColor: theme.colorScheme.primary,
                    ),
                    SettingsListTile(
                      enabled:
                          !isOverallLoading, // TODO: Enable based on actual auth implementation
                      leadingIcon: Icons.password_outlined,
                      title: 'Change Password',
                      subtitle: 'Feature coming soon',
                      trailing: Icon(Icons.chevron_right,
                          color: isOverallLoading
                              ? theme.disabledColor
                              : theme.colorScheme.onSurfaceVariant),
                      onTap: isOverallLoading
                          ? null
                          : () =>
                              context.pushNamed(RouteNames.settingsSecurity),
                    ),

                    const SectionHeader(title: 'Data Management'),
                    SettingsListTile(
                      enabled: !isDataManagementLoading &&
                          !isSettingsLoading, // Enable only when not loading anything
                      leadingIcon: Icons.backup_outlined, title: 'Backup Data',
                      subtitle: 'Save all data to a file',
                      trailing: Icon(Icons.chevron_right,
                          color: isOverallLoading
                              ? theme.disabledColor
                              : theme.colorScheme.onSurfaceVariant),
                      onTap: isOverallLoading
                          ? null
                          : () => _handleBackup(context),
                    ),
                    SettingsListTile(
                      enabled: !isDataManagementLoading && !isSettingsLoading,
                      leadingIcon: Icons.restore_page_outlined,
                      title: 'Restore Data',
                      subtitle: 'Load data from a backup file',
                      trailing: Icon(Icons.chevron_right,
                          color: isOverallLoading
                              ? theme.disabledColor
                              : theme.colorScheme.onSurfaceVariant),
                      onTap: isOverallLoading
                          ? null
                          : () => _handleRestore(context),
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
                      enabled: !isOverallLoading,
                      leadingIcon: Icons.delete_sweep_outlined,
                      title: 'Clear All Data',
                      subtitle:
                          'Permanently delete all accounts & transactions',
                      trailing: Icon(Icons.chevron_right,
                          color: isOverallLoading
                              ? theme.disabledColor
                              : theme.colorScheme.error),
                      onTap: isDataManagementLoading
                          ? null
                          : () => _handleClearData(context),
                      // Custom styling via theme or specific Text widget if needed
                      // titleTextStyle: TextStyle(color: isOverallLoading ? theme.disabledColor : theme.colorScheme.error),
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

                    const SectionHeader(title: 'Help & Feedback'),
                    SettingsListTile(
                      enabled: !isOverallLoading,
                      leadingIcon: Icons.feedback_outlined,
                      title: 'Send Feedback',
                      trailing: Icon(Icons.chevron_right,
                          color: isOverallLoading
                              ? theme.disabledColor
                              : theme.colorScheme.onSurfaceVariant),
                      onTap: isOverallLoading
                          ? null
                          : () =>
                              context.pushNamed(RouteNames.settingsFeedback),
                    ),
                    SettingsListTile(
                      enabled: !isOverallLoading,
                      leadingIcon: Icons.help_outline_rounded,
                      title: 'FAQ / Help Center',
                      trailing: Icon(Icons.open_in_new,
                          size: 18,
                          color: isOverallLoading
                              ? theme.disabledColor
                              : theme.colorScheme.secondary),
                      onTap: isOverallLoading
                          ? null
                          : () => _launchURL(context,
                              'https://example.com/help'), // Replace URL
                    ),
                    SettingsListTile(
                      enabled: !isOverallLoading,
                      leadingIcon: Icons.share_outlined,
                      title: 'Tell a Friend',
                      subtitle: 'Help spread the word!',
                      trailing: Icon(Icons.chevron_right,
                          color: isOverallLoading
                              ? theme.disabledColor
                              : theme.colorScheme.onSurfaceVariant),
                      onTap: isOverallLoading
                          ? null
                          : () {
                              log.warning(
                                  "Share functionality not implemented."); /* TODO */
                            },
                    ),

                    const SectionHeader(title: 'Legal'),
                    SettingsListTile(
                      enabled: !isOverallLoading,
                      leadingIcon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      trailing: Icon(Icons.open_in_new,
                          size: 18,
                          color: isOverallLoading
                              ? theme.disabledColor
                              : theme.colorScheme.secondary),
                      onTap: isOverallLoading
                          ? null
                          : () => _launchURL(context,
                              'https://example.com/privacy'), // Replace URL
                    ),
                    SettingsListTile(
                      enabled: !isOverallLoading,
                      leadingIcon: Icons.gavel_outlined,
                      title: 'Terms of Service',
                      trailing: Icon(Icons.open_in_new,
                          size: 18,
                          color: isOverallLoading
                              ? theme.disabledColor
                              : theme.colorScheme.secondary),
                      onTap: isOverallLoading
                          ? null
                          : () => _launchURL(context,
                              'https://example.com/terms'), // Replace URL
                    ),
                    SettingsListTile(
                      enabled: !isOverallLoading,
                      leadingIcon: Icons.article_outlined,
                      title: 'Open Source Licenses',
                      trailing: Icon(Icons.chevron_right,
                          color: isOverallLoading
                              ? theme.disabledColor
                              : theme.colorScheme.onSurfaceVariant),
                      onTap: isOverallLoading
                          ? null
                          : () => showLicensePage(context: context),
                    ),

                    const SectionHeader(title: 'About'),
                    SettingsListTile(
                      enabled: !isOverallLoading,
                      leadingIcon: Icons.info_outline_rounded,
                      title: 'About App',
                      subtitle: state.packageInfoStatus ==
                              PackageInfoStatus.loading
                          ? 'Loading...'
                          : state.packageInfoStatus == PackageInfoStatus.error
                              ? state.packageInfoError ?? 'Error'
                              : state.appVersion ?? 'N/A',
                      trailing: Icon(Icons.chevron_right,
                          color: isOverallLoading
                              ? theme.disabledColor
                              : theme.colorScheme.onSurfaceVariant),
                      onTap: isOverallLoading
                          ? null
                          : () => context.pushNamed(RouteNames.settingsAbout),
                    ),
                    // Optional Logout
                    SettingsListTile(
                      enabled:
                          !isOverallLoading, // Enable when auth is implemented
                      leadingIcon: Icons.logout_rounded,
                      title: 'Logout',
                      onTap: isOverallLoading
                          ? null
                          : () {
                              log.warning(
                                  "Logout functionality not implemented.");
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text("Logout (Not Implemented)")));
                            },
                    ),

                    const SizedBox(height: 40), // Bottom padding
                  ],
                ),

                // Loading Overlay (Displays over the list when isOverallLoading is true)
                if (isOverallLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black
                          .withOpacity(0.5), // Semi-transparent overlay
                      child: Center(
                        child: Card(
                          // Card background for the indicator
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32.0, vertical: 24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 20),
                                // Display appropriate loading message
                                Text(
                                  _isAuthenticating
                                      ? "Authenticating..."
                                      : isDataManagementLoading
                                          ? "Processing data..."
                                          : "Loading settings...",
                                  style: theme.textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                ),
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

// Helper extension
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
