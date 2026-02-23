import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:expense_tracker/features/profile/domain/repositories/profile_repository.dart';
import 'package:expense_tracker/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class FakeUserProfile extends Fake implements UserProfile {}

void main() {
  late UpdateProfileUseCase usecase;
  late MockProfileRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(FakeUserProfile());
  });

  setUp(() {
    mockRepository = MockProfileRepository();
    usecase = UpdateProfileUseCase(mockRepository);
  });

  const tProfile = UserProfile(
    id: '1',
    fullName: 'Test User',
    currency: 'USD',
    timezone: 'UTC',
  );

  test('should update profile via repository', () async {
    when(
      () => mockRepository.updateProfile(any()),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase(tProfile);

    expect(result, const Right(null));
    verify(() => mockRepository.updateProfile(tProfile)).called(1);
  });
}
