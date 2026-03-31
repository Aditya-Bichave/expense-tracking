import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/services/downloader_service_locator.dart';
import 'package:expense_tracker/core/services/downloader_service.dart';

void main() {
  test('getDownloaderService returns a DownloaderService', () {
    final service = getDownloaderService();
    expect(service, isA<DownloaderService>());
  });
}
