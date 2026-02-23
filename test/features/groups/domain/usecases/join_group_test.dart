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

  const tToken = 'invite-token-123';
  final tResult = {'group_id': '1'};

  test('should pass the token to the repository', () async {
    when(
      () => mockGroupsRepository.acceptInvite(any()),
    ).thenAnswer((_) async => Right(tResult));

    final result = await usecase(tToken);

    expect(result, Right(tResult));
    verify(() => mockGroupsRepository.acceptInvite(tToken));
    verifyNoMoreInteractions(mockGroupsRepository);
  });
}
