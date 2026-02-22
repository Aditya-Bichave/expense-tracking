import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'dart:io';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class FetchProfile extends ProfileEvent {
  final bool forceRefresh;
  const FetchProfile({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

class UpdateProfile extends ProfileEvent {
  final UserProfile profile;
  const UpdateProfile(this.profile);
  @override
  List<Object?> get props => [profile];
}

class UploadAvatar extends ProfileEvent {
  final File file;
  const UploadAvatar(this.file);
  @override
  List<Object?> get props => [file];
}
