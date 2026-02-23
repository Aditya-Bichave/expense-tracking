import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:expense_tracker/features/profile/domain/repositories/profile_repository.dart';
import 'package:expense_tracker/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late GetProfileUseCase usecase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    usecase = GetProfileUseCase(mockRepository);
  });

  const tProfile = UserProfile(
    id: '1',
    fullName: 'Test User',
    currency: 'USD',
    timezone: 'UTC',
  );

  test('should get profile from repository', () async {
    when(
      () => mockRepository.getProfile(forceRefresh: any(named: 'forceRefresh')),
    ).thenAnswer((_) async => const Right(tProfile));

    final result = await usecase(forceRefresh: true);

    expect(result, const Right(tProfile));
    verify(() => mockRepository.getProfile(forceRefresh: true)).called(1);
  });
}
