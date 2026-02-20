import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/mock_helpers.dart';

class FakeAuthResponse extends Fake implements AuthResponse {}

void main() {
  late VerifyOtpUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = VerifyOtpUseCase(mockRepository);
  });

  test('should call repository.verifyOtp', () async {
    final tAuthResponse = FakeAuthResponse();
    when(
      () => mockRepository.verifyOtp(
        phone: any(named: 'phone'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => Right(tAuthResponse));

    final result = await usecase(phone: '123456', token: '1234');

    expect(result, Right(tAuthResponse));
    verify(
      () => mockRepository.verifyOtp(phone: '123456', token: '1234'),
    ).called(1);
  });
}
