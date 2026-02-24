import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/utils/logger.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Security Error: PIN configuration missing.'),
        ),
      );
      // Optionally logout or similar
      return;
    }

    if (enteredPin == savedPin) {
      context.read<SessionCubit>().unlock();
    } else {
      setState(() {
        enteredPin = '';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Incorrect PIN')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.lock, size: 64),
            const SizedBox(height: 24),
            const Text(
              'App Locked',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Semantics(
              label: '${enteredPin.length} of 4 digits entered',
              excludeSemantics: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < enteredPin.length
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
            ),
            const Spacer(),
            if (_canCheckBiometrics)
              TextButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.fingerprint, size: 32),
                label: const Text('Use Biometrics'),
              ),
            const SizedBox(height: 24),
            _buildKeypad(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        _buildRow(['4', '5', '6']),
        _buildRow(['7', '8', '9']),
        _buildRow([null, '0', 'back']),
      ],
    );
  }

  Widget _buildRow(List<dynamic> items) {
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
              child: IconButton(
                onPressed: _onDeleteDigit,
                icon: const Icon(Icons.backspace_outlined),
              ),
            ),
          );
        }
        return Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.all(8),
          child: TextButton(
            style: TextButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: Colors.grey.shade200,
            ),
            onPressed: () => _onPinDigit(item),
            child: Text(
              item,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }
}
