import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/profile/domain/repositories/profile_repository.dart';
import 'package:expense_tracker/features/profile/domain/usecases/upload_avatar_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class FakeFile extends Fake implements File {}

void main() {
  late UploadAvatarUseCase usecase;
  late MockProfileRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeFile());
  });

  setUp(() {
    mockRepository = MockProfileRepository();
    usecase = UploadAvatarUseCase(mockRepository);
  });

  test('should upload avatar via repository', () async {
    final tFile = FakeFile();
    when(
      () => mockRepository.uploadAvatar(any()),
    ).thenAnswer((_) async => const Right('url'));

    final result = await usecase(tFile);

    expect(result, const Right('url'));
    verify(() => mockRepository.uploadAvatar(tFile)).called(1);
  });
}
