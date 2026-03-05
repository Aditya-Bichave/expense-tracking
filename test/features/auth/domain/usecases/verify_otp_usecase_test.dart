import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAuthResponse extends Mock implements AuthResponse {}

void main() {
  late MockAuthRepository mockRepository;
  late VerifyOtpUseCase usecase;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = VerifyOtpUseCase(mockRepository);
  });

  const tPhone = '1234567890';
  const tToken = '123456';

  test('should call verifyOtp on the repository', () async {
    final tResponse = MockAuthResponse();
    when(
      () => mockRepository.verifyOtp(
        phone: any(named: 'phone'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => Right(tResponse));

    final result = await usecase(phone: tPhone, token: tToken);

    expect(result, Right(tResponse));
    verify(
      () => mockRepository.verifyOtp(phone: tPhone, token: tToken),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    when(
      () => mockRepository.verifyOtp(
        phone: any(named: 'phone'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => const Left(ServerFailure('error')));

    final result = await usecase(phone: tPhone, token: tToken);

    expect(result, const Left(ServerFailure('error')));
  });
}
