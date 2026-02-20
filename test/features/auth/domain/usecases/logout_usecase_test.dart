import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/auth/domain/usecases/logout_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_helpers.dart';

void main() {
  late LogoutUseCase usecase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = LogoutUseCase(mockRepository);
  });

  test('should call repository.signOut', () async {
    when(
      () => mockRepository.signOut(),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase();

    expect(result, const Right(null));
    verify(() => mockRepository.signOut()).called(1);
  });
}
