import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class AppConfig {
  static const _defined = String.fromEnvironment('API_BASE_URL');

  // Base host Laravel yang dapat diakses dari perangkat.
  static const _localNetworkHost = 'http://192.168.95.61:8000';

  static const appName = 'SOUL';
  static const brandBlue = 0xFF2563EB;
  static const brandBlueDark = 0xFF1D4ED8;
  static const brandBg = 0xFFE0F2FE;

  static String get apiBaseUrl {
    final host = _defined.isNotEmpty
        ? _defined
        : _localNetworkHost.isNotEmpty
        ? _localNetworkHost
        : (!kIsWeb && Platform.isAndroid)
        ? 'http://10.0.2.2:8000'
        : 'http://localhost:8000';
    final clean = host.replaceAll(RegExp(r'/+$'), '');
    if (clean.endsWith('/api')) return clean;
    return '$clean/api';
  }

  static String imageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (!url.startsWith('http')) return '$apiBaseUrl$url';
    final host = Uri.parse(apiBaseUrl).host;
    final u = Uri.parse(url);
    if (u.host == 'localhost' || u.host == '127.0.0.1') {
      return u
          .replace(
            scheme: Uri.parse(apiBaseUrl).scheme,
            host: host,
            port: Uri.parse(apiBaseUrl).port,
          )
          .toString();
    }
    return url;
  }
}
