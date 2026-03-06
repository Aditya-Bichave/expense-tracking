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

  final tGroupList = [
    GroupEntity(
      id: 'test_id_1',
      name: 'Test Group 1',
      type: GroupType.custom,
      currency: 'USD',
      createdBy: 'user_123',
      createdAt: DateTime(2023, 1, 1),
      updatedAt: DateTime(2023, 1, 1),
    ),
  ];

  test('should return stream of Right(List<GroupEntity>) from repository', () {
    // arrange
    when(
      () => mockGroupsRepository.watchGroups(),
    ).thenAnswer((_) => Stream.value(Right(tGroupList)));

    // act
    final result = usecase();

    // assert
    expect(result, emitsInOrder([Right(tGroupList)]));
    verify(() => mockGroupsRepository.watchGroups());
    verifyNoMoreInteractions(mockGroupsRepository);
  });

  test('should return stream of Left(Failure) from repository', () {
    // arrange
    final tFailure = ServerFailure('Server Error');
    when(
      () => mockGroupsRepository.watchGroups(),
    ).thenAnswer((_) => Stream.value(Left(tFailure)));

    // act
    final result = usecase();

    // assert
    expect(result, emitsInOrder([Left(tFailure)]));
    verify(() => mockGroupsRepository.watchGroups());
    verifyNoMoreInteractions(mockGroupsRepository);
  });
}
