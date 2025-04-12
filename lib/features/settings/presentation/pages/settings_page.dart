// lib/features/settings/presentation/pages/settings_page.dart
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
// Import decomposed widgets
import 'package:expense_tracker/features/settings/presentation/widgets/appearance_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/general_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/security_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/data_management_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/help_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/legal_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/about_settings_section.dart';
// Import Data Management Bloc
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
// Other imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:expense_tracker/main.dart';
import 'package:url_launcher/url_launcher.dart';
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

  // --- App Lock Handler (Remains in View State) ---
  Future<void> _handleAppLockToggle(BuildContext context, bool enable) async {
    final settingsState = context.read<SettingsBloc>().state;
    if (settingsState.isInDemoMode) {
      log.warning("[SettingsPage] App Lock toggle blocked in Demo Mode.");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("App Lock cannot be changed in Demo Mode.")));
      return;
    }

    log.info("[SettingsPage] App Lock toggle requested. Enable: $enable");
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    try {
      bool canAuth = false;
      if (enable) {
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
          setState(() => _isAuthenticating = false);
          return;
        }
      }
      if (mounted) {
        log.info(
            "[SettingsPage] Dispatching UpdateAppLock event. IsEnabled: $enable");
        context.read<SettingsBloc>().add(UpdateAppLock(enable));
      }
    } on PlatformException catch (e, s) {
      log.severe(
          "[SettingsPage] PlatformException checking/setting App Lock: $e\n$s");
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text("Error setting App Lock: ${e.message ?? e.code}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
        setState(() => _isAuthenticating = false);
      }
    } catch (e, s) {
      log.severe(
          "[SettingsPage] Unexpected error checking/setting App Lock: $e\n$s");
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content:
                const Text("An unexpected error occurred setting App Lock."),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
        setState(() => _isAuthenticating = false);
      }
    } finally {
      if (mounted && _isAuthenticating) {
        // Re-check BLoC state before setting authenticating back to false
        final finalSettingsState = context.read<SettingsBloc>().state;
        if (finalSettingsState.status != SettingsStatus.loading) {
          // Ensure loading is finished before resetting flag
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isAuthenticating = false);
          });
        }
      }
    }
  }

  // --- URL Launcher (Remains in View State) ---
  void _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        log.warning(
            "[SettingsPage] Could not launch URL (launchUrl returned false): $urlString");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open link: $urlString')));
        }
      }
    } catch (e, s) {
      log.severe("[SettingsPage] Error launching URL $urlString: $e\n$s");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening link: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modeTheme = context.modeTheme;

    return MultiBlocListener(
      listeners: [
        BlocListener<SettingsBloc, SettingsState>(
          listener: (context, state) {
            // Handle main settings errors
            final errorMsg = state.errorMessage;
            if (state.status == SettingsStatus.error && errorMsg != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                    content: Text("Settings Error: $errorMsg"),
                    backgroundColor: theme.colorScheme.error));
              context.read<SettingsBloc>().add(const ClearSettingsMessage());
            }
            // Handle package info errors
            final pkgErrorMsg = state.packageInfoError;
            if (state.packageInfoStatus == PackageInfoStatus.error &&
                pkgErrorMsg != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                    content: Text("Version Info Error: $pkgErrorMsg"),
                    backgroundColor: theme.colorScheme.error));
              // Optionally clear the error message if needed
              // context.read<SettingsBloc>().add(const ClearPackageInfoErrorMessage());
            }
          },
        ),
        BlocListener<DataManagementBloc, DataManagementState>(
          listener: (context, state) {
            // Handle Data Management success/error messages
            final dataMsg = state.message;
            if ((state.status == DataManagementStatus.success ||
                    state.status == DataManagementStatus.error) &&
                dataMsg != null) {
              final isError = state.status == DataManagementStatus.error;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                    content: Text(dataMsg),
                    backgroundColor:
                        isError ? theme.colorScheme.error : Colors.green));
              context
                  .read<DataManagementBloc>()
                  .add(const ClearDataManagementMessage());
            }
          },
        ),
      ],
      child: Scaffold(
        // --- AppBar is now provided by MainShell ---
        // appBar: AppBar(title: const Text('Settings')),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settingsState) {
            final dataManagementState =
                context.watch<DataManagementBloc>().state;

            final isSettingsLoading = settingsState.status ==
                    SettingsStatus.loading ||
                settingsState.packageInfoStatus == PackageInfoStatus.loading;
            final isDataManagementLoading =
                dataManagementState.status == DataManagementStatus.loading;
            final isOverallLoading = isDataManagementLoading ||
                _isAuthenticating ||
                isSettingsLoading;

            if (settingsState.status == SettingsStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            return Stack(
              children: [
                ListView(
                  padding:
                      modeTheme?.pagePadding.copyWith(top: 8, bottom: 80) ??
                          const EdgeInsets.only(top: 8.0, bottom: 80.0),
                  children: [
                    AppearanceSettingsSection(
                        state: settingsState, isLoading: isOverallLoading),
                    GeneralSettingsSection(
                        state: settingsState, isLoading: isOverallLoading),
                    SecuritySettingsSection(
                        state: settingsState,
                        isLoading: isOverallLoading,
                        onAppLockToggle: _handleAppLockToggle),
                    DataManagementSettingsSection(
                      isDataManagementLoading: isDataManagementLoading,
                      isSettingsLoading: isSettingsLoading,
                      onBackup: () {
                        log.info(
                            "[SettingsPage] Backup requested via section.");
                        context
                            .read<DataManagementBloc>()
                            .add(const BackupRequested());
                      },
                      onRestore: () async {
                        log.info(
                            "[SettingsPage] Restore requested via section.");
                        final confirmed = await AppDialogs.showConfirmation(
                          context,
                          title: "Confirm Restore",
                          content:
                              "Restoring from backup will overwrite all current data. Are you sure you want to proceed?",
                          confirmText: "Restore",
                          confirmColor: Colors.orange[700],
                        );
                        if (confirmed == true && context.mounted) {
                          context
                              .read<DataManagementBloc>()
                              .add(const RestoreRequested());
                        }
                      },
                      onClearData: () async {
                        log.info(
                            "[SettingsPage] Clear data requested via section.");
                        final confirmed =
                            await AppDialogs.showStrongConfirmation(
                          context,
                          title: "Confirm Clear All Data",
                          content:
                              "This action will permanently delete ALL accounts, expenses, and income data. This cannot be undone.",
                          confirmText: "Clear Data",
                          confirmationPhrase: "DELETE",
                          confirmColor: Theme.of(context).colorScheme.error,
                        );
                        if (confirmed == true && context.mounted) {
                          context
                              .read<DataManagementBloc>()
                              .add(const ClearDataRequested());
                        }
                      },
                    ),
                    HelpSettingsSection(
                        isLoading: isOverallLoading,
                        launchUrlCallback: _launchURL),
                    LegalSettingsSection(
                        isLoading: isOverallLoading,
                        launchUrlCallback: _launchURL),
                    AboutSettingsSection(
                        state: settingsState, isLoading: isOverallLoading),
                    const SizedBox(height: 40),
                  ],
                ),

                // Loading Overlay
                if (isOverallLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: Card(
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
