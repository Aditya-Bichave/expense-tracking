import 'package:file_picker/file_picker.dart';

class FilePickerService {
  Future<String?> saveFile({
    required String dialogTitle,
    required String fileName,
    List<String>? allowedExtensions,
  }) {
    return FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      allowedExtensions: allowedExtensions,
    );
  }
}
