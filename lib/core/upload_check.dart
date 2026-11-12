import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'api_client.dart';

/// Batas maksimum ukuran file unggahan gambar (2 Megabyte).
const int maxImageUploadBytes = 2 * 1024 * 1024;

/// Label informasi batasan ukuran file.
const String imageUploadNote = 'maks. 2 MB';

/// Membaca byte dari file `XFile` dan memvalidasi apakah ukurannya melebihi `maxImageUploadBytes`.
/// Melempar `ApiException` jika ukuran berkas melebihi batas yang ditentukan.
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