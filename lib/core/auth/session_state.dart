import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SessionState extends Equatable {
  const SessionState();
  @override
  List<Object?> get props => [];
}

class SessionUnauthenticated extends SessionState {}

class SessionAuthenticating extends SessionState {}

class SessionAuthenticated extends SessionState {
  final UserProfile profile;
  const SessionAuthenticated(this.profile);
  @override
  List<Object?> get props => [profile];
}

class SessionNeedsProfileSetup extends SessionState {
  final User user;
  const SessionNeedsProfileSetup(this.user);
  @override
  List<Object?> get props => [user];
}

class SessionLocked extends SessionState {}
