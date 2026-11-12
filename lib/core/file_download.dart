import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'api_client.dart';
import 'notification_service.dart';

/// Mengunduh file dari server API melalui `ApiClient` dan menyimpannya secara lokal
/// ke direktori unduhan perangkat (folder Download publik untuk Android atau direktori dokumen untuk platform lain).
/// Otomatis memicu notifikasi sukses unduhan setelah file berhasil disimpan.
Future<bool> saveApiFile({
  required ApiClient api,
  required String path,
  required String fileName,
  Map<String, dynamic>? query,
}) async {
  try {
    // Mengambil byte file dari server
    final bytes = await api.getBytes(path, query: query);
    Directory? dir;
    if (Platform.isAndroid) {
      // Mengarahkan ke folder Download standar Android
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        dir = await getExternalStorageDirectory();
      }
    } else {
      dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    }
    if (dir == null) return false;
    // Menulis file ke disk
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    // Memunculkan notifikasi sukses unduhan
    await NotificationService().showDownloadNotification(fileName: fileName);
    return true;
  } catch (_) {
    return false;
  }
}
