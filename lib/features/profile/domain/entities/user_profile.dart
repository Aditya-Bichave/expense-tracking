import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String currency;
  final String timezone;
  final String? upiId;

  const UserProfile({
    required this.id,
    this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    required this.currency,
    required this.timezone,
    this.upiId,
  });

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    phone,
    avatarUrl,
    currency,
    timezone,
    upiId,
  ];
}
