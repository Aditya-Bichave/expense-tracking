import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_section.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_switch.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_dialog.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_text_field.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_toast.dart';

class SecuritySettingsSection extends StatefulWidget {
  const SecuritySettingsSection({super.key});

  @override
  State<SecuritySettingsSection> createState() =>
      _SecuritySettingsSectionState();
}

class _SecuritySettingsSectionState extends State<SecuritySettingsSection> {
  bool _biometricEnabled = false;
  final SecureStorageService _storage = sl<SecureStorageService>();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final enabled = await _storage.isBiometricEnabled();
    if (mounted) setState(() => _biometricEnabled = enabled);
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final pin = await _storage.getPin();
      if (!mounted) return;
      if (pin == null) {
        final pinSet = await AppDialog.show<bool>(
          context: context,
          title: 'Set PIN',
          contentWidget: const PinSetupContent(),
        );
        if (!mounted) return;
        if (pinSet != true) return;
      }
    }
    await _storage.setBiometricEnabled(value);
    if (mounted) setState(() => _biometricEnabled = value);
  }

  Future<void> _changePin() async {
    await AppDialog.show(
      context: context,
      title: 'Change PIN',
      contentWidget: const PinSetupContent(isChange: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return AppSection(
      title: 'Security',
      child: Column(
        children: [
          AppListTile(
            leading: Icon(Icons.lock_outlined, color: kit.colors.textPrimary),
            title: Text('App Lock'),
            subtitle: Text('Require authentication to open app'),
            trailing: AppSwitch(
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
            ),
          ),
          if (_biometricEnabled)
            AppListTile(
              leading: Icon(Icons.lock_reset, color: kit.colors.textPrimary),
              title: Text('Change PIN'),
              trailing: Icon(
                Icons.chevron_right,
                color: kit.colors.textSecondary,
              ),
              onTap: _changePin,
            ),
        ],
      ),
    );
  }
}

class PinSetupContent extends StatefulWidget {
  final bool isChange;
  const PinSetupContent({super.key, this.isChange = false});

  @override
  State<PinSetupContent> createState() => _PinSetupContentState();
}

class _PinSetupContentState extends State<PinSetupContent> {
  final _pinController = TextEditingController();
  final SecureStorageService _storage = sl<SecureStorageService>();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Since AppDialog wraps content in a dialog, this widget just provides the input and logic buttons for the dialog content
    // However, AppDialog structure usually expects actions to be passed to it, or it renders standard ones.
    // But here we have custom logic inside the dialog (validation).
    // The previous implementation used a StatefulWidget dialog.
    // To adapt to AppDialog (stateless wrapper), we might need to rely on the caller or rebuild the dialog part.
    // Actually, AppDialog is a StatelessWidget that returns AlertDialog.
    // So we can't easily hook into "OK" button of AppDialog to do validation without passing a callback that checks the controller.

    // Let's reuse the controller in a way that the parent can access, or just build the UI here and include buttons here?
    // But AppDialog enforces actions.

    // Alternative: We can use showDialog directly with AppDialog but we need to intercept the confirm action.
    // But AppDialog's onConfirm is a VoidCallback.

    // Let's make PinSetupDialog a full dialog widget using AppDialog as a base or composition if possible,
    // or just implement a custom dialog using kit tokens if AppDialog is too restrictive.
    // Checking AppDialog source again... it takes contentWidget and onConfirm.

    // The issue is validation before closing.
    // So I will implement a self-contained dialog that uses AppDialog styles but manages its own state and closing.

    final kit = context.kit;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          inputFormatters:
              [], // Add length limiter if available in utils, or manual
          obscureText: true,
          hint: 'Enter 4-digit PIN',
          // autofocus: true,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: kit.typography.labelMedium.copyWith(
                  color: kit.colors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final pin = _pinController.text;
                if (pin.length == 4 && int.tryParse(pin) != null) {
                  await _storage.savePin(pin);
                  if (context.mounted) Navigator.pop(context, true);
                } else {
                  if (context.mounted) {
                    AppToast.show(
                      context,
                      'PIN must be 4 digits',
                      type: AppToastType.error,
                    );
                  }
                }
              },
              child: Text(
                'Save',
                style: kit.typography.labelMedium.copyWith(
                  color: kit.colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
