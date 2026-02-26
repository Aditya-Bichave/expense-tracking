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

class MockAppLinks extends Mock implements AppLinks {}
class MockGroupsRepository extends Mock implements GroupsRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAppLinks mockAppLinks;
  late MockGroupsRepository mockGroupsRepository;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAppLinks = MockAppLinks();
    mockGroupsRepository = MockGroupsRepository();
    mockAuthRepository = MockAuthRepository();

    // Mock initial link
    when(() => mockAppLinks.getInitialLink()).thenAnswer((_) async => null);
    // Mock stream
    when(() => mockAppLinks.uriLinkStream).thenAnswer((_) => const Stream.empty());
  });

  group('DeepLinkBloc', () {
    test('initial state is DeepLinkInitial', () {
      final bloc = DeepLinkBloc(mockAppLinks, mockGroupsRepository, mockAuthRepository);
      expect(bloc.state, isA<DeepLinkInitial>());
    });

    blocTest<DeepLinkBloc, DeepLinkState>(
      'ignores invalid URI in arguments',
      build: () => DeepLinkBloc(mockAppLinks, mockGroupsRepository, mockAuthRepository),
      act: (bloc) => bloc.add(const DeepLinkStarted(args: [
        'io.supabase.expensetracker://host:abc'
      ])),
      expect: () => [], // No state emitted because DeepLinkReceived is not added
    );

    blocTest<DeepLinkBloc, DeepLinkState>(
      'requires login for join links instead of auto-creating anonymous account',
      build: () {
        when(() => mockAuthRepository.getCurrentUser()).thenReturn(const Right(null)); // Not logged in
        return DeepLinkBloc(mockAppLinks, mockGroupsRepository, mockAuthRepository);
      },
      act: (bloc) => bloc.add(const DeepLinkStarted(args: [
        'io.supabase.expensetracker://join?token=123'
      ])),
      expect: () => [
        isA<DeepLinkProcessing>(),
        isA<DeepLinkError>().having((e) => e.message, 'message', contains('Please log in')),
      ],
      verify: (_) {
        verifyNever(() => mockAuthRepository.signInAnonymously());
      }
    );
  });
}
