import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:expense_tracker/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:expense_tracker/features/profile/domain/usecases/upload_avatar_usecase.dart';
import 'package:expense_tracker/features/profile/presentation/bloc/profile_event.dart';
import 'package:expense_tracker/features/profile/presentation/bloc/profile_state.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final UploadAvatarUseCase _uploadAvatarUseCase;

  ProfileBloc(
    this._getProfileUseCase,
    this._updateProfileUseCase,
    this._uploadAvatarUseCase,
  ) : super(ProfileInitial()) {
    on<FetchProfile>(_onFetchProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<UploadAvatar>(_onUploadAvatar);
  }

  Future<void> _onFetchProfile(
    FetchProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await _getProfileUseCase(forceRefresh: event.forceRefresh);
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (profile) => emit(ProfileLoaded(profile)),
    );
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await _updateProfileUseCase(event.profile);
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (_) => emit(ProfileLoaded(event.profile)),
    );
  }

  Future<void> _onUploadAvatar(
    UploadAvatar event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) {
      return;
    }

    emit(ProfileLoading());
    final result = await _uploadAvatarUseCase(event.file);
    await result.fold(
      (failure) async => emit(ProfileError(failure.message)),
      (url) async {
        final newProfile = UserProfile(
          id: currentState.profile.id,
          fullName: currentState.profile.fullName,
          email: currentState.profile.email,
          phone: currentState.profile.phone,
          avatarUrl: url,
          currency: currentState.profile.currency,
          timezone: currentState.profile.timezone,
        );

        final updateResult = await _updateProfileUseCase(newProfile);
        updateResult.fold(
          (l) => emit(ProfileError(l.message)),
          (_) => emit(ProfileLoaded(newProfile)),
        );
      },
    );
  }
}
