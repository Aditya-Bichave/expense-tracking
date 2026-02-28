import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';

import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_gap.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_safe_area.dart';
import 'package:expense_tracker/ui_kit/components/typography/app_text.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_icon_button.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_dialog.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_toast.dart';
import 'package:expense_tracker/ui_kit/foundation/ui_enums.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_button.dart';
import 'package:expense_tracker/ui_bridge/bridge_decoration.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final SecureStorageService storage = sl<SecureStorageService>();
  String enteredPin = '';
  String? savedPin;
  bool _canCheckBiometrics = false;
  bool _pinLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _loadPin().then((_) => _authenticate());
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await auth.canCheckBiometrics;
      if (mounted) setState(() => _canCheckBiometrics = canCheck);
    } catch (_) {}
  }

  Future<void> _loadPin() async {
    savedPin = await storage.getPin();
    if (mounted) setState(() => _pinLoaded = true);
  }

  Future<void> _authenticate() async {
    if (!mounted) return;
    try {
      final authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to unlock',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (authenticated && mounted) {
        context.read<SessionCubit>().unlock();
      }
    } catch (e) {
      // Fallback
    }
  }

  void _onPinDigit(String digit) {
    if (!_pinLoaded) return;
    HapticFeedback.selectionClick();
    if (enteredPin.length < 4) {
      setState(() {
        enteredPin += digit;
      });
      if (enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDeleteDigit() {
    HapticFeedback.selectionClick();
    if (enteredPin.isNotEmpty) {
      setState(() {
        enteredPin = enteredPin.substring(0, enteredPin.length - 1);
      });
    }
  }

  void _verifyPin() {
    if (savedPin == null) {
      log.severe('PIN verification attempted but saved PIN is null.');
      setState(() => enteredPin = '');

      AppDialog.show(
        context: context,
        title: 'Security Configuration Error',
        content:
            'Your security PIN is missing or corrupted. You need to log out and set it up again.',
        confirmLabel: 'Logout & Reset',
        onConfirm: () {
          Navigator.of(context).pop();
          context.read<AuthBloc>().add(AuthLogoutRequested());
        },
        isDestructive: true,
      );
      return;
    }

    if (enteredPin == savedPin) {
      context.read<SessionCubit>().unlock();
    } else {
      setState(() {
        enteredPin = '';
      });
      AppToast.show(context, 'Incorrect PIN', type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return AppScaffold(
      body: AppSafeArea(
        child: Column(
          children: [
            const Spacer(),
            Icon(Icons.lock, size: 64, color: kit.colors.primary),
            AppGap.md(context),
            const AppText('App Locked', style: AppTextStyle.headline),
            AppGap.lg(context),
            Semantics(
              label: '${enteredPin.length} of 4 digits entered',
              excludeSemantics: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const BridgeEdgeInsets.symmetric(horizontal: 8),
                    width: 20,
                    height: 20,
                    decoration: BridgeDecoration(
                      shape: BoxShape.circle,
                      color: index < enteredPin.length
                          ? kit.colors.primary
                          : kit.colors.surfaceContainer,
                      border: Border.all(color: kit.colors.borderSubtle),
                    ),
                  );
                }),
              ),
            ),
            const Spacer(),
            if (_canCheckBiometrics) ...[
              AppButton(
                onPressed: _authenticate,
                label: 'Use Biometrics',
                icon: const Icon(Icons.fingerprint),
                variant: UiVariant.secondary,
              ),
              AppGap.md(context),
            ],
            _buildKeypad(kit),
            AppGap.md(context),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(dynamic kit) {
    return Column(
      children: [
        _buildRow(kit, ['1', '2', '3']),
        _buildRow(kit, ['4', '5', '6']),
        _buildRow(kit, ['7', '8', '9']),
        _buildRow(kit, [null, '0', 'back']),
      ],
    );
  }

  Widget _buildRow(dynamic kit, List<dynamic> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((item) {
        if (item == null) {
          return const SizedBox(width: 80, height: 80);
        }
        if (item == 'back') {
          return SizedBox(
            width: 80,
            height: 80,
            child: Semantics(
              label: 'Delete digit',
              child: AppIconButton(
                onPressed: _onDeleteDigit,
                icon: const Icon(Icons.backspace_outlined),
                // variant and size removed as per AppIconButton definition
              ),
            ),
          );
        }
        return Container(
          width: 80,
          height: 80,
          margin: const BridgeEdgeInsets.all(8),
          child: BridgeTextButton(
            style: TextButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: kit.colors.surfaceContainer,
              foregroundColor: kit.colors.textPrimary,
            ),
            onPressed: () => _onPinDigit(item),
            child: Text(item, style: kit.typography.headline),
          ),
        );
      }).toList(),
    );
  }
}
