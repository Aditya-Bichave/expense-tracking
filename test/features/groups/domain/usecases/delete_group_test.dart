import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/groups/domain/usecases/delete_group.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupsRepository extends Mock implements GroupsRepository {}

void main() {
  late DeleteGroup usecase;
  late MockGroupsRepository mockGroupsRepository;

  setUp(() {
    mockGroupsRepository = MockGroupsRepository();
    usecase = DeleteGroup(mockGroupsRepository);
  });

  test('passes the group id to the repository', () async {
    when(
      () => mockGroupsRepository.deleteGroup('g1'),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase('g1');

    expect(result, const Right(null));
    verify(() => mockGroupsRepository.deleteGroup('g1')).called(1);
    verifyNoMoreInteractions(mockGroupsRepository);
  });

  test('returns failures from the repository', () async {
    final failure = ServerFailure('Delete failed');
    when(
      () => mockGroupsRepository.deleteGroup('g1'),
    ).thenAnswer((_) async => Left(failure));

    final result = await usecase('g1');

    expect(result, Left(failure));
  });
}
