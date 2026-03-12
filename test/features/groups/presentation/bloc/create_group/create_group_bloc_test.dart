import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';
import 'package:dartz/dartz.dart';

import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/features/groups/domain/usecases/create_group.dart';
import 'package:expense_tracker/features/groups/domain/usecases/update_group.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_state.dart';

class MockCreateGroup extends Mock implements CreateGroup {}

class MockUpdateGroup extends Mock implements UpdateGroup {}

class MockUuid extends Mock implements Uuid {}

void main() {
  late CreateGroupBloc bloc;
  late MockCreateGroup mockCreateGroup;
  late MockUpdateGroup mockUpdateGroup;
  late MockUuid mockUuid;

  setUpAll(() {
    registerFallbackValue(
      GroupEntity(
        id: 'g1',
        name: 'name',
        type: GroupType.trip,
        currency: 'USD',
        createdBy: 'u1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockCreateGroup = MockCreateGroup();
    mockUpdateGroup = MockUpdateGroup();
    mockUuid = MockUuid();
    bloc = CreateGroupBloc(
      createGroup: mockCreateGroup,
      updateGroup: mockUpdateGroup,
      uuid: mockUuid,
    );
  });

  group('CreateGroupBloc', () {
    test('initial state should be CreateGroupInitial', () {
      expect(bloc.state, isA<CreateGroupInitial>());
    });

    final dateTime = DateTime.now();
    final groupEntity = GroupEntity(
      id: 'mock-uuid',
      name: 'Test Group',
      type: GroupType.trip,
      currency: 'USD',
      createdBy: 'u1',
      createdAt: dateTime,
      updatedAt: dateTime,
      isArchived: false,
    );

    blocTest<CreateGroupBloc, CreateGroupState>(
      'emits [CreateGroupLoading, CreateGroupSuccess] when createGroup succeeds',
      setUp: () {
        when(() => mockUuid.v4()).thenReturn('mock-uuid');
        when(
          () => mockCreateGroup(any()),
        ).thenAnswer((_) async => Right(groupEntity));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(
        CreateGroupSubmitted(
          name: 'Test Group',
          type: GroupType.trip,
          currency: 'USD',
          userId: 'u1',
          photoFile: File('dummy.jpg'),
        ),
      ),
      expect: () => [
        isA<CreateGroupLoading>(),
        CreateGroupSuccess(groupEntity),
      ],
      verify: (_) {
        verify(() => mockCreateGroup(any())).called(1);
        verifyNever(() => mockUpdateGroup(any()));
      },
    );

    blocTest<CreateGroupBloc, CreateGroupState>(
      'emits [CreateGroupLoading, CreateGroupSuccess] when edit mode updates the group',
      setUp: () {
        final updatedGroup = groupEntity.copyWith(name: 'Renamed Group');
        when(
          () => mockUpdateGroup(any()),
        ).thenAnswer((_) async => Right(updatedGroup));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(
        CreateGroupSubmitted(
          name: 'Renamed Group',
          type: GroupType.trip,
          currency: 'USD',
          userId: 'u1',
          groupId: 'mock-uuid',
          createdBy: 'u1',
          createdAt: dateTime,
          existingPhotoUrl: 'https://example.com/photo.jpg',
        ),
      ),
      expect: () => [
        isA<CreateGroupLoading>(),
        isA<CreateGroupSuccess>().having(
          (state) => state.group.name,
          'updated name',
          'Renamed Group',
        ),
      ],
      verify: (_) {
        verify(() => mockUpdateGroup(any())).called(1);
        verifyNever(() => mockCreateGroup(any()));
      },
    );

    blocTest<CreateGroupBloc, CreateGroupState>(
      'emits [CreateGroupLoading, CreateGroupFailure] when createGroup fails',
      setUp: () {
        when(() => mockUuid.v4()).thenReturn('mock-uuid');
        when(
          () => mockCreateGroup(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Creation failed')));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(
        const CreateGroupSubmitted(
          name: 'Test Group',
          type: GroupType.trip,
          currency: 'USD',
          userId: 'u1',
        ),
      ),
      expect: () => [
        isA<CreateGroupLoading>(),
        const CreateGroupFailure('Creation failed'),
      ],
    );
  });
}
