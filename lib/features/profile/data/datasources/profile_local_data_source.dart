import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:hive_ce/hive.dart';

abstract class ProfileLocalDataSource {
  Future<void> cacheProfile(ProfileModel profile);
  Future<ProfileModel?> getLastProfile();
  Future<void> clearProfile();
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  final Box<ProfileModel> _box;
  static const String _profileKey = 'current_profile';

  ProfileLocalDataSourceImpl(this._box);

  @override
  Future<void> cacheProfile(ProfileModel profile) async {
    await _box.put(_profileKey, profile);
  }

  @override
  Future<ProfileModel?> getLastProfile() async {
    return _box.get(_profileKey);
  }

  @override
  Future<void> clearProfile() async {
    await _box.delete(_profileKey);
  }
}
