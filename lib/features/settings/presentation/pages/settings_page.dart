import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/appearance_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/general_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/security_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/data_management_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/help_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/legal_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/about_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:expense_tracker/core/utils/app_dialogs.dart';

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
  void _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        log.warning("[SettingsPage] Could not launch URL: $urlString");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $urlString')),
          );
        }
      }
    } catch (e, s) {
      log.severe("[SettingsPage] Error launching URL $urlString: $e\n$s");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: ${e.toString()}')),
        );
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
            final errorMsg = state.errorMessage;
            if (state.status == SettingsStatus.error && errorMsg != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text("Settings Error: $errorMsg"),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              context.read<SettingsBloc>().add(const ClearSettingsMessage());
            }
            final pkgErrorMsg = state.packageInfoError;
            if (state.packageInfoStatus == PackageInfoStatus.error &&
                pkgErrorMsg != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text("Version Info Error: $pkgErrorMsg"),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
            }
          },
        ),
        BlocListener<DataManagementBloc, DataManagementState>(
          listener: (context, state) {
            final dataMsg = state.message;
            if ((state.status == DataManagementStatus.success ||
                    state.status == DataManagementStatus.error) &&
                dataMsg != null) {
              final isError = state.status == DataManagementStatus.error;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(dataMsg),
                    backgroundColor: isError
                        ? theme.colorScheme.error
                        : Colors.green,
                  ),
                );
              context.read<DataManagementBloc>().add(
                const ClearDataManagementMessage(),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settingsState) {
            final dataManagementState = context
                .watch<DataManagementBloc>()
                .state;
            final isSettingsLoading =
                settingsState.status == SettingsStatus.loading ||
                settingsState.packageInfoStatus == PackageInfoStatus.loading;
            final isDataManagementLoading =
                dataManagementState.status == DataManagementStatus.loading;
            final isOverallLoading =
                isDataManagementLoading || isSettingsLoading;

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
                      state: settingsState,
                      isLoading: isOverallLoading,
                    ),
                    GeneralSettingsSection(
                      state: settingsState,
                      isLoading: isOverallLoading,
                    ),
                    const SecuritySettingsSection(),
                    DataManagementSettingsSection(
                      isDataManagementLoading: isDataManagementLoading,
                      isSettingsLoading: isSettingsLoading,
                      onBackup: () async {
                        final password = await _promptForPassword(
                          context,
                          'Backup Password',
                        );
                        if (password != null && password.isNotEmpty) {
                          context.read<DataManagementBloc>().add(
                            BackupRequested(password),
                          );
                        }
                      },
                      onRestore: () async {
                        final confirmed = await AppDialogs.showConfirmation(
                          context,
                          title: "Confirm Restore",
                          content:
                              "Restoring from backup will overwrite all current data. Are you sure you want to proceed?",
                          confirmText: "Restore",
                          confirmColor: Colors.orange[700],
                        );
                        if (confirmed == true && context.mounted) {
                          final password = await _promptForPassword(
                            context,
                            'Backup Password',
                          );
                          if (password != null && password.isNotEmpty) {
                            context.read<DataManagementBloc>().add(
                              RestoreRequested(password),
                            );
                          }
                        }
                      },
                      onClearData: () async {
                        final confirmed = await AppDialogs.showStrongConfirmation(
                          context,
                          title: "Confirm Clear All Data",
                          content:
                              "This action will permanently delete ALL accounts, expenses, and income data. This cannot be undone.",
                          confirmText: "Clear Data",
                          confirmationPhrase: "DELETE",
                          confirmColor: Theme.of(context).colorScheme.error,
                        );
                        if (confirmed == true && context.mounted) {
                          context.read<DataManagementBloc>().add(
                            const ClearDataRequested(),
                          );
                        }
                      },
                    ),
                    HelpSettingsSection(
                      isLoading: isOverallLoading,
                      launchUrlCallback: _launchURL,
                    ),
                    LegalSettingsSection(
                      isLoading: isOverallLoading,
                      launchUrlCallback: _launchURL,
                    ),
                    AboutSettingsSection(
                      state: settingsState,
                      isLoading: isOverallLoading,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onError,
                        ),
                        onPressed: () {
                          context.read<AuthBloc>().add(AuthLogoutRequested());
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
                if (isOverallLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32.0,
                              vertical: 24.0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 20),
                                Text(
                                  isDataManagementLoading
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

  Future<String?> _promptForPassword(BuildContext context, String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
