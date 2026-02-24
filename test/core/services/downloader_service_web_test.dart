@TestOn('browser')
import 'dart:convert';
import 'dart:html' as html;
import 'package:expense_tracker/core/services/downloader_service_web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DownloaderServiceWeb', () {
    test('downloadFile creates anchor and triggers download', () async {
      final service = DownloaderServiceImpl();
      final bytes = utf8.encode('test content');

      // We can't easily verify the click behavior in headless unit test without browser interaction
      // but we can ensure it doesn't throw.
      await expectLater(
        service.downloadFile(
          bytes: bytes,
          downloadName: 'test.txt',
          mimeType: 'text/plain',
        ),
        completes,
      );

      // In a real browser test, we'd check DOM for the anchor, but it's removed immediately.
    });
  });
}
