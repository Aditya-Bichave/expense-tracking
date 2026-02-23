import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/groups/domain/usecases/watch_groups.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupsRepository extends Mock implements GroupsRepository {}

void main() {
  late WatchGroups usecase;
  late MockGroupsRepository mockGroupsRepository;

  setUp(() {
    mockGroupsRepository = MockGroupsRepository();
    usecase = WatchGroups(mockGroupsRepository);
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

  test('should return a stream of groups from the repository', () {
    final tStream = Stream.value(Right<Failure, List<GroupEntity>>([tGroup]));
    when(() => mockGroupsRepository.watchGroups()).thenAnswer((_) => tStream);

    final result = usecase();

    expect(result, tStream);
    verify(() => mockGroupsRepository.watchGroups());
    verifyNoMoreInteractions(mockGroupsRepository);
  });
}
