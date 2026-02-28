import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
// Removing part-of imports and importing bloc/state directly if exported or check proper imports
// If they are part files, they should be imported via the main library file usually.
// Let's assume settings_bloc.dart or data_management_bloc.dart exports them.
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
// import 'package:expense_tracker/features/settings/presentation/bloc/settings_event.dart'; // Likely part of settings_bloc
// import 'package:expense_tracker/features/settings/presentation/bloc/settings_state.dart'; // Likely part of settings_bloc

// If data_management_bloc.dart is the main file, import that.
import 'package:expense_tracker/features/settings/presentation/widgets/about_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/appearance_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/data_management_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/general_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/help_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/legal_settings_section.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/security_settings_section.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart'; // Import for modeTheme extension
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_gap.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_toast.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_dialog.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/components/typography/app_text.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_text_field.dart';
import 'package:expense_tracker/ui_kit/foundation/ui_enums.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(const LoadSettings());
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (context.mounted) {
        AppToast.show(context, 'Could not launch ', type: AppToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;
    final modeTheme = context.modeTheme; // Valid now with import

    return MultiBlocListener(
      listeners: [
        BlocListener<SettingsBloc, SettingsState>(
          listener: (context, state) {
            final errorMsg = state.errorMessage;
            if (state.status == SettingsStatus.error && errorMsg != null) {
              AppToast.show(
                context,
                "Settings Error: ",
                type: AppToastType.error,
              );
              context.read<SettingsBloc>().add(const ClearSettingsMessage());
            }
            final pkgErrorMsg = state.packageInfoError;
            if (state.packageInfoStatus == PackageInfoStatus.error &&
                pkgErrorMsg != null) {
              AppToast.show(
                context,
                "Version Info Error: ",
                type: AppToastType.error,
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
              AppToast.show(
                context,
                dataMsg,
                type: isError ? AppToastType.error : AppToastType.success,
              );
              context.read<DataManagementBloc>().add(
                const ClearDataManagementMessage(),
              );
            }
          },
        ),
      ],
      child: AppScaffold(
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
              return const AppLoadingIndicator();
            }

            return Stack(
              children: [
                ListView(
                  padding:
                      modeTheme?.pagePadding.copyWith(top: 8, bottom: 80) ??
                      kit.spacing.allMd.copyWith(bottom: 80),
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
                        AppDialog.show(
                          context: context,
                          title: "Confirm Restore",
                          content:
                              "Restoring from backup will overwrite all current data. Are you sure you want to proceed?",
                          confirmLabel: "Restore",
                          onConfirm: () async {
                            Navigator.of(context).pop(); // Close confirm dialog
                            final password = await _promptForPassword(
                              context,
                              'Backup Password',
                            );
                            if (password != null && password.isNotEmpty) {
                              if (context.mounted) {
                                context.read<DataManagementBloc>().add(
                                  RestoreRequested(password),
                                );
                              }
                            }
                          },
                          cancelLabel: "Cancel",
                          isDestructive: false,
                        );
                      },
                      onClearData: () async {
                        AppDialog.show(
                          context: context,
                          title: "Confirm Clear All Data",
                          content:
                              "This action will permanently delete ALL accounts, expenses, and income data. This cannot be undone.",
                          confirmLabel: "Clear Data",
                          onConfirm: () {
                            Navigator.of(context).pop();
                            context.read<DataManagementBloc>().add(
                              const ClearDataRequested(),
                            );
                          },
                          cancelLabel: "Cancel",
                          isDestructive: true,
                        );
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
                      padding: kit.spacing.vMd,
                      child: AppButton(
                        label: 'Logout',
                        icon: const Icon(Icons.logout),
                        variant: UiVariant.destructive,
                        onPressed: () {
                          context.read<AuthBloc>().add(AuthLogoutRequested());
                        },
                      ),
                    ),
                    AppGap.xl(context),
                  ],
                ),
                if (isOverallLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: AppCard(
                          padding: kit.spacing.allLg,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppLoadingIndicator(),
                              AppGap.md(context),
                              AppText(
                                isDataManagementLoading
                                    ? "Processing data..."
                                    : "Loading settings...",
                                style: AppTextStyle.bodyStrong,
                                textAlign: TextAlign.center,
                              ),
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

  Future<String?> _promptForPassword(BuildContext context, String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AppDialog(
        title: title,
        contentWidget: AppTextField(
          controller: controller,
          obscureText: true,
          label: 'Password',
        ),
        confirmLabel: 'OK',
        onConfirm: () => Navigator.of(ctx).pop(controller.text),
        cancelLabel: 'Cancel',
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }
}
