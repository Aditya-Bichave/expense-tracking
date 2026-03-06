import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/groups/domain/usecases/join_group.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupsRepository extends Mock implements GroupsRepository {}

void main() {
  late JoinGroup usecase;
  late MockGroupsRepository mockGroupsRepository;

  setUp(() {
    mockGroupsRepository = MockGroupsRepository();
    usecase = JoinGroup(mockGroupsRepository);
  });

  const tToken = 'test_token';
  final tResult = {'status': 'success', 'groupId': 'test_group_id'};

  test('should return Map from the repository when successful', () async {
    // arrange
    when(
      () => mockGroupsRepository.acceptInvite(any()),
    ).thenAnswer((_) async => Right(tResult));

    // act
    final result = await usecase(tToken);

    // assert
    expect(result, Right(tResult));
    verify(() => mockGroupsRepository.acceptInvite(tToken));
    verifyNoMoreInteractions(mockGroupsRepository);
  });

  test('should return Failure from the repository when unsuccessful', () async {
    // arrange
    final tFailure = ServerFailure('Server Error');
    when(
      () => mockGroupsRepository.acceptInvite(any()),
    ).thenAnswer((_) async => Left(tFailure));

    // act
    final result = await usecase(tToken);

    // assert
    expect(result, Left(tFailure));
    verify(() => mockGroupsRepository.acceptInvite(tToken));
    verifyNoMoreInteractions(mockGroupsRepository);
  });
}
