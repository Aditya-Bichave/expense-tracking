import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/features/groups/domain/usecases/create_group.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockCreateGroup extends Mock implements CreateGroup {}

class MockUuid extends Mock implements Uuid {}

class FakeGroupEntity extends Fake implements GroupEntity {}

void main() {
  late CreateGroupBloc bloc;
  late MockCreateGroup mockCreateGroup;
  late MockUuid mockUuid;

  setUpAll(() {
    registerFallbackValue(FakeGroupEntity());
  });

  setUp(() {
    mockCreateGroup = MockCreateGroup();
    mockUuid = MockUuid();
    bloc = CreateGroupBloc(createGroup: mockCreateGroup, uuid: mockUuid);
  });

  tearDown(() {
    bloc.close();
  });

  final tGroup = GroupEntity(
    id: 'generated-uuid',
    name: 'Test Setup',
    type: GroupType.home,
    currency: 'EUR',
    createdBy: 'test-user',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    isArchived: false,
  );

  test('initial state should be CreateGroupInitial', () {
    expect(bloc.state, CreateGroupInitial());
  });

  blocTest<CreateGroupBloc, CreateGroupState>(
    'should emit [CreateGroupLoading, CreateGroupSuccess] when CreateGroupSubmitted is added and succeeds',
    build: () {
      when(() => mockUuid.v4()).thenReturn('generated-uuid');
      when(() => mockCreateGroup(any())).thenAnswer((_) async => Right(tGroup));
      return bloc;
    },
    act: (bloc) => bloc.add(
      const CreateGroupSubmitted(
        name: 'Test Setup',
        type: GroupType.home,
        currency: 'EUR',
        userId: 'test-user',
      ),
    ),
    expect: () => [CreateGroupLoading(), CreateGroupSuccess(tGroup)],
    verify: (_) {
      verify(() => mockUuid.v4()).called(1);
      verify(() => mockCreateGroup(any())).called(1);
    },
  );

  blocTest<CreateGroupBloc, CreateGroupState>(
    'should emit [CreateGroupLoading, CreateGroupFailure] when CreateGroupSubmitted is added and fails',
    build: () {
      when(() => mockUuid.v4()).thenReturn('generated-uuid');
      when(
        () => mockCreateGroup(any()),
      ).thenAnswer((_) async => Left(ServerFailure('Server Error')));
      return bloc;
    },
    act: (bloc) => bloc.add(
      const CreateGroupSubmitted(
        name: 'Test Setup',
        type: GroupType.home,
        currency: 'EUR',
        userId: 'test-user',
      ),
    ),
    expect: () => [
      CreateGroupLoading(),
      const CreateGroupFailure('Server Error'),
    ],
    verify: (_) {
      verify(() => mockUuid.v4()).called(1);
      verify(() => mockCreateGroup(any())).called(1);
    },
  );
}
