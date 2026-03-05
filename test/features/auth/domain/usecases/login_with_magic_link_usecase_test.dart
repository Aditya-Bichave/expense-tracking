import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/auth/domain/usecases/login_with_magic_link_usecase.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:dartz/dartz.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late LoginWithMagicLinkUseCase usecase;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = LoginWithMagicLinkUseCase(mockRepository);
  });

  const tEmail = 'test@example.com';

  test('should call signInWithMagicLink on the repository', () async {
    when(
      () => mockRepository.signInWithMagicLink(any()),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase(tEmail);

    expect(result, const Right(null));
    verify(() => mockRepository.signInWithMagicLink(tEmail)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    when(
      () => mockRepository.signInWithMagicLink(any()),
    ).thenAnswer((_) async => const Left(ServerFailure('error')));

    final result = await usecase(tEmail);

    expect(result, const Left(ServerFailure('error')));
  });
}
