import 'dart:async';
import 'package:expense_tracker/core/auth/auth_session_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockSession extends Mock implements Session {}

class FakeAuthState extends Fake implements AuthState {
  final AuthChangeEvent _event;
  final Session? _session;

  FakeAuthState(this._event, this._session);

  @override
  AuthChangeEvent get event => _event;

  @override
  Session? get session => _session;
}

void main() {
  late AuthSessionService authSessionService;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();

    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(
      () => mockGoTrueClient.onAuthStateChange,
    ).thenAnswer((_) => const Stream.empty());
  });

  test('currentUser returns user from client', () {
    final mockUser = MockUser();
    when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);

    authSessionService = AuthSessionService(mockSupabaseClient);

    expect(authSessionService.currentUser, equals(mockUser));
  });

  test('isAuthenticated returns true when currentUser is not null', () {
    final mockUser = MockUser();
    when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);

    authSessionService = AuthSessionService(mockSupabaseClient);

    expect(authSessionService.isAuthenticated, isTrue);
  });

  test('isAuthenticated returns false when currentUser is null', () {
    when(() => mockGoTrueClient.currentUser).thenReturn(null);

    authSessionService = AuthSessionService(mockSupabaseClient);

    expect(authSessionService.isAuthenticated, isFalse);
  });

  test('signOut calls client.auth.signOut', () async {
    when(() => mockGoTrueClient.signOut()).thenAnswer((_) async {
      return;
    });

    authSessionService = AuthSessionService(mockSupabaseClient);
    await authSessionService.signOut();

    verify(() => mockGoTrueClient.signOut()).called(1);
  });

  test('userStream emits user on auth state change', () async {
    final controller = StreamController<AuthState>();
    when(
      () => mockGoTrueClient.onAuthStateChange,
    ).thenAnswer((_) => controller.stream);

    authSessionService = AuthSessionService(mockSupabaseClient);

    final mockUser = MockUser();
    final mockSession = MockSession();
    when(() => mockSession.user).thenReturn(mockUser);

    expectLater(authSessionService.userStream, emits(mockUser));

    controller.add(FakeAuthState(AuthChangeEvent.signedIn, mockSession));

    await controller.close();
  });
}
