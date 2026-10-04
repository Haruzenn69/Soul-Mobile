import 'package:dio/dio.dart';

import 'dart:typed_data';

import 'app_config.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException({this.statusCode, required this.message});

  bool get isUnauthorized => statusCode == 401;

  bool get isForbidden => statusCode == 403;

  bool get isValidation => statusCode == 422;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this._tokenStorage}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  final TokenStorage _tokenStorage;
  late final Dio _dio;

  String? _token;

  bool get hasToken => _token != null;

  /// Keep the in-memory token synchronized with secure storage after login.
  /// Without this, switching accounts can keep using the previous token.
  void setToken(String token) => _token = token;

  /// Clear both the in-memory token and the persisted token.
  Future<void> clearToken() async {
    _token = null;
    await _tokenStorage.clear();
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    _token ??= await _tokenStorage.read();
    if (_token != null) {
      options.headers['Authorization'] = 'Bearer $_token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    if (status == 401 && _token != null) {
      final expired = err.requestOptions.path.contains('/auth/login') == false;
      if (expired) {
        await clearToken();
      }
    }

    String message = 'Terjadi kesalahan jaringan. Periksa koneksimu.';

    final data = err.response?.data;
    if (data is Map && data['message'] != null) {
      message = data['message'].toString();
    } else if (err.response?.data is String &&
        (err.response?.data as String).isNotEmpty) {
      message = err.response!.data as String;
    } else if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout) {
      message = 'Tidak dapat terhubung ke server. Coba lagi.';
    } else if (err.type == DioExceptionType.badResponse) {
      message = status == 500
          ? 'Terjadi kesalahan pada server. Coba lagi.'
          : 'Permintaan gagal (${status ?? '-'}).';
    }

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: ApiException(statusCode: status, message: message),
      ),
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    return _unwrap(
      await _guard(
        () => _dio.get(
          path,
          queryParameters: query,
          options: _noContentAsNullOptions,
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    return _unwrap(
      await _guard(
        () => _dio.post(
          path,
          data: data,
          queryParameters: query,
          options: _noContentAsNullOptions,
        ),
      ),
    );
  }

  Future<Uint8List> getBytes(String path, {Map<String, dynamic>? query}) async {
    final response = await _guard(
      () => _dio.get<List<int>>(
        path,
        queryParameters: query,
        options: Options(responseType: ResponseType.bytes),
      ),
    );
    final data = response.data;
    if (data is List<int>) return Uint8List.fromList(data);
    throw const ApiException(message: 'File dari server tidak valid.');
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, dynamic> fields,
    List<MultipartFile> files = const [],
    List<String> fileKeys = const [],
  }) async {
    final form = FormData();
    fields.forEach((k, v) {
      if (v != null) form.fields.add(MapEntry(k, v.toString()));
    });
    for (var i = 0; i < files.length; i++) {
      final key = i < fileKeys.length ? fileKeys[i] : 'file-$i';
      form.files.add(MapEntry(key, files[i]));
    }
    return _unwrap(await _guard(() => _dio.post(path, data: form)));
  }

  Future<Map<String, dynamic>> delete(String path) async {
    return _unwrap(await _guard(() => _dio.delete(path)));
  }

  Future<Response<dynamic>> _guard(
    Future<Response<dynamic>> Function() run,
  ) async {
    try {
      return await run();
    } on DioException catch (e) {
      final api = e.error;
      if (api is ApiException) throw api;
      throw ApiException(
        statusCode: e.response?.statusCode,
        message:
            e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.connectionTimeout
            ? 'Tidak dapat terhubung ke server. Coba lagi.'
            : 'Terjadi kesalahan jaringan. Periksa koneksimu.',
      );
    }
  }

  Options get _noContentAsNullOptions => Options();

  Map<String, dynamic> _unwrap(Response<dynamic> res) {
    final body = res.data;
    if (body is! Map) return {};
    return Map<String, dynamic>.from(body);
  }
}
