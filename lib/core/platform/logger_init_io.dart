import 'dart:io';
import 'package:path_provider/path_provider.dart';

File? _startupLogFile;

Future<void> initFileLogger() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    _startupLogFile = File('${dir.path}/startup.log');
  } catch (_) {}
}

Future<void> writeStartupLog(String message) async {
  try {
    final file = _startupLogFile;
    if (file != null) {
      final timestamp = DateTime.now().toIso8601String();
      await file.writeAsString('$timestamp $message\n', mode: FileMode.append);
    }
  } catch (_) {}
}
