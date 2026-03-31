import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/services/downloader_service_stub.dart';

void main() {
  group('DownloaderServiceStub Test', () {
    test('downloadFile throws UnimplementedError', () async {
      final service = DownloaderServiceImpl();

      expect(
        () => service.downloadFile(
          bytes: Uint8List.fromList([1, 2, 3]),
          downloadName: 'test.pdf',
        ),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
