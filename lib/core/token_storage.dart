import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Kelas utilitas untuk menyimpan, membaca, dan menghapus token autentikasi
/// secara aman menggunakan `FlutterSecureStorage` (enkripsi tingkat sistem perangkat).
class TokenStorage {
  static const _key = 'soul_auth_token';
  const TokenStorage();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Membaca token autentikasi yang tersimpan
  Future<String?> read() => _storage.read(key: _key);

  /// Menyimpan token autentikasi baru
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  /// Menghapus token autentikasi (proses logout)
  Future<void> clear() => _storage.delete(key: _key);
}