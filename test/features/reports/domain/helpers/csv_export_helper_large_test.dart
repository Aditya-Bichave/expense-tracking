import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart';
import 'package:expense_tracker/core/services/downloader_service.dart';

class MockDownloaderService extends Mock implements DownloaderService {}

void main() {
  late CsvExportHelper helper;
  late MockDownloaderService mockDownloader;

  setUp(() {
    mockDownloader = MockDownloaderService();
    helper = CsvExportHelper(downloaderService: mockDownloader);
  });

  test('can be instantiated', () {
    expect(helper, isNotNull);
  });
}
