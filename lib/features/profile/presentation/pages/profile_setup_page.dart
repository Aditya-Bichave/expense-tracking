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
      // Handle permission error
    }
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Profile')),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            if (_nameController.text.isEmpty &&
                state.profile.fullName != null) {
              _nameController.text = state.profile.fullName!;
            }
            if (_upiIdController.text.isEmpty && state.profile.upiId != null) {
              _upiIdController.text = state.profile.upiId!;
            }
          }
          if (state is ProfileError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading && state is! ProfileLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          String? avatarUrl;
          if (state is ProfileLoaded) {
            avatarUrl = state.profile.avatarUrl;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _avatarFile != null
                        ? FileImage(_avatarFile!)
                        : (avatarUrl != null ? NetworkImage(avatarUrl) : null)
                              as ImageProvider?,
                    child: (_avatarFile == null && avatarUrl == null)
                        ? const Icon(Icons.camera_alt, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _upiIdController,
                  decoration: const InputDecoration(
                    labelText: 'UPI ID (VPA)',
                    hintText: 'e.g. username@okicici',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _currency,
                  items: _currencies.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _currency = val);
                  },
                  decoration: const InputDecoration(labelText: 'Currency'),
                ),
                const SizedBox(height: 16),
                Text('Timezone: '),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Complete Setup'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
