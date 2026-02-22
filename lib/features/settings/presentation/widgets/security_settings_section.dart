import 'package:flutter/material.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/widgets/settings_list_tile.dart';

class SecuritySettingsSection extends StatefulWidget {
  const SecuritySettingsSection({super.key});

  @override
  State<SecuritySettingsSection> createState() => _SecuritySettingsSectionState();
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
            final pinSet = await showDialog<bool>(
                context: context,
                builder: (context) => const PinSetupDialog(),
            );
            if (!mounted) return;
            if (pinSet != true) return;
        }
    }
    await _storage.setBiometricEnabled(value);
    if (mounted) setState(() => _biometricEnabled = value);
  }

  Future<void> _changePin() async {
      await showDialog(
          context: context,
          builder: (context) => const PinSetupDialog(isChange: true),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('App Lock'),
          subtitle: const Text('Require authentication to open app'),
          value: _biometricEnabled,
          onChanged: _toggleBiometric,
        ),
        if (_biometricEnabled)
            ListTile(
                title: const Text('Change PIN'),
                leading: const Icon(Icons.lock_outline),
                onTap: _changePin,
            ),
      ],
    );
  }
}

class PinSetupDialog extends StatefulWidget {
  final bool isChange;
  const PinSetupDialog({super.key, this.isChange = false});

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  final _pinController = TextEditingController();
  final SecureStorageService _storage = sl<SecureStorageService>();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isChange ? 'Change PIN' : 'Set PIN'),
      content: TextField(
        controller: _pinController,
        keyboardType: TextInputType.number,
        maxLength: 4,
        obscureText: true,
        decoration: const InputDecoration(hintText: 'Enter 4-digit PIN'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final pin = _pinController.text;
            if (pin.length == 4 && int.tryParse(pin) != null) {
              await _storage.savePin(pin);
              if (mounted) Navigator.pop(context, true);
            } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN must be 4 digits')));
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
