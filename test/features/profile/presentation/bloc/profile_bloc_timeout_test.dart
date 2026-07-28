import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/profile/domain/usecases/upload_avatar_usecase.dart';
import 'package:expense_tracker/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:expense_tracker/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:expense_tracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:expense_tracker/features/profile/presentation/bloc/profile_event.dart';
import 'package:expense_tracker/features/profile/presentation/bloc/profile_state.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:io';

class MockUploadAvatarUseCase extends Mock implements UploadAvatarUseCase {}
class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}
class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}

class FakeFile extends Fake implements File {}
class FakeUserProfile extends Fake implements UserProfile {}

void main() {
  late ProfileBloc bloc;
  late MockUploadAvatarUseCase uploadAvatarUseCase;
  late MockUpdateProfileUseCase updateProfileUseCase;
  late MockGetProfileUseCase getProfileUseCase;

  setUpAll(() {
    registerFallbackValue(FakeFile());
    registerFallbackValue(FakeUserProfile());
  });

  setUp(() {
    uploadAvatarUseCase = MockUploadAvatarUseCase();
    updateProfileUseCase = MockUpdateProfileUseCase();
    getProfileUseCase = MockGetProfileUseCase();

    bloc = ProfileBloc(
      getProfileUseCase,
      updateProfileUseCase,
      uploadAvatarUseCase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('UploadAvatar should not emit if closed', () async {
    final file = File('test.png');
    when(() => uploadAvatarUseCase.call(any())).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      return Right('http://url.com');
    });

    when(() => updateProfileUseCase.call(any())).thenAnswer((_) async {
      return Right(null);
    });

    // Add event then close
    bloc.add(UploadAvatar(file));
    await Future.delayed(const Duration(milliseconds: 50));
    await bloc.close();

    await Future.delayed(const Duration(milliseconds: 100));
    // Check it doesn't crash or throw StateError
  });
}
