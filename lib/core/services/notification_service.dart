import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:simple_logger/simple_logger.dart';

class NotificationService {
  final SupabaseClient _supabase;
  final FirebaseMessaging _fcm;
  final SimpleLogger _log = SimpleLogger();

  NotificationService({SupabaseClient? supabase, FirebaseMessaging? fcm})
    : _supabase = supabase ?? Supabase.instance.client,
      _fcm = fcm ?? FirebaseMessaging.instance;

  Future<void> syncDeviceToken() async {
    try {
      // 1. Request Permission
      NotificationSettings settings = await _fcm.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        _log.info('User declined or has not accepted notification permissions');
        return;
      }

      // 2. Get FCM Token
      String? token = await _fcm.getToken();
      if (token == null) {
        _log.warning('Failed to get FCM token');
        return;
      }

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        _log.warning('Cannot sync device token: No user logged in');
        return;
      }

      // 3. Get Unique Device ID
      String deviceId = await _getDeviceId();
      String platform = _getPlatform();

      // 4. Upsert to Supabase
      await _upsertToken(currentUser.id, deviceId, token, platform);

      // 5. Listen for token refreshes
      _fcm.onTokenRefresh
          .listen((newToken) async {
            final user = _supabase.auth.currentUser;
            if (user != null) {
              await _upsertToken(user.id, deviceId, newToken, platform);
            }
          })
          .onError((e, s) {
            _log.severe('Error on FCM token refresh: $e\n$s');
          });
    } catch (e, s) {
      _log.severe('Error syncing device token: $e\n$s');
    }
  }

  Future<void> _upsertToken(
    String userId,
    String deviceId,
    String token,
    String platform,
  ) async {
    try {
      await _supabase.from('user_fcm_tokens').upsert({
        'user_id': userId,
        'device_id': deviceId,
        'fcm_token': token,
        'platform': platform,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e, s) {
      _log.severe('Failed to upsert user_fcm_tokens: $e\n$s');
    }
  }

  Future<void> deleteDeviceToken() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      String deviceId = await _getDeviceId();

      await _supabase
          .from('user_fcm_tokens')
          .delete()
          .eq('user_id', currentUser.id)
          .eq('device_id', deviceId);

      // Also delete the token locally from firebase messaging so it can regenerate properly next time
      await _fcm.deleteToken();
    } catch (e, s) {
      _log.severe('Error deleting device token: $e\n$s');
    }
  }

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      final webBrowserInfo = await deviceInfo.webBrowserInfo;
      return webBrowserInfo.userAgent ?? 'unknown_web';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios';
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else {
      return 'unknown_desktop';
    }
  }

  String _getPlatform() {
    if (kIsWeb) {
      return 'web';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isAndroid) {
      return 'android';
    } else {
      return 'web';
    }
  }
}
