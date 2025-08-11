import 'package:flutter/foundation.dart';

abstract class DownloaderService {
  Future<void> downloadFile({
    required Uint8List bytes,
    required String downloadName,
    String? mimeType,
  });
}
