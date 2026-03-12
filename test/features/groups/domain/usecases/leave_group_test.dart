import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/groups/domain/usecases/leave_group.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupsRepository extends Mock implements GroupsRepository {}

void main() {
  late LeaveGroup usecase;
  late MockGroupsRepository mockGroupsRepository;

  setUp(() {
    mockGroupsRepository = MockGroupsRepository();
    usecase = LeaveGroup(mockGroupsRepository);
  });

  test('passes the group id and user id to the repository', () async {
    when(
      () => mockGroupsRepository.leaveGroup('g1', 'u1'),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase('g1', 'u1');

    expect(result, const Right(null));
    verify(() => mockGroupsRepository.leaveGroup('g1', 'u1')).called(1);
    verifyNoMoreInteractions(mockGroupsRepository);
  });

  test('returns failures from the repository', () async {
    final failure = ServerFailure('Leave failed');
    when(
      () => mockGroupsRepository.leaveGroup('g1', 'u1'),
    ).thenAnswer((_) async => Left(failure));

    final result = await usecase('g1', 'u1');

    expect(result, Left(failure));
  });
}
