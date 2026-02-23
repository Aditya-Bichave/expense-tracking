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

  test('should call syncGroups on the repository', () async {
    when(
      () => mockGroupsRepository.syncGroups(),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase();

    expect(result, const Right(null));
    verify(() => mockGroupsRepository.syncGroups());
    verifyNoMoreInteractions(mockGroupsRepository);
  });

  test('should return Failure when repository fails', () async {
    final tFailure = ServerFailure('Server Failure');
    when(
      () => mockGroupsRepository.syncGroups(),
    ).thenAnswer((_) async => Left(tFailure));

    final result = await usecase();

    expect(result, Left(tFailure));
    verify(() => mockGroupsRepository.syncGroups());
    verifyNoMoreInteractions(mockGroupsRepository);
  });
}
