import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/auth/auth_session_service.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class CheckAuth extends AuthEvent {}

class SendOtp extends AuthEvent {
  final String phone;
  const SendOtp(this.phone);
  @override
  List<Object?> get props => [phone];
}

class VerifyOtp extends AuthEvent {
  final String phone;
  final String token;
  const VerifyOtp(this.phone, this.token);
  @override
  List<Object?> get props => [phone, token];
}

class SignOut extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class OtpSent extends AuthState {
  final String phone;
  const OtpSent(this.phone);
  @override
  List<Object?> get props => [phone];
}

class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthSessionService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<CheckAuth>(_onCheckAuth);
    on<SendOtp>(_onSendOtp);
    on<VerifyOtp>(_onVerifyOtp);
    on<SignOut>(_onSignOut);
  }

  void _onCheckAuth(CheckAuth event, Emitter<AuthState> emit) {
    final user = _authService.currentUser;
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onSendOtp(SendOtp event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.signInWithOtp(phone: event.phone);
      emit(OtpSent(event.phone));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onVerifyOtp(VerifyOtp event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.verifyOtp(phone: event.phone, token: event.token);
      final user = _authService.currentUser;
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const AuthError("Verification failed"));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignOut(SignOut event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
