import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/auth/domain/usecases/login_with_otp_usecase.dart';
import 'package:expense_tracker/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:expense_tracker/features/auth/domain/usecases/logout_usecase.dart';
import 'package:expense_tracker/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginWithOtpUseCase _loginWithOtpUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  AuthBloc(
    this._loginWithOtpUseCase,
    this._verifyOtpUseCase,
    this._logoutUseCase,
    this._getCurrentUserUseCase,
  ) : super(AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthVerifyOtpRequested>(_onVerifyOtpRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  void _onCheckStatus(AuthCheckStatus event, Emitter<AuthState> emit) {
    final result = _getCurrentUserUseCase();
    result.fold((failure) => emit(AuthUnauthenticated()), (user) {
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _loginWithOtpUseCase(event.phone);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthOtpSent(event.phone)),
    );
  }

  Future<void> _onVerifyOtpRequested(
    AuthVerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _verifyOtpUseCase(
      phone: event.phone,
      token: event.token,
    );
    result.fold((failure) => emit(AuthError(failure.message)), (response) {
      if (response.user != null) {
        emit(AuthAuthenticated(response.user!));
      } else {
        emit(const AuthError("Login failed: No user returned"));
      }
    });
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _logoutUseCase();
    emit(AuthUnauthenticated());
  }
}
