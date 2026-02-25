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

class MockAuthResponse extends Mock implements AuthResponse {}

void main() {
  late DeepLinkBloc bloc;
  late MockAppLinks mockAppLinks;
  late MockGroupsRepository mockGroupsRepository;
  late MockAuthRepository mockAuthRepository;
  late MockUser mockUser;
  late MockAuthResponse mockAuthResponse;
  // Use StreamControllers to control event timing in tests
  late StreamController<Uri> uriStreamController;

  setUp(() {
    mockAppLinks = MockAppLinks();
    mockGroupsRepository = MockGroupsRepository();
    mockAuthRepository = MockAuthRepository();
    mockUser = MockUser();
    mockAuthResponse = MockAuthResponse();
    uriStreamController = StreamController<Uri>();

    when(
      () => mockAppLinks.uriLinkStream,
    ).thenAnswer((_) => uriStreamController.stream);
    when(() => mockAppLinks.getInitialLink()).thenAnswer((_) async => null);

    bloc = DeepLinkBloc(mockAppLinks, mockGroupsRepository, mockAuthRepository);
  });

  tearDown(() {
    uriStreamController.close();
    bloc.close();
  });

  group('DeepLinkBloc', () {
    test('initial state is DeepLinkInitial', () {
      expect(bloc.state, DeepLinkInitial());
    });

    // Test Initial Link
    blocTest<DeepLinkBloc, DeepLinkState>(
      'emits success when initial link is a valid join link',
      setUp: () {
        when(() => mockAppLinks.getInitialLink()).thenAnswer(
          (_) async => Uri.parse('https://spendos.app/join?token=123'),
        );
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenReturn(Right(mockUser));
        when(() => mockGroupsRepository.acceptInvite('123')).thenAnswer(
          (_) async =>
              const Right({'group_id': '123', 'group_name': 'Initial Group'}),
        );
        when(
          () => mockGroupsRepository.syncGroups(),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () =>
          DeepLinkBloc(mockAppLinks, mockGroupsRepository, mockAuthRepository),
      act: (bloc) => bloc.add(const DeepLinkStarted()),
      expect: () => [
        DeepLinkProcessing(),
        const DeepLinkSuccess(groupId: '123', groupName: 'Initial Group'),
      ],
    );

    // Test Manual Entry Success
    blocTest<DeepLinkBloc, DeepLinkState>(
      'emits [DeepLinkProcessing, DeepLinkSuccess] when DeepLinkManualEntry is added and join is successful',
      setUp: () {
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenReturn(Right(mockUser));
        when(() => mockGroupsRepository.acceptInvite('token123')).thenAnswer(
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

    // Test Manual Entry Failure
    blocTest<DeepLinkBloc, DeepLinkState>(
      'emits [DeepLinkProcessing, DeepLinkError] when DeepLinkManualEntry fails',
      setUp: () {
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenReturn(Right(mockUser));
        when(
          () => mockGroupsRepository.acceptInvite('invalid'),
        ).thenAnswer((_) async => const Left(ServerFailure('Invalid token')));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const DeepLinkManualEntry('invalid')),
      expect: () => [
        DeepLinkProcessing(),
        const DeepLinkError('Invalid token'),
      ],
    );

    // Test Anonymous Auth Success
    blocTest<DeepLinkBloc, DeepLinkState>(
      'signs in anonymously if user is null',
      setUp: () {
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenReturn(Left(CacheFailure('No user')));
        when(() => mockAuthResponse.user).thenReturn(mockUser);
        when(
          () => mockAuthRepository.signInAnonymously(),
        ).thenAnswer((_) async => Right(mockAuthResponse));
        when(() => mockGroupsRepository.acceptInvite('token')).thenAnswer(
          (_) async =>
              const Right({'group_id': '123', 'group_name': 'Anon Group'}),
        );
        when(
          () => mockGroupsRepository.syncGroups(),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const DeepLinkManualEntry('token')),
      expect: () => [
        DeepLinkProcessing(),
        const DeepLinkSuccess(groupId: '123', groupName: 'Anon Group'),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.signInAnonymously()).called(1);
      },
    );

    // Test Anonymous Auth Failure
    blocTest<DeepLinkBloc, DeepLinkState>(
      'emits error if anonymous sign in fails',
      setUp: () {
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenReturn(Left(CacheFailure('No user')));
        when(
          () => mockAuthRepository.signInAnonymously(),
        ).thenAnswer((_) async => const Left(ServerFailure('Auth failed')));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const DeepLinkManualEntry('token')),
      expect: () => [
        DeepLinkProcessing(),
        const DeepLinkError("Failed to sign in anonymously"),
      ],
    );

    // Test Stream Handling (https)
    blocTest<DeepLinkBloc, DeepLinkState>(
      'emits success when link received from stream',
      setUp: () {
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenReturn(Right(mockUser));
        when(() => mockGroupsRepository.acceptInvite('stream')).thenAnswer(
          (_) async =>
              const Right({'group_id': '456', 'group_name': 'Stream Group'}),
        );
        when(
          () => mockGroupsRepository.syncGroups(),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () =>
          DeepLinkBloc(mockAppLinks, mockGroupsRepository, mockAuthRepository),
      act: (bloc) async {
        bloc.add(const DeepLinkStarted());
        // Wait for bloc to subscribe
        await Future.delayed(Duration.zero);
        uriStreamController.add(
          Uri.parse('https://spendos.app/join?token=stream'),
        );
      },
      expect: () => [
        DeepLinkProcessing(),
        const DeepLinkSuccess(groupId: '456', groupName: 'Stream Group'),
      ],
    );

    // Test Custom Scheme Link
    blocTest<DeepLinkBloc, DeepLinkState>(
      'emits success when custom scheme link received',
      setUp: () {
        when(
          () => mockAuthRepository.getCurrentUser(),
        ).thenReturn(Right(mockUser));
        when(() => mockGroupsRepository.acceptInvite('custom')).thenAnswer(
          (_) async =>
              const Right({'group_id': '789', 'group_name': 'Custom Group'}),
        );
        when(
          () => mockGroupsRepository.syncGroups(),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () =>
          DeepLinkBloc(mockAppLinks, mockGroupsRepository, mockAuthRepository),
      act: (bloc) async {
        bloc.add(const DeepLinkStarted());
        // Wait for bloc to subscribe
        await Future.delayed(Duration.zero);
        uriStreamController.add(Uri.parse('spendos://join?token=custom'));
      },
      expect: () => [
        DeepLinkProcessing(),
        const DeepLinkSuccess(groupId: '789', groupName: 'Custom Group'),
      ],
    );
  });
}
