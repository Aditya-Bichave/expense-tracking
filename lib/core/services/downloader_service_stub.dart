import 'package:flutter/foundation.dart';
import 'downloader_service.dart';

class DownloaderServiceImpl implements DownloaderService {
  @override
  Future<void> downloadFile({
    required Uint8List bytes,
    required String downloadName,
    String? mimeType,
  }) async {
    throw UnimplementedError('File download is not supported on this platform.');
  }
}
