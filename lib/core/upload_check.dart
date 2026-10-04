import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'api_client.dart';

const int maxImageUploadBytes = 2 * 1024 * 1024;

const String imageUploadNote = 'maks. 2 MB';

Future<Uint8List> readImageBytesChecked(
  XFile file, {
  String label = 'Foto',
}) async {
  final bytes = await file.readAsBytes();
  if (bytes.length > maxImageUploadBytes) {
    throw ApiException(message: '$label maksimal 2 MB per berkas.');
  }
  return bytes;
}