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
    id: 'test_id',
    name: 'Test Group',
    type: GroupType.custom,
    currency: 'USD',
    createdBy: 'user_123',
    createdAt: DateTime(2023, 1, 1),
    updatedAt: DateTime(2023, 1, 1),
  );

  test(
    'should return GroupEntity from the repository when successful',
    () async {
      // arrange
      when(
        () => mockGroupsRepository.createGroup(any()),
      ).thenAnswer((_) async => Right(tGroup));

      // act
      final result = await usecase(tGroup);

      // assert
      expect(result, Right(tGroup));
      verify(() => mockGroupsRepository.createGroup(tGroup));
      verifyNoMoreInteractions(mockGroupsRepository);
    },
  );

  test('should return Failure from the repository when unsuccessful', () async {
    // arrange
    final tFailure = ServerFailure('Server Error');
    when(
      () => mockGroupsRepository.createGroup(any()),
    ).thenAnswer((_) async => Left(tFailure));

    // act
    final result = await usecase(tGroup);

    // assert
    expect(result, Left(tFailure));
    verify(() => mockGroupsRepository.createGroup(tGroup));
    verifyNoMoreInteractions(mockGroupsRepository);
  });
}
