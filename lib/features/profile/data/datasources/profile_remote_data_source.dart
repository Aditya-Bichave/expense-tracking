import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:expense_tracker/core/network/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cross_file/cross_file.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile(String userId);
  Future<void> updateProfile(ProfileModel profile);
  Future<String> uploadAvatar(String userId, XFile file);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final SupabaseClient _client;

  ProfileRemoteDataSourceImpl(this._client);

  @override
  Future<ProfileModel> getProfile(String userId) async {
    final response = await _client
        .from(SupabaseConfig.profilesTable)
        .select()
        .eq('id', userId)
        .single();
    return ProfileModel.fromJson(response);
  }

  @override
  Future<void> updateProfile(ProfileModel profile) async {
    await _client
        .from(SupabaseConfig.profilesTable)
        .update({
          'full_name': profile.fullName,
          'email': profile.email,
          'phone': profile.phone,
          'avatar_url': profile.avatarUrl,
          'currency': profile.currency,
          'timezone': profile.timezone,
          'upi_id': profile.upiId,
        })
        .eq('id', profile.id);
  }

  @override
  Future<String> uploadAvatar(String userId, XFile file) async {
    final parts = file.name.split('.');
    final ext = (parts.length > 1) ? parts.last : 'jpg';
    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final fileName = '$userId/$timestamp.$ext';

    final bytes = await file.readAsBytes();

    await _client.storage
        .from(SupabaseConfig.profileAvatarsBucket)
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return _client.storage
        .from(SupabaseConfig.profileAvatarsBucket)
        .getPublicUrl(fileName);
  }
}
