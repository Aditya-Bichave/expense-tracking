import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_nav_bar.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_gap.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_text_field.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_toast.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart'; // Corrected import path

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _getFormattedPhone(String raw) {
    if (raw.isEmpty) return null;
    // Basic stripping of non-digits (except +)
    String digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');

    if (digits.isEmpty) return null;

    // Remove leading zero if it looks like a local number
    if (!digits.startsWith('+') && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    // Add default country code if missing
    if (!digits.startsWith('+')) {
      return '+91$digits'; // Defaulting to +91 as per test expectation
    }

    return digits;
  }

  void _submitPhone() {
    final phone = _phoneController.text.trim();
    final formatted = _getFormattedPhone(phone);

    if (formatted != null && formatted.length > 3) {
      context.read<AuthBloc>().add(AuthLoginRequested(formatted));
    } else {
      AppToast.show(
        context,
        'Please enter a valid phone number (e.g. 9876543210)',
        type: AppToastType.error,
      );
    }
  }

  void _submitEmail() {
    final email = _emailController.text.trim();
    if (email.isNotEmpty && email.contains('@')) {
      context.read<AuthBloc>().add(AuthLoginWithMagicLinkRequested(email));
    } else {
      AppToast.show(
        context,
        'Please enter a valid email address',
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return AppScaffold(
      appBar: const AppNavBar(title: 'Login / Sign Up'),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpSent) {
            context.push('/verify-otp', extra: state.phone);
          } else if (state is AuthError) {
            AppToast.show(context, state.message, type: AppToastType.error);
          }
        },
        child: Padding(
          padding: kit.spacing.allMd,
          child: Column(
            children: [
              AppCard(
                child: TabBar(
                  controller: _tabController,
                  labelColor: kit.colors.primary,
                  unselectedLabelColor: kit.colors.textSecondary,
                  indicatorColor: kit.colors.primary,
                  tabs: const [
                    Tab(text: 'Phone'),
                    Tab(text: 'Email'),
                  ],
                ),
              ),
              AppGap.md(context),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildPhoneTab(context), _buildEmailTab(context)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneTab(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: '1234567890',
          keyboardType: TextInputType.phone,
          textCapitalization: TextCapitalization.none,
        ),
        AppGap.md(context),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return AppButton(
              label: 'Send OTP',
              onPressed: isLoading ? null : _submitPhone,
              isLoading: isLoading,
              isFullWidth: true,
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmailTab(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          textCapitalization: TextCapitalization.none,
        ),
        AppGap.md(context),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return AppButton(
              label: 'Send Magic Link',
              onPressed: isLoading ? null : _submitEmail,
              isLoading: isLoading,
              isFullWidth: true,
            );
          },
        ),
      ],
    );
  }
}
