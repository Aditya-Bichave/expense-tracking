import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUser extends Mock implements User {}

void main() {
  late MockAuthRepository mockRepository;
  late GetCurrentUserUseCase usecase;

  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = GetCurrentUserUseCase(mockRepository);
  });

  final tUser = MockUser();

  test('should get current user from the repository', () {
    when(() => mockRepository.getCurrentUser()).thenReturn(Right(tUser));

    final result = usecase();

    expect(result, Right(tUser));
    verify(() => mockRepository.getCurrentUser()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return null when repository returns null user', () {
    when(() => mockRepository.getCurrentUser()).thenReturn(const Right(null));

    final result = usecase();

    expect(result, const Right(null));
    verify(() => mockRepository.getCurrentUser()).called(1);
  });

  test('should return failure when repository fails', () {
    when(
      () => mockRepository.getCurrentUser(),
    ).thenReturn(const Left(ServerFailure('error')));

    final result = usecase();

    expect(result, const Left(ServerFailure('error')));
    verify(() => mockRepository.getCurrentUser()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
