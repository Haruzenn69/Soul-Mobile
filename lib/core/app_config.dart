import 'package:flutter/foundation.dart';

/// Konfigurasi global aplikasi termasuk endpoint API, konstanta warna brand,
/// validasi URL API (mendukung HTTPS dan HTTP khusus lokal), serta helper pemformatan URL gambar.
class AppConfig {
  /// Mengambil environment variable 'API_BASE_URL' yang disuplai saat build (--dart-define)
  static const _defined = String.fromEnvironment('API_BASE_URL');

  static const appName = 'Soul';
  static const brandBlue = 0xFF2563EB;
  static const brandBlueDark = 0xFF1D4ED8;
  static const brandBg = 0xFFE0F2FE;

  /// Mendapatkan Base URL API yang telah divalidasi keamanannya (harus HTTPS kecuali localhost saat debug)
  static String get apiBaseUrl {
    if (_defined.isEmpty) {
      throw StateError('Set API_BASE_URL to an HTTPS endpoint.');
    }
    // Menghapus trailing slash
    final clean = _defined.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(clean);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
      throw StateError('API_BASE_URL must be an absolute URL with a host.');
    }
    // Validasi protokol HTTPS (HTTP hanya diizinkan untuk local debug)
    if (uri.scheme != 'https' &&
        !(kDebugMode && uri.scheme == 'http' && _isLocalHost(uri.host))) {
      throw StateError(
        'API_BASE_URL must use HTTPS; HTTP is allowed only for local debug.',
      );
    }
    return clean.endsWith('/api') ? clean : '$clean/api';
  }

  /// Helper untuk memformat URL gambar agar selalu valid dan sesuai dengan server backend
  static String imageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    // Menyesuaikan URL localhost/emulator dengan base URL aktif
    if (url.startsWith('http://localhost') ||
        url.startsWith('http://127.0.0.1') ||
        url.startsWith('http://10.0.2.2')) {
      final u = Uri.parse(url);
      final baseUri = Uri.parse(apiBaseUrl);
      final replaced = u.replace(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: baseUri.port,
      );
      return replaced.toString();
    }
    // Jika URL relatif, gabungkan dengan base URL server
    if (!url.startsWith('http')) {
      final cleanBase = apiBaseUrl.endsWith('/api')
          ? apiBaseUrl.substring(0, apiBaseUrl.length - 4)
          : apiBaseUrl;
      return url.startsWith('/') ? '$cleanBase$url' : '$cleanBase/$url';
    }
    final uri = Uri.tryParse(url);
    if (uri != null && uri.scheme == 'http') {
      if (_isLocalHost(uri.host)) {
        final baseUri = Uri.parse(apiBaseUrl);
        final replaced = uri.replace(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.port,
        );
        return replaced.toString();
      }
      throw StateError('Remote HTTP image URLs are not allowed.');
    }
    return url;
  }

  /// Mengecek apakah suatu host termasuk alamat lokal (localhost, IP lokal, atau private subnet)
  static bool _isLocalHost(String host) {
    final normalizedHost = host.toLowerCase();
    if (normalizedHost == 'localhost' ||
        normalizedHost == '127.0.0.1' ||
        normalizedHost == '::1' ||
        normalizedHost == '10.0.2.2') {
      return true;
    }

    final octets = normalizedHost.split('.');
    if (octets.length != 4) return false;
    final parts = octets.map(int.tryParse).toList();
    if (parts.any((part) => part == null || part < 0 || part > 255)) {
      return false;
    }
    final first = parts[0]!;
    final second = parts[1]!;
    return first == 10 ||
        first == 192 && second == 168 ||
        first == 172 && second >= 16 && second <= 31;
  }
}
