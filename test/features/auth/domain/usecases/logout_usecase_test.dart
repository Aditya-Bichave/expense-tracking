import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/auth/domain/usecases/logout_usecase.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:dartz/dartz.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late LogoutUseCase usecase;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = LogoutUseCase(mockRepository);
  });

  test('should call signOut on the repository', () async {
    when(
      () => mockRepository.signOut(),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase();

    expect(result, const Right(null));
    verify(() => mockRepository.signOut()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    when(
      () => mockRepository.signOut(),
    ).thenAnswer((_) async => const Left(ServerFailure('error')));

    final result = await usecase();

    expect(result, const Left(ServerFailure('error')));
  });
}
