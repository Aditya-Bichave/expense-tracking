import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(
    'dev.fluttercommunity.plus/device_info',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        return {
          'name': 'test',
          'systemName': 'test',
          'systemVersion': 'test',
          'model': 'test',
          'localizedModel': 'test',
          'identifierForVendor': 'test-device-id',
          'isPhysicalDevice': true,
          'utsname': {
            'sysname': 'test',
            'nodename': 'test',
            'release': 'test',
            'version': 'test',
            'machine': 'test',
          },
        };
      });

  late MockSupabaseClient mockSupabaseClient;
  late MockFirebaseMessaging mockFirebaseMessaging;
  late NotificationService notificationService;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockNotificationSettings mockSettings;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late FakePostgrestFilterBuilder mockFilterBuilder;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
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

    notificationService = NotificationService(
      supabase: mockSupabaseClient,
      fcm: mockFirebaseMessaging,
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
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
      when(() => mockFirebaseMessaging.deleteToken()).thenAnswer((_) async {});

      await notificationService.deleteDeviceToken();

      verify(() => mockFirebaseMessaging.deleteToken()).called(1);
    });

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
    });

    test('deleteDeviceToken does nothing if user is null', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      await notificationService.deleteDeviceToken();

      verifyNever(() => mockSupabaseClient.from(any()));
    });
  });
}
