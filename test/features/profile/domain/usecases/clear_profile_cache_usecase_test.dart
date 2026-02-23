import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/profile/domain/repositories/profile_repository.dart';
import 'package:expense_tracker/features/profile/domain/usecases/clear_profile_cache_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late ClearProfileCacheUseCase usecase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    usecase = ClearProfileCacheUseCase(mockRepository);
  });

  test('should clear profile cache via repository', () async {
    when(
      () => mockRepository.clearProfileCache(),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase(NoParams());

    expect(result, const Right(null));
    verify(() => mockRepository.clearProfileCache()).called(1);
  });
}
