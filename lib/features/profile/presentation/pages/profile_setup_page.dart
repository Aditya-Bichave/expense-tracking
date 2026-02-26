import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:expense_tracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:expense_tracker/features/profile/presentation/bloc/profile_event.dart';
import 'package:expense_tracker/features/profile/presentation/bloc/profile_state.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_scaffold.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_nav_bar.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_gap.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_text_field.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_dropdown.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_toast.dart';
import 'package:expense_tracker/ui_kit/components/typography/app_text.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _nameController = TextEditingController();
  final _upiIdController = TextEditingController();
  String _currency = 'INR';
  String _timezone = 'Asia/Kolkata';
  File? _avatarFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> _currencies = [
    'INR',
    'USD',
    'EUR',
    'GBP',
    'AUD',
    'CAD',
    'JPY',
  ];

  @override
  void initState() {
    super.initState();
    _initTimezone();
    context.read<ProfileBloc>().add(const FetchProfile());
  }

  Future<void> _initTimezone() async {
    try {
      final tz = await FlutterTimezone.getLocalTimezone();
      if (mounted) setState(() => _timezone = tz.toString());
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _avatarFile = File(picked.path));
        if (mounted) {
          context.read<ProfileBloc>().add(UploadAvatar(_avatarFile!));
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          'Failed to pick image',
          type: AppToastType.error,
        );
      }
    }
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) {
      AppToast.show(context, 'Name is required', type: AppToastType.error);
      return;
    }

    final currentState = context.read<ProfileBloc>().state;
    UserProfile? currentProfile;
    if (currentState is ProfileLoaded) {
      currentProfile = currentState.profile;
    }

    if (currentProfile != null) {
      final updated = UserProfile(
        id: currentProfile.id,
        fullName: _nameController.text.trim(),
        email: currentProfile.email,
        phone: currentProfile.phone,
        avatarUrl: currentProfile.avatarUrl,
        currency: _currency,
        timezone: _timezone,
        upiId: _upiIdController.text.trim().isNotEmpty
            ? _upiIdController.text.trim()
            : null,
      );

      context.read<ProfileBloc>().add(UpdateProfile(updated));
      context.read<SessionCubit>().profileSetupCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final kit = context.kit;

    return AppScaffold(
      appBar: const AppNavBar(title: 'Setup Profile'),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            // Only update controllers if they are empty, to avoid overwriting user input during rebuilds or partial updates
            if (_nameController.text.isEmpty &&
                state.profile.fullName != null) {
              _nameController.text = state.profile.fullName!;
            }
            if (_upiIdController.text.isEmpty && state.profile.upiId != null) {
              _upiIdController.text = state.profile.upiId!;
            }
          }
          if (state is ProfileError) {
            AppToast.show(context, state.message, type: AppToastType.error);
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading && state is! ProfileLoaded) {
            return const AppLoadingIndicator();
          }

          String? avatarUrl;
          if (state is ProfileLoaded) {
            avatarUrl = state.profile.avatarUrl;
          }

          return SingleChildScrollView(
            padding: kit.spacing.allMd,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kit.colors.primaryContainer,
                      image: _avatarFile != null
                          ? DecorationImage(
                              image: FileImage(_avatarFile!),
                              fit: BoxFit.cover,
                            )
                          : (avatarUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(avatarUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null),
                    ),
                    child: (_avatarFile == null && avatarUrl == null)
                        ? Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: kit.colors.onPrimaryContainer,
                          )
                        : null,
                  ),
                ),
                AppGap.lg(context),
                AppTextField(controller: _nameController, label: 'Full Name'),
                AppGap.md(context),
                AppTextField(
                  controller: _upiIdController,
                  label: 'UPI ID (VPA)',
                  hint: 'e.g. username@okicici',
                ),
                AppGap.md(context),
                AppDropdown<String>(
                  label: 'Currency',
                  value: _currency,
                  items: _currencies.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _currency = val);
                  },
                ),
                AppGap.md(context),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const AppText('Timezone: ', style: AppTextStyle.bodyStrong),
                    AppText(_timezone, style: AppTextStyle.body),
                  ],
                ),
                AppGap.xl(context),
                AppButton(
                  label: 'Complete Setup',
                  onPressed: _submit,
                  isFullWidth: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
