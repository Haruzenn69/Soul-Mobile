import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      const settings = InitializationSettings(android: android, iOS: ios);
      await _plugin.initialize(settings);
      _initialized = true;
      await requestPermission();
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> requestPermission() async {
    try {
      await Permission.notification.request();
    } catch (_) {}
  }

  Future<void> showDownloadNotification({required String fileName}) async {
    try {
      await init();
      if (!_initialized) return;
      const androidDetails = AndroidNotificationDetails(
        'download_channel',
        'Download',
        channelDescription: 'Notifikasi unduhan file',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const details = NotificationDetails(android: androidDetails);
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'Unduhan selesai',
        'File $fileName berhasil disimpan di folder Download',
        details,
      );
    } catch (_) {}
  }

  Future<void> showUpdateNotification({required String title, required String body}) async {
    try {
      await init();
      if (!_initialized) return;
      const androidDetails = AndroidNotificationDetails(
        'update_channel',
        'Pembaruan',
        channelDescription: 'Notifikasi pembaruan aplikasi',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const details = NotificationDetails(android: androidDetails);
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1,
        title,
        body,
        details,
      );
    } catch (_) {}
  }
}
