import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_nav_bar.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_gap.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_text_field.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_toast.dart';
import 'package:expense_tracker/ui_kit/components/typography/app_text.dart';

class VerifyOtpPage extends StatefulWidget {
  final String phone;

  const VerifyOtpPage({super.key, required this.phone});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _tokenController = TextEditingController();

  void _verify() {
    final token = _tokenController.text.trim();
    if (token.isNotEmpty) {
      context.read<AuthBloc>().add(AuthVerifyOtpRequested(widget.phone, token));
    } else {
      AppToast.show(context, 'Please enter the OTP', type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return AppScaffold(
      appBar: const AppNavBar(title: 'Verify OTP'),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/'); // Navigate to home
          } else if (state is AuthError) {
            AppToast.show(context, state.message, type: AppToastType.error);
          }
        },
        child: Padding(
          padding: kit.spacing.allMd,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText(
                'Enter OTP sent to ${widget.phone}',
                style: AppTextStyle.bodyStrong,
                textAlign: TextAlign.center,
              ),
              AppGap.lg(context),
              AppTextField(
                controller: _tokenController,
                label: 'OTP',
                keyboardType: TextInputType.number,
                textCapitalization: TextCapitalization.none,
              ),
              AppGap.md(context),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return AppButton(
                    label: 'Verify',
                    onPressed: isLoading ? null : _verify,
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
