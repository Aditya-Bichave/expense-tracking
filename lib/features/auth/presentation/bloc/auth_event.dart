import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String phone;

  const AuthLoginRequested(this.phone);

  @override
  List<Object?> get props => [phone];
}

class AuthVerifyOtpRequested extends AuthEvent {
  final String phone;
  final String token;

  const AuthVerifyOtpRequested(this.phone, this.token);

  @override
  List<Object?> get props => [phone, token];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckStatus extends AuthEvent {}

class AuthLoginWithMagicLinkRequested extends AuthEvent {
  final String email;

  const AuthLoginWithMagicLinkRequested(this.email);

  @override
  List<Object?> get props => [email];
}
