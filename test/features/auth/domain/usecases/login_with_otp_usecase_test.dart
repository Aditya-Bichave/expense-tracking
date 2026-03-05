import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/auth/domain/usecases/login_with_otp_usecase.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:dartz/dartz.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late LoginWithOtpUseCase usecase;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = LoginWithOtpUseCase(mockRepository);
  });

  const tPhone = '1234567890';

  test('should call signInWithOtp on the repository', () async {
    when(
      () => mockRepository.signInWithOtp(any()),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase(tPhone);

    expect(result, const Right(null));
    verify(() => mockRepository.signInWithOtp(tPhone)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    when(
      () => mockRepository.signInWithOtp(any()),
    ).thenAnswer((_) async => const Left(ServerFailure('error')));

    final result = await usecase(tPhone);

    expect(result, const Left(ServerFailure('error')));
    verify(() => mockRepository.signInWithOtp(tPhone)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
