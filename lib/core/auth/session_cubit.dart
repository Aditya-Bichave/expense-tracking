import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/core/auth/session_state.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/profile/domain/repositories/profile_repository.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionCubit extends Cubit<SessionState> {
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  final SecureStorageService _secureStorageService;
  StreamSubscription? _authSubscription;

  SessionCubit(
    this._authRepository,
    this._profileRepository,
    this._secureStorageService,
  ) : super(SessionUnauthenticated()) {
    _init();
  }

  Future<void> _init() async {
    _authSubscription = _authRepository.authStateChanges.listen((authState) {
      if (authState.event == AuthChangeEvent.signedOut) {
        emit(SessionUnauthenticated());
      } else if (authState.event == AuthChangeEvent.signedIn ||
          authState.event == AuthChangeEvent.initialSession) {
        checkSession();
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> checkSession() async {
    final userResult = _authRepository.getCurrentUser();
    await userResult.fold((failure) async => emit(SessionUnauthenticated()), (
      user,
    ) async {
      if (user == null) {
        emit(SessionUnauthenticated());
        return;
      }

      final isLockEnabled = await _secureStorageService.isBiometricEnabled();
      if (state is SessionLocked) return;

      if (isLockEnabled) {
        emit(SessionLocked());
        return;
      }

      await _loadProfile(user);
    });
  }

  Future<void> _loadProfile(User user) async {
    final localResult = await _profileRepository.getProfile(
      forceRefresh: false,
    );

    localResult.fold(
      (failure) async {
        await _fetchRemoteProfile(user);
      },
      (profile) {
        _validateAndEmit(user, profile);
        _fetchRemoteProfile(user, background: true);
      },
    );
  }

  Future<void> _fetchRemoteProfile(User user, {bool background = false}) async {
    if (isClosed) return;
    final remoteResult = await _profileRepository.getProfile(
      forceRefresh: true,
    );
    if (isClosed) return;

    remoteResult.fold(
      (failure) {
        if (!background && !isClosed) emit(SessionNeedsProfileSetup(user));
      },
      (profile) {
        if (!isClosed) _validateAndEmit(user, profile);
      },
    );
  }

  void _validateAndEmit(User user, UserProfile profile) {
    if (profile.fullName == null || profile.fullName!.isEmpty) {
      emit(SessionNeedsProfileSetup(user));
    } else {
      emit(SessionAuthenticated(profile));
    }
  }

  Future<void> unlock() async {
    final userResult = _authRepository.getCurrentUser();
    await userResult.fold((l) async => emit(SessionUnauthenticated()), (
      user,
    ) async {
      if (user != null) {
        await _loadProfile(user);
      } else {
        emit(SessionUnauthenticated());
      }
    });
  }

  void lock() {
    emit(SessionLocked());
  }

  void profileSetupCompleted() {
    checkSession();
  }
}
