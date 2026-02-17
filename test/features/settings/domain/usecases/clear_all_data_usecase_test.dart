import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:expense_tracker/features/settings/domain/usecases/clear_all_data_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDataManagementRepository extends Mock
    implements DataManagementRepository {}

void main() {
  late ClearAllDataUseCase useCase;
  late MockDataManagementRepository mockRepository;

  setUp(() {
    mockRepository = MockDataManagementRepository();
    useCase = ClearAllDataUseCase(mockRepository);
  });

  test('should clear all data using the repository', () async {
    // arrange
    when(
      () => mockRepository.clearAllData(),
    ).thenAnswer((_) async => const Right(null));
    // act
    final result = await useCase(NoParams());
    // assert
    expect(result, const Right(null));
    verify(() => mockRepository.clearAllData());
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return failure when repository fails', () async {
    // arrange
    when(() => mockRepository.clearAllData()).thenAnswer(
      (_) async => Left(ClearDataFailure('Failed')),
    ); // ClearDataFailure is from implementation
    // act
    final result = await useCase(NoParams());
    // assert
    expect(result, Left(ClearDataFailure('Failed')));
    verify(() => mockRepository.clearAllData());
  });
}
