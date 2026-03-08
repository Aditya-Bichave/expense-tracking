import 'package:flutter/material.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:expense_tracker/features/profile/data/datasources/profile_local_data_source.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = ProfileModel(
          id: user.id,
          fullName: 'E2E Tester',
          currency: 'USD',
          timezone: 'UTC',
          email: user.email,
        );

        // Force cache it locally to instantly satisfy SessionCubit
        await sl<ProfileLocalDataSource>().cacheProfile(profile);

        // Notify SessionCubit to re-evaluate and emit SessionAuthenticated
        sl<SessionCubit>().checkSession();
      }

      if (mounted) {
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
