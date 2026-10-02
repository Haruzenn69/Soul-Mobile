import 'package:file_picker/file_picker.dart';

import 'api_client.dart';

Future<bool> saveApiFile({
  required ApiClient api,
  required String path,
  required String fileName,
  Map<String, dynamic>? query,
}) async {
  final extension = fileName.split('.').last;
  final bytes = await api.getBytes(path, query: query);
  final saved = await FilePicker.saveFile(
    dialogTitle: 'Simpan file',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: [extension],
    bytes: bytes,
    mimeType: extension == 'pdf'
        ? 'application/pdf'
        : 'application/octet-stream',
  );
  return saved != null;
}
