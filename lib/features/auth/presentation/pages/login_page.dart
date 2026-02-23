import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:country_code_picker/country_code_picker.dart';

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
  String _countryCode = '+91';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpSent) {
            context.push('/verify-otp', extra: state.phone);
          } else if (state is AuthMagicLinkSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Magic link sent to ${state.email}')),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Phone'),
                  Tab(text: 'Email'),
                ],
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildPhoneForm(), _buildEmailForm()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            CountryCodePicker(
              onChanged: (code) {
                if (code.dialCode != null) {
                  setState(() => _countryCode = code.dialCode!);
                }
              },
              initialSelection: 'IN',
              favorite: const ['+91', 'US'],
              showCountryOnly: false,
              showOnlyCountryWhenClosed: false,
              alignLeft: false,
            ),
            Expanded(
              child: TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '1234567890',
                ),
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  final phone = _phoneController.text.trim();
                  if (phone.isNotEmpty) {
                    context.read<AuthBloc>().add(
                      AuthLoginRequested('$_countryCode$phone'),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      final phone = _phoneController.text.trim();
                      if (phone.isNotEmpty) {
                        context.read<AuthBloc>().add(
                          AuthLoginRequested('$_countryCode$phone'),
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send OTP'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'you@example.com',
          ),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            final email = _emailController.text.trim();
            if (email.isNotEmpty) {
              context.read<AuthBloc>().add(
                AuthLoginWithMagicLinkRequested(email),
              );
            }
          },
        ),
        const SizedBox(height: 16),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            return ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      final email = _emailController.text.trim();
                      if (email.isNotEmpty) {
                        context.read<AuthBloc>().add(
                          AuthLoginWithMagicLinkRequested(email),
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Magic Link'),
            );
          },
        ),
      ],
    );
  }
}
