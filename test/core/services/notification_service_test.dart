import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockNotificationSettings extends Mock implements NotificationSettings {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

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
    return Future.value().then(onValue, onError: onError);
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
  late MockSharedPreferences mockPrefs;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    mockSupabaseClient = MockSupabaseClient();
    mockFirebaseMessaging = MockFirebaseMessaging();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    mockSettings = MockNotificationSettings();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = FakePostgrestFilterBuilder();
    mockPrefs = MockSharedPreferences();

    when(
      () => mockSupabaseClient.from(any()),
    ).thenAnswer((_) => mockQueryBuilder);
    when(() => mockQueryBuilder.delete()).thenAnswer((_) => mockFilterBuilder);
    when(
      () => mockQueryBuilder.upsert(any()),
    ).thenAnswer((_) => mockFilterBuilder);

    when(() => mockSupabaseClient.auth).thenAnswer((_) => mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('user123');

    when(
      () => mockFirebaseMessaging.requestPermission(),
    ).thenAnswer((_) async => mockSettings);

    when(
      () => mockSettings.authorizationStatus,
    ).thenReturn(AuthorizationStatus.authorized);

    when(
      () => mockFirebaseMessaging.onTokenRefresh,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockFirebaseMessaging.getInitialMessage(),
    ).thenAnswer((_) async => null);

    when(
      () => mockPrefs.getString('app_device_id'),
    ).thenReturn('test-device-id');
    when(
      () => mockPrefs.setString('app_device_id', any()),
    ).thenAnswer((_) async => true);

    notificationService = NotificationService(
      supabase: mockSupabaseClient,
      fcm: mockFirebaseMessaging,
      prefs: mockPrefs,
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    notificationService.dispose();
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

    test(
      'deleteDeviceToken calls FCM deleteToken and deletes from Supabase',
      () async {
        when(
          () => mockFirebaseMessaging.deleteToken(),
        ).thenAnswer((_) async {});
        when(
          () => mockQueryBuilder.delete(),
        ).thenAnswer((_) => mockFilterBuilder);

        await notificationService.deleteDeviceToken();

        verify(() => mockFirebaseMessaging.deleteToken()).called(1);
        verify(() => mockQueryBuilder.delete()).called(1);
      },
    );

    test('syncDeviceToken does nothing if user is null', () async {
      when(
        () => mockSettings.authorizationStatus,
      ).thenReturn(AuthorizationStatus.authorized);
      when(
        () => mockFirebaseMessaging.getToken(),
      ).thenAnswer((_) async => 'token');
      when(() => mockAuth.currentUser).thenReturn(null);

      await notificationService.syncDeviceToken();

      verifyNever(() => mockSupabaseClient.from(any()));
    });

    test('deleteDeviceToken catches exceptions', () async {
      when(
        () => mockFirebaseMessaging.deleteToken(),
      ).thenThrow(Exception('test exception'));
      // should not throw
      await notificationService.deleteDeviceToken();
    });

    test('syncDeviceToken catches exceptions', () async {
      when(
        () => mockFirebaseMessaging.requestPermission(),
      ).thenThrow(Exception('test exception'));
      // should not throw
      await notificationService.syncDeviceToken();
      debugDefaultTargetPlatformOverride = null;
    });

    test('deleteDeviceToken does nothing if user is null', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      await notificationService.deleteDeviceToken();

      verifyNever(() => mockSupabaseClient.from(any()));
    });

    test('syncDeviceToken sends exact payload to supabase', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      when(
        () => mockFirebaseMessaging.getToken(),
      ).thenAnswer((_) async => 'test-fcm-token');

      await notificationService.syncDeviceToken();

      final expectedPayload = {
        'user_id': 'user123',
        'device_id': 'test-device-id',
        'fcm_token': 'test-fcm-token',
        'platform': 'ios',
      };

      verify(
        () => mockQueryBuilder.upsert(
          any(
            that: isA<Map<String, dynamic>>().having(
              (m) =>
                  m.keys.contains('updated_at') &&
                  m['user_id'] == expectedPayload['user_id'] &&
                  m['device_id'] == expectedPayload['device_id'] &&
                  m['fcm_token'] == expectedPayload['fcm_token'] &&
                  m['platform'] == expectedPayload['platform'],
              'matches expected payload',
              true,
            ),
          ),
        ),
      ).called(1);
    });

    test('syncDeviceToken handles token refresh', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final streamController = StreamController<String>();
      when(
        () => mockFirebaseMessaging.onTokenRefresh,
      ).thenAnswer((_) => streamController.stream);
      when(
        () => mockFirebaseMessaging.getToken(),
      ).thenAnswer((_) async => 'initial-token');

      await notificationService.syncDeviceToken();

      // Simulate token refresh
      streamController.add('new-token');
      await Future.delayed(Duration.zero);

      verify(() => mockQueryBuilder.upsert(any())).called(greaterThan(0));

      await streamController.close();
      debugDefaultTargetPlatformOverride = null;
    });

    test('syncDeviceToken handles token refresh error', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final streamController = StreamController<String>.broadcast();
      when(
        () => mockFirebaseMessaging.onTokenRefresh,
      ).thenAnswer((_) => streamController.stream);
      when(
        () => mockFirebaseMessaging.getToken(),
      ).thenAnswer((_) async => 'initial-token');

      await notificationService.syncDeviceToken();

      // Simulate token refresh error
      streamController.addError(Exception('refresh error'));
      await Future.microtask(
        () {},
      ); // Give stream time to process synchronously

      await streamController.close();
      debugDefaultTargetPlatformOverride = null;
    });

    test('syncDeviceToken handles upsert error', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      when(
        () => mockFirebaseMessaging.getToken(),
      ).thenAnswer((_) async => 'token');
      when(
        () => mockQueryBuilder.upsert(any()),
      ).thenThrow(Exception('upsert error'));

      await notificationService.syncDeviceToken();
      debugDefaultTargetPlatformOverride = null;
    });

    test('getPlatform covers android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      when(
        () => mockFirebaseMessaging.getToken(),
      ).thenAnswer((_) async => 'token');
      await notificationService.syncDeviceToken();
      verify(
        () => mockQueryBuilder.upsert(
          any(that: containsPair('platform', 'android')),
        ),
      ).called(1);
      debugDefaultTargetPlatformOverride = null;
    });

    test('getPlatform covers iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      when(
        () => mockFirebaseMessaging.getToken(),
      ).thenAnswer((_) async => 'token');
      await notificationService.syncDeviceToken();
      verify(
        () =>
            mockQueryBuilder.upsert(any(that: containsPair('platform', 'ios'))),
      ).called(1);
      debugDefaultTargetPlatformOverride = null;
    });

    test('getPlatform covers linux', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      when(
        () => mockFirebaseMessaging.getToken(),
      ).thenAnswer((_) async => 'token');
      await notificationService.syncDeviceToken();
      debugDefaultTargetPlatformOverride = null;
    });

    test('getPlatform covers windows', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      when(
        () => mockFirebaseMessaging.getToken(),
      ).thenAnswer((_) async => 'token');
      await notificationService.syncDeviceToken();
      debugDefaultTargetPlatformOverride = null;
    });

    test('getPlatform covers unknown platform', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
      when(
        () => mockFirebaseMessaging.getToken(),
      ).thenAnswer((_) async => 'token');
      await notificationService.syncDeviceToken();
      debugDefaultTargetPlatformOverride = null;
    });

    test('handles message opened app stream', () async {
      final streamController = StreamController<RemoteMessage>();
      // when(() => mockFirebaseMessaging.onMessageOpenedApp).thenAnswer((_) => streamController.stream);
      when(
        () => mockFirebaseMessaging.getToken(),
      ).thenAnswer((_) async => 'token');

      await notificationService.syncDeviceToken();
      streamController.add(
        RemoteMessage(data: {'type': 'NUDGE', 'group_id': 'g123'}),
      );
      streamController.add(RemoteMessage(data: {'type': 'OTHER'}));

      await Future.delayed(Duration.zero);
      streamController.close();
    });

    test('handles initial message', () async {
      when(() => mockFirebaseMessaging.getInitialMessage()).thenAnswer(
        (_) async => RemoteMessage(data: {'type': 'NUDGE', 'group_id': 'g123'}),
      );
      when(
        () => mockFirebaseMessaging.getToken(),
      ).thenAnswer((_) async => 'token');

      await notificationService.syncDeviceToken();
    });
  });
}
