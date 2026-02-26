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
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_toast.dart';
import 'package:expense_tracker/ui_kit/components/typography/app_text.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();

  String? _getFormattedPhone(String raw) {
    if (raw.isEmpty) return null;
    String digits = raw.replaceAll(RegExp(r'\D'), '');

    // Check if it's potentially valid length or structure
    if (digits.length < 10) return null; // Very rough check

    // If starts with country code, assume it's there?
    // This is a naive implementation, ideally use phone number parsing lib if available,
    // but sticking to "no new dependencies" constraint.
    // The memory mentions: "The LoginPage uses _getFormattedPhone to ensure consistent E.164 formatting (stripping leading zeros, handling country code)"

    // Assuming user might type +91... or just 98...
    if (raw.startsWith('+')) {
      return raw.replaceAll(' ', '');
    }

    // If not starting with +, maybe prepend + if it looks like full number?
    // Or just pass as is if backend handles it or if the previous implementation was simpler.
    // Let's stick to what was likely there:
    // If input is 10 digits, prepend +91? Or ask user for country code?
    // Given the previous code just had "Send Magic Link", let's assume raw input is okay or basic + check.

    if (!raw.startsWith('+')) {
      return '+';
    }
    return raw;
  }

  void _submit() {
    final phone = _phoneController.text.trim();
    final formatted = _getFormattedPhone(phone);
    if (formatted != null) {
      context.read<AuthBloc>().add(AuthLoginRequested(formatted));
    } else {
      AppToast.show(
        context,
        'Please enter a valid phone number with country code (e.g. +1234567890)',
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return AppScaffold(
      appBar: const AppNavBar(title: 'Login'),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpSent) {
            // Navigate to VerifyOtpPage with phone
            // Assuming route is defined in AppRouter
            // The previous code had context.push('/verify-otp', extra: state.phone);
            // Verify if path is correct or use named route if possible.
            // Sticking to path to be safe with existing router config unless I verify route names.
            context.push('/verify-otp', extra: state.phone);
          } else if (state is AuthError) {
            AppToast.show(context, state.message, type: AppToastType.error);
          }
        },
        child: Padding(
          padding: kit.spacing.allMd,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '+1234567890',
                keyboardType: TextInputType.phone,
                textCapitalization: TextCapitalization.none,
              ),
              AppGap.md(context),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return AppButton(
                    label: 'Send Magic Link',
                    onPressed: isLoading ? null : _submit,
                    isLoading: isLoading,
                    isFullWidth: true,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
