import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'api_client.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => const TokenStorage(),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokenStorage: ref.watch(tokenStorageProvider)),
);

enum AuthStatus { unknown, authenticated, unauthenticated, sessionUnavailable }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? token;
  final bool loading;
  final String? loginError;
  final String? sessionError;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.token,
    this.loading = false,
    this.loginError,
    this.sessionError,
  });

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? token,
    bool? loading,
    String? loginError,
    String? sessionError,
    bool clearError = false,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    token: token ?? this.token,
    loading: loading ?? this.loading,
    loginError: clearError ? null : (loginError ?? this.loginError),
    sessionError: sessionError ?? this.sessionError,
  );
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restoreSession();
    return const AuthState();
  }

  Future<void> _restoreSession() async {
    state = const AuthState(status: AuthStatus.unknown);
    final api = ref.read(apiClientProvider);
    final storage = ref.read(tokenStorageProvider);
    try {
      final token = await storage.read();
      if (token == null || token.isEmpty) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      final res = await api
          .get('/auth/me')
          .timeout(
            const Duration(seconds: 70),
            onTimeout: () =>
                throw const ApiException(message: 'Timeout koneksi server.'),
          );
      final user = AuthUser.fromJson(
        res['data'] is Map
            ? ((res['data'] as Map)['user'] is Map
                ? (res['data'] as Map)['user'] as Map<String, dynamic>
                : (res['data'] as Map) as Map<String, dynamic>)
            : (res['user'] is Map ? res['user'] as Map<String, dynamic> : res),
      );
      if (user.role != 'siswa') {
        try {
          await api.post('/auth/logout');
        } catch (_) {}
        await api.clearToken();
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        token: token,
      );
      ref.read(selectedSiswaEkskulProvider.notifier).clear();
    } catch (error) {
      // Hanya token yang ditolak server (401) yang dianggap kedaluwarsa.
      // Gangguan jaringan dan timeout tidak boleh menghapus sesi lokal.
      if (error is ApiException && error.isUnauthorized) {
        try {
          await api.clearToken();
        } catch (_) {}
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      state = AuthState(
        status: AuthStatus.sessionUnavailable,
        sessionError: error is ApiException
            ? error.message
            : 'Tidak dapat memeriksa sesi. Periksa koneksi lalu coba lagi.',
      );
    }
  }

  Future<void> refreshSession() => _restoreSession();

  Future<void> login(String identifier, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post(
        '/auth/login',
        data: {'identifier': identifier, 'password': password},
      );
      final data = res['data'] is Map ? res['data'] as Map<String, dynamic> : res;
      final token = data['token'] as String;
      final user = AuthUser.fromJson(
        data['user'] is Map ? data['user'] as Map<String, dynamic> : data,
      );
      if (user.role != 'siswa') {
        api.setToken(token);
        await api.post('/auth/logout');
        await api.clearToken();
        throw const ApiException(
          message: 'Aplikasi ini hanya mendukung akun Siswa dan Ketua Ekskul.',
        );
      }

      await ref.read(tokenStorageProvider).write(token);
      api.setToken(token);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        token: token,
      );
      ref.read(selectedSiswaEkskulProvider.notifier).clear();
    } catch (e) {
      final msg = e is ApiException ? e.message : 'Login gagal. Coba lagi.';
      state = state.copyWith(loading: false, loginError: msg);
    }
  }

  Future<void> logout() async {
    final api = ref.read(apiClientProvider);
    try {
      await api.post('/auth/logout');
    } catch (_) {}
    await api.clearToken();
    ref.read(selectedSiswaEkskulProvider.notifier).clear();
    ref.read(shellTabProvider.notifier).set(0);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearLoginError() => state = state.copyWith(clearError: true);
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

final selectedSiswaEkskulProvider =
    NotifierProvider<_SelectedSiswaEkskul, int?>(_SelectedSiswaEkskul.new);

class _SelectedSiswaEkskul extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int id) => state = id;

  void clear() => state = null;
}

class _ShellTab extends Notifier<int> {
  @override
  int build() => 0;

  void set(int value) => state = value;
}

final shellTabProvider = NotifierProvider<_ShellTab, int>(_ShellTab.new);
