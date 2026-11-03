import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'api_client.dart';
import 'notification_service.dart';

Future<bool> saveApiFile({
  required ApiClient api,
  required String path,
  required String fileName,
  Map<String, dynamic>? query,
}) async {
  try {
    final bytes = await api.getBytes(path, query: query);
    Directory? dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        dir = await getExternalStorageDirectory();
      }
    } else {
      dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    }
    if (dir == null) return false;
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await NotificationService().showDownloadNotification(fileName: fileName);
    return true;
  } catch (_) {
    return false;
  }
}
