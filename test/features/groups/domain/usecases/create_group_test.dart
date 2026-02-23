import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/groups/domain/usecases/create_group.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupsRepository extends Mock implements GroupsRepository {}

class FakeGroupEntity extends Fake implements GroupEntity {}

void main() {
  late CreateGroup usecase;
  late MockGroupsRepository mockGroupsRepository;

  setUpAll(() {
    registerFallbackValue(FakeGroupEntity());
  });

  setUp(() {
    mockGroupsRepository = MockGroupsRepository();
    usecase = CreateGroup(mockGroupsRepository);
  });

  final tGroup = GroupEntity(
    id: '1',
    name: 'Test Group',
    type: GroupType.trip,
    currency: 'USD',
    createdBy: 'user1',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    isArchived: false,
  );

  test('should pass the group entity to the repository', () async {
    when(
      () => mockGroupsRepository.createGroup(any()),
    ).thenAnswer((_) async => Right(tGroup));

    final result = await usecase(tGroup);

    expect(result, Right(tGroup));
    verify(() => mockGroupsRepository.createGroup(tGroup));
    verifyNoMoreInteractions(mockGroupsRepository);
  });

  test('should return Failure when repository fails', () async {
    final tFailure = ServerFailure('Server Failure');
    when(
      () => mockGroupsRepository.createGroup(any()),
    ).thenAnswer((_) async => Left(tFailure));

    final result = await usecase(tGroup);

    expect(result, Left(tFailure));
    verify(() => mockGroupsRepository.createGroup(tGroup));
    verifyNoMoreInteractions(mockGroupsRepository);
  });
}
