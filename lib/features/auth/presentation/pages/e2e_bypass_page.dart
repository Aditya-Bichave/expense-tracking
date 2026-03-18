import 'package:flutter/material.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/core/utils/e2e_bootstrap.dart';
import 'package:go_router/go_router.dart';

class E2EBypassPage extends StatefulWidget {
  const E2EBypassPage({super.key});

  @override
  State<E2EBypassPage> createState() => _E2EBypassPageState();
}

class _E2EBypassPageState extends State<E2EBypassPage> {
  @override
  void initState() {
    super.initState();
    _bypassProfile();
  }

  Future<void> _bypassProfile() async {
    try {
      await E2EBootstrap.seedLocalState();
      await sl<SessionCubit>().checkSession();

      if (context.mounted) {
        // Safe redirect to dashboard
        context.go('/dashboard');
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('E2E Bypass Hook Running...')),
    );
  }
}
