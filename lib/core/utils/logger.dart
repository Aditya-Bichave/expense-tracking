import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:simple_logger/simple_logger.dart';

final log = SimpleLogger()
  ..onLogged = (log, info) {
    if (kIsWeb && kReleaseMode) {
      _sendToServer(info);
    }
  };

// Throttling: Max 1 log every 100ms per client to avoid spamming the server
DateTime? _lastLogTime;
const _minLogInterval = Duration(milliseconds: 100);

Future<void> _sendToServer(LogInfo info) async {
  final now = DateTime.now();
  if (_lastLogTime != null && now.difference(_lastLogTime!) < _minLogInterval) {
    return;
  }
  _lastLogTime = now;

  try {
    // Determine the level string
    String levelStr = info.level.toString();

    // Construct the payload
    final Map<String, dynamic> payload = {
      'level': levelStr,
      'message': info.message,
      'time': info.time.toIso8601String(),
    };

    if (info.callerFrame != null) {
      payload['caller'] = info.callerFrame.toString();
    }
    if (info.stackTrace != null) {
      payload['stackTrace'] = info.stackTrace.toString();
    }

    await http.post(
      Uri.parse('/log'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
  } catch (_) {
    // Fail silently to avoid infinite loops or blocking
  }
}
