import 'package:expense_tracker/core/services/file_picker_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mock FilePickerPlatform (using interface)
class MockFilePickerPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements FilePicker {}

void main() {
  late FilePickerService service;
  late MockFilePickerPlatform mockFilePicker;

  setUp(() {
    mockFilePicker = MockFilePickerPlatform();
    FilePicker.platform = mockFilePicker;
    service = FilePickerService();
  });

  group('FilePickerService', () {
    test(
      'saveFile calls FilePicker.platform.saveFile with correct args',
      () async {
        when(
          () => mockFilePicker.saveFile(
            dialogTitle: any(named: 'dialogTitle'),
            fileName: any(named: 'fileName'),
            allowedExtensions: any(named: 'allowedExtensions'),
          ),
        ).thenAnswer((_) async => '/path/to/file.csv');

        final result = await service.saveFile(
          dialogTitle: 'Save CSV',
          fileName: 'report.csv',
          allowedExtensions: ['csv'],
        );

        expect(result, '/path/to/file.csv');
        verify(
          () => mockFilePicker.saveFile(
            dialogTitle: 'Save CSV',
            fileName: 'report.csv',
            allowedExtensions: ['csv'],
          ),
        ).called(1);
      },
    );

    test('saveFile returns null when cancelled', () async {
      when(
        () => mockFilePicker.saveFile(
          dialogTitle: any(named: 'dialogTitle'),
          fileName: any(named: 'fileName'),
          allowedExtensions: any(named: 'allowedExtensions'),
        ),
      ).thenAnswer((_) async => null);

      final result = await service.saveFile(
        dialogTitle: 'Save',
        fileName: 'test.pdf',
      );

      expect(result, null);
    });
  });
}
