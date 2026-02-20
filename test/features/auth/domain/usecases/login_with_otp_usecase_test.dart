import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/auth/domain/usecases/login_with_otp_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_helpers.dart';

void main() {
  late LoginWithOtpUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = LoginWithOtpUseCase(mockRepository);
  });

  test('should call repository.signInWithOtp', () async {
    when(
      () => mockRepository.signInWithOtp(any()),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase('123456');

    expect(result, const Right(null));
    verify(() => mockRepository.signInWithOtp('123456')).called(1);
  });
}
