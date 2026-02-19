import 'dart:typed_data';
import 'package:expense_tracker/core/services/downloader_service.dart';
import 'package:flutter_test/flutter_test.dart';

class MockDownloaderService implements DownloaderService {
  bool downloadCalled = false;
  Uint8List? lastBytes;
  String? lastDownloadName;
  String? lastMimeType;

  @override
  Future<void> downloadFile({
    required Uint8List bytes,
    required String downloadName,
    String? mimeType,
  }) async {
    downloadCalled = true;
    lastBytes = bytes;
    lastDownloadName = downloadName;
    lastMimeType = mimeType;
  }
}

void main() {
  test('DownloaderService interface can be implemented', () async {
    final service = MockDownloaderService();
    final bytes = Uint8List.fromList([1, 2, 3]);

    await service.downloadFile(
      bytes: bytes,
      downloadName: 'test.txt',
      mimeType: 'text/plain',
    );

    expect(service.downloadCalled, isTrue);
    expect(service.lastBytes, equals(bytes));
    expect(service.lastDownloadName, equals('test.txt'));
    expect(service.lastMimeType, equals('text/plain'));
  });
}
