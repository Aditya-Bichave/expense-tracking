// ignore_for_file: overridden_fields
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'profile_model.g.dart';

@HiveType(typeId: 20)
@JsonSerializable(fieldRename: FieldRename.snake)
class ProfileModel extends UserProfile {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String? fullName;
  @override
  @HiveField(2)
  final String? email;
  @override
  @HiveField(3)
  final String? phone;
  @override
  @HiveField(4)
  final String? avatarUrl;
  @override
  @HiveField(5)
  final String currency;
  @override
  @HiveField(6)
  final String timezone;

  const ProfileModel({
    required this.id,
    this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    required this.currency,
    required this.timezone,
  }) : super(
         id: id,
         fullName: fullName,
         email: email,
         phone: phone,
         avatarUrl: avatarUrl,
         currency: currency,
         timezone: timezone,
       );

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileModelToJson(this);

  factory ProfileModel.fromEntity(UserProfile user) {
    return ProfileModel(
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
      currency: user.currency,
      timezone: user.timezone,
    );
  }
}
