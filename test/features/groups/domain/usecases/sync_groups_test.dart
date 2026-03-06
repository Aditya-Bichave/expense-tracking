import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/groups/domain/usecases/sync_groups.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupsRepository extends Mock implements GroupsRepository {}

void main() {
  late SyncGroups usecase;
  late MockGroupsRepository mockGroupsRepository;

  setUp(() {
    mockGroupsRepository = MockGroupsRepository();
    usecase = SyncGroups(mockGroupsRepository);
  });

  test(
    'should call syncGroups from the repository and return Right(null) when successful',
    () async {
      // arrange
      when(
        () => mockGroupsRepository.syncGroups(),
      ).thenAnswer((_) async => const Right(null));

      // act
      final result = await usecase();

      // assert
      expect(result, const Right(null));
      verify(() => mockGroupsRepository.syncGroups());
      verifyNoMoreInteractions(mockGroupsRepository);
    },
  );

  test('should return Failure from the repository when unsuccessful', () async {
    // arrange
    final tFailure = ServerFailure('Server Error');
    when(
      () => mockGroupsRepository.syncGroups(),
    ).thenAnswer((_) async => Left(tFailure));

    // act
    final result = await usecase();

    // assert
    expect(result, Left(tFailure));
    verify(() => mockGroupsRepository.syncGroups());
    verifyNoMoreInteractions(mockGroupsRepository);
  });
}
