import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/deep_link/presentation/bloc/deep_link_bloc.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAppLinks extends Mock implements AppLinks {}

class MockGroupsRepository extends Mock implements GroupsRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUser extends Mock implements User {}

void main() {
  late DeepLinkBloc bloc;
  late MockAppLinks mockAppLinks;
  late MockGroupsRepository mockGroupsRepository;
  late MockAuthRepository mockAuthRepository;
  late MockUser mockUser;

  setUp(() {
    mockAppLinks = MockAppLinks();
    mockGroupsRepository = MockGroupsRepository();
    mockAuthRepository = MockAuthRepository();
    mockUser = MockUser();

    when(
      () => mockAppLinks.uriLinkStream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockAppLinks.getInitialLink()).thenAnswer((_) async => null);

    bloc = DeepLinkBloc(mockAppLinks, mockGroupsRepository, mockAuthRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('DeepLinkBloc', () {
    test('initial state is DeepLinkInitial', () {
      expect(bloc.state, DeepLinkInitial());
    });

    blocTest<DeepLinkBloc, DeepLinkState>(
      'emits [DeepLinkProcessing, DeepLinkSuccess] when DeepLinkManualEntry is added and join is successful',
      setUp: () {
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenReturn(Right(mockUser));
        when(() => mockGroupsRepository.acceptInvite(any())).thenAnswer(
          (_) async =>
              const Right({'group_id': '123', 'group_name': 'Test Group'}),
        );
        when(
          () => mockGroupsRepository.syncGroups(),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const DeepLinkManualEntry('token123')),
      expect: () => [
        DeepLinkProcessing(),
        const DeepLinkSuccess(groupId: '123', groupName: 'Test Group'),
      ],
    );

    blocTest<DeepLinkBloc, DeepLinkState>(
      'emits [DeepLinkProcessing, DeepLinkError] when DeepLinkManualEntry fails',
      setUp: () {
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenReturn(Right(mockUser));
        when(
          () => mockGroupsRepository.acceptInvite(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Invalid token')));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const DeepLinkManualEntry('invalid')),
      expect: () => [
        DeepLinkProcessing(),
        const DeepLinkError('Invalid token'),
      ],
    );
  });
}
