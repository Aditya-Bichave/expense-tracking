import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/groups/domain/usecases/update_group.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupsRepository extends Mock implements GroupsRepository {}

class FakeGroupEntity extends Fake implements GroupEntity {}

void main() {
  late UpdateGroup usecase;
  late MockGroupsRepository mockGroupsRepository;

  final group = GroupEntity(
    id: 'g1',
    name: 'Edited',
    type: GroupType.trip,
    currency: 'USD',
    createdBy: 'u1',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 2),
  );

  setUpAll(() {
    registerFallbackValue(FakeGroupEntity());
  });

  setUp(() {
    mockGroupsRepository = MockGroupsRepository();
    usecase = UpdateGroup(mockGroupsRepository);
  });

  test('passes the group to the repository', () async {
    when(
      () => mockGroupsRepository.updateGroup(any()),
    ).thenAnswer((_) async => Right(group));

    final result = await usecase(group);

    expect(result, Right(group));
    verify(() => mockGroupsRepository.updateGroup(group)).called(1);
    verifyNoMoreInteractions(mockGroupsRepository);
  });

  test('returns failures from the repository', () async {
    final failure = ServerFailure('Update failed');
    when(
      () => mockGroupsRepository.updateGroup(any()),
    ).thenAnswer((_) async => Left(failure));

    final result = await usecase(group);

    expect(result, Left(failure));
  });
}
