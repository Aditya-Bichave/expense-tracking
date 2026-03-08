import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockNotificationSettings extends Mock implements NotificationSettings {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  @override
  PostgrestFilterBuilder<dynamic> eq(String column, Object value) {
    return this;
  }

  @override
  Future<U> then<U>(
    FutureOr<U> Function(dynamic value) onValue, {
    Function? onError,
  }) {
    return Future.value().then(onValue).catchError(onError ?? (e) {});
  }
}

void main() {
  late MockSupabaseClient mockSupabaseClient;
  late MockFirebaseMessaging mockFirebaseMessaging;
  late NotificationService notificationService;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockNotificationSettings mockSettings;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late FakePostgrestFilterBuilder mockFilterBuilder;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockFirebaseMessaging = MockFirebaseMessaging();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    mockSettings = MockNotificationSettings();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = FakePostgrestFilterBuilder();

    when(
      () => mockSupabaseClient.from(any()),
    ).thenAnswer((_) => mockQueryBuilder);
    when(() => mockQueryBuilder.delete()).thenAnswer((_) => mockFilterBuilder);

    when(() => mockSupabaseClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('user123');

    when(
      () => mockFirebaseMessaging.requestPermission(),
    ).thenAnswer((_) async => mockSettings);

    when(
      () => mockSettings.authorizationStatus,
    ).thenReturn(AuthorizationStatus.authorized);

    // Default mocks for stream to prevent errors
    when(
      () => mockFirebaseMessaging.onTokenRefresh,
    ).thenAnswer((_) => const Stream.empty());

    notificationService = NotificationService(
      supabase: mockSupabaseClient,
      fcm: mockFirebaseMessaging,
    );
  });

  group('NotificationService', () {
    test('syncDeviceToken does nothing if user declines permission', () async {
      when(
        () => mockSettings.authorizationStatus,
      ).thenReturn(AuthorizationStatus.denied);

      await notificationService.syncDeviceToken();

      verify(() => mockFirebaseMessaging.requestPermission()).called(1);
      verifyNever(() => mockFirebaseMessaging.getToken());
    });

    test('syncDeviceToken does nothing if token is null', () async {
      when(
        () => mockFirebaseMessaging.getToken(),
      ).thenAnswer((_) async => null);

      await notificationService.syncDeviceToken();

      verify(() => mockFirebaseMessaging.requestPermission()).called(1);
      verify(() => mockFirebaseMessaging.getToken()).called(1);
    });

    test('deleteDeviceToken calls FCM deleteToken', () async {
      when(
        () => mockFirebaseMessaging.deleteToken(),
      ).thenAnswer((_) async => {});

      await notificationService.deleteDeviceToken();

      verify(() => mockFirebaseMessaging.deleteToken()).called(1);
    });
  });
}
