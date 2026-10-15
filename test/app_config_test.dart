import 'package:flutter_test/flutter_test.dart';
import 'package:soul/core/app_config.dart';

void main() {
  const configuredUrl = String.fromEnvironment('API_BASE_URL');

  test('API base URL includes the API path', () {
    final uri = Uri.parse(configuredUrl);
    expect(AppConfig.apiBaseUrl, '${uri.origin}/api');
  });

  test('localhost image URLs are rewritten to the configured API host', () {
    final uri = Uri.parse(configuredUrl);
    expect(
      AppConfig.imageUrl('http://localhost:8000/storage/cover.jpg'),
      '${uri.origin}/storage/cover.jpg',
    );
  });

  test('remote HTTP image URLs are rejected', () {
    expect(
      () => AppConfig.imageUrl('http://images.example.test/cover.jpg'),
      throwsStateError,
    );
  });
}
