import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

class FilePickerService {
  static Future<SelectedFile?> pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (kIsWeb) {
          // On web, we get bytes directly
          if (file.bytes != null) {
            return SelectedFile(
              name: file.name,
              size: file.size,
              bytes: file.bytes!,
              path: null,
            );
          }
        } else {
          // On mobile, we get file path
          if (file.path != null) {
            final fileObj = File(file.path!);
            final bytes = await fileObj.readAsBytes();
            return SelectedFile(
              name: file.name,
              size: file.size,
              bytes: bytes,
              path: file.path!,
            );
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error picking PDF file: $e');
      return null;
    }
  }
}

class SelectedFile {
  final String name;
  final int size;
  final Uint8List bytes;
  final String? path;

  SelectedFile({
    required this.name,
    required this.size,
    required this.bytes,
    this.path,
  });
}