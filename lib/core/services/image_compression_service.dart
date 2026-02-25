import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart'; // For RootIsolateToken
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageCompressionService {
  Future<XFile?> compressImage(String sourcePath) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(
      tempDir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    // Capture the token to allow platform channel access in the background isolate
    final token = RootIsolateToken.instance;

    return await Isolate.run(() async {
      if (token != null) {
        BackgroundIsolateBinaryMessenger.ensureInitialized(token);
      }

      return await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        quality: 70,
        minWidth: 1920,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );
    });
  }
}
