import 'package:flutter/material.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class E2ELoginPage extends StatefulWidget {
  const E2ELoginPage({super.key});

  @override
  State<E2ELoginPage> createState() => _E2ELoginPageState();
}

class _E2ELoginPageState extends State<E2ELoginPage> {
  Future<void> _loginAndSetup() async {
    final supabase = Supabase.instance.client;
    // We assume global-setup.js already signed in or this gets called after.
    // If not, we can trigger sign in here. But the auth state is usually saved by Playwright.
    final user = supabase.auth.currentUser;
    if (user != null) {
      await supabase.from('profiles').upsert({
        'id': user.id,
        'full_name': 'E2E Tester',
        'currency': 'USD',
        'timezone': 'UTC',
      });
      // Force refresh the session cubit
      sl<SessionCubit>().checkSession(background: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('e2e-login-btn'),
          onPressed: _loginAndSetup,
          child: const Text('E2E Setup Profile'),
        ),
      ),
    );
  }
}
