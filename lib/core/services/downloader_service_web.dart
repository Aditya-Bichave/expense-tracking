import 'dart:convert';
import 'dart:html' as html; // ignore: avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'downloader_service.dart';

class DownloaderServiceImpl implements DownloaderService {
  final log = Logger('DownloaderServiceWeb');
  @override
  Future<void> downloadFile({
    required Uint8List bytes,
    required String downloadName,
    String? mimeType,
  }) async {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = downloadName;
    html.document.body!.children.add(anchor);
    try {
      anchor.click();
    } catch (e, s) {
      log.severe("Msg: $e\n$s");
      log.warning('Download blocked by browser: $e\n$s');
    }
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}
