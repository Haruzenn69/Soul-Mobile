import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soul/core/api_client.dart';
import 'package:soul/core/providers.dart';
import 'package:soul/core/token_storage.dart';
import 'package:soul/data/providers.dart';
import 'package:soul/main.dart';
import 'package:soul/models/models.dart';
import 'package:soul/screens/katalog/katalog_screen.dart';
import 'package:soul/screens/kegiatan/kegiatan_detail_screen.dart';
import 'package:soul/screens/kegiatan/kegiatan_screen.dart';
import 'package:soul/screens/kegiatan/presensi_input_screen.dart';
import 'package:soul/screens/anggota/anggota_screen.dart';
import 'package:soul/screens/anggota/tambah_anggota_screen.dart';
import 'package:soul/screens/aktivitas/siswa_aktivitas_screen.dart';
import 'package:soul/screens/auth_gate.dart';
import 'package:soul/screens/beranda/ketua_beranda.dart';
import 'package:soul/screens/laporan/laporan_create_screen.dart';
import 'package:soul/screens/laporan/laporan_detail_screen.dart';
import 'package:soul/screens/laporan/laporan_screen.dart';
import 'package:soul/screens/login_screen.dart';
import 'package:soul/screens/main_shell.dart';
import 'package:soul/screens/menu/ketua_menu_screen.dart';
import 'package:soul/screens/notifikasi/notifikasi_screen.dart';
import 'package:soul/screens/profil/profil_screen.dart';
import 'package:soul/theme/app_theme.dart';
import 'package:soul/theme/theme_controller.dart';
import 'package:soul/widgets/common.dart';

class _TestAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

class _LoginErrorAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.unauthenticated,
    loginError: 'Server tidak tersedia.',
  );
}

class _IncompleteProfileAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    user: AuthUser(
      id: 9,
      username: 'incomplete',
      email: 'incomplete@example.test',
      role: 'siswa',
      needsOnboarding: false,
      needsProfileCompletion: true,
    ),
  );
}

class _FirstLoginAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    user: AuthUser(
      id: 10,
      username: 'student',
      email: 'student@example.test',
      role: 'siswa',
      needsOnboarding: true,
      needsProfileCompletion: false,
    ),
  );
}

class _MemoryThemeController extends ThemeModeController {
  @override
  ThemeMode build() => ThemeMode.light;

  @override
  Future<void> setDarkMode(bool enabled) async {
    state = enabled ? ThemeMode.dark : ThemeMode.light;
  }
}

void _ignoreFilter(String _) {}

void _ignoreInt(int _) {}

class _DirectMembershipApiClient extends ApiClient {
  _DirectMembershipApiClient() : super(tokenStorage: const TokenStorage());

  final List<String> requestedPaths = [];
  final List<Map<String, dynamic>> getQueries = [];
  Map<String, dynamic>? submittedData;
  Completer<Map<String, dynamic>>? pendingPageTwo;
  bool paginate = false;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    requestedPaths.add(path);
    if (path == '/siswa/kelas') {
      return {
        'data': {
          'kelas': [
            {'id': 5, 'nama': 'XI IPA 1'},
          ],
        },
      };
    }
    final requestQuery = Map<String, dynamic>.from(query ?? {});
    getQueries.add(requestQuery);
    if (requestQuery['page'] == 2 && pendingPageTwo != null) {
      return pendingPageTwo!.future;
    }
    final isSearch = requestQuery['q'] != null;
    return {
      'data': {
        'items': isSearch
            ? [
                {
                  'id': 44,
                  'nama': 'Hasil Cari',
                  'nis': '3456789012',
                  'kelas': 'XI IPA 3',
                  'sudah_aktif': false,
                },
              ]
            : [
                {
                  'id': 42,
                  'nama': 'Calon Anggota',
                  'nis': '1234567890',
                  'kelas': 'XI IPA 1',
                  'sudah_aktif': false,
                },
                {
                  'id': 43,
                  'nama': 'Sudah Aktif',
                  'nis': '2345678901',
                  'kelas': 'XI IPA 2',
                  'sudah_aktif': true,
                },
              ],
        'current_page': 1,
        'last_page': paginate && !isSearch ? 2 : 1,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    requestedPaths.add(path);
    submittedData = Map<String, dynamic>.from(data! as Map);
    return {'message': 'Berhasil menambahkan 1 siswa ke ekstrakurikuler.'};
  }
}

class _PagedKetuaListApiClient extends ApiClient {
  _PagedKetuaListApiClient() : super(tokenStorage: const TokenStorage());

  final List<(String, int, int)> requestedPages = [];

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final page = query?['page'] as int? ?? 1;
    requestedPages.add((path, page, query?['per_page'] as int? ?? 0));
    final collectionKey = path == '/ketua/anggota' ? 'anggotas' : 'kegiatans';
    final count = page == 1 ? 10 : 2;

    return {
      'data': {
        collectionKey: List.generate(
          count,
          (index) => {'id': ((page - 1) * 10) + index + 1},
        ),
        'pagination': {'current': page, 'last': 2, 'per_page': 100},
      },
    };
  }
}

class _SiswaDashboardApiClient extends ApiClient {
  _SiswaDashboardApiClient() : super(tokenStorage: const TokenStorage());

  Map<String, dynamic>? requestedQuery;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    requestedQuery = query;
    return {'data': {}};
  }
}

void main() {
  test('ketua list providers load every API page', () async {
    final api = _PagedKetuaListApiClient();
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);

    final members = await container.read(ketuaAnggotaProvider.future);
    final activities = await container.read(ketuaKegiatanProvider.future);

    expect(members['anggotas'], hasLength(12));
    expect(activities['kegiatans'], hasLength(12));
    expect(api.requestedPages, [
      ('/ketua/anggota', 1, 100),
      ('/ketua/anggota', 2, 100),
      ('/ketua/kegiatan', 1, 100),
      ('/ketua/kegiatan', 2, 100),
    ]);
  });

  test('student dashboard requests the selected extracurricular', () async {
    final api = _SiswaDashboardApiClient();
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    container.read(selectedSiswaEkskulProvider.notifier).select(42);

    await container.read(siswaDashboardProvider.future);

    expect(api.requestedQuery, {'ekskul_id': 42});
  });

  testWidgets('dashboard switch changes the global navigation shell', (
    tester,
  ) async {
    final user = AuthUser.fromJson({
      'id': 1,
      'username': 'siswa-ketua',
      'email': 'ketua@example.test',
      'role': 'siswa',
      'siswa': {
        'id': 10,
        'nama': 'Siswa Ketua',
        'nis': '1234567890',
        'jabatan': 'ketua',
        'is_ketua': true,
        'is_profile_complete': true,
      },
      'aktiv_ekskul': {'id': 2, 'nama_ekskul': 'Paskibra', 'status': true},
      'active_ekskuls': [
        {'id': 1, 'nama_ekskul': 'Basket', 'status': true},
        {'id': 2, 'nama_ekskul': 'Paskibra', 'status': true},
      ],
      'ketua_ekskul_id': 2,
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifikasiProvider.overrideWith((ref) async => {}),
          siswaDashboardProvider.overrideWith((ref) async => {}),
          ketuaDashboardProvider.overrideWith((ref) async => {}),
        ],
        child: MaterialApp(home: MainShell(user: user)),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    List<String> navigationLabels() => tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .map((destination) => destination.label)
        .toList();

    expect(navigationLabels(), contains('Ekskul'));
    expect(find.text('Dashboard · Basket'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dashboard-ekskul-switcher')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final selectedMenuItem = find.ancestor(
      of: find.byIcon(Icons.radio_button_checked_rounded),
      matching: find.byType(PopupMenuItem<int>),
    );
    final ketuaMenuItem = find.ancestor(
      of: find.text('Ketua'),
      matching: find.byType(PopupMenuItem<int>),
    );
    expect(
      find.descendant(of: selectedMenuItem, matching: find.text('Basket')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: ketuaMenuItem, matching: find.text('Paskibra')),
      findsOneWidget,
    );
    await tester.tap(find.text('Paskibra').last);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(navigationLabels(), contains('Anggota'));
    expect(navigationLabels(), isNot(contains('Ekskul')));
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    expect(find.byType(BerandaKetua), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('ketua-dashboard-hero')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-ekskul-switcher')),
      findsOneWidget,
    );
    expect(find.text('Dashboard · Paskibra'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dashboard-ekskul-switcher')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Basket').last);
    await tester.pump(const Duration(seconds: 1));

    expect(navigationLabels(), contains('Ekskul'));
    expect(find.text('Dashboard · Basket'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('app themes use the shared Laravel palette', () {
    expect(AppTheme.blue, const Color(0xFF2563EB));
    expect(AppTheme.blueDark, const Color(0xFF1D4ED8));
    expect(AppTheme.yellow, const Color(0xFFFACC15));
    expect(AppTheme.ink, const Color(0xFF0F172A));
    expect(AppTheme.canvas, const Color(0xFFF8FAFC));
    expect(AppTheme.line, const Color(0xFFE3EAF4));
    expect(AppTheme.lightSurfaceVariant, const Color(0xFFF1F5FB));
    expect(AppTheme.lightAccentSurface, const Color(0xFFEDF4FF));
    expect(AppTheme.darkCanvas, const Color(0xFF171717));
    expect(AppTheme.darkSurface, const Color(0xFF24262B));
    expect(AppTheme.darkSurfaceVariant, const Color(0xFF2C3038));
    expect(AppTheme.darkLine, const Color(0xFF3B414A));
    expect(AppTheme.darkSub, const Color(0xFFA6AFBD));
    expect(
      AppTheme.light().colorScheme.surfaceContainerHighest,
      AppTheme.lightSurfaceVariant,
    );
    expect(
      AppTheme.dark().colorScheme.surfaceContainerHighest,
      AppTheme.darkSurfaceVariant,
    );
  });

  testWidgets('shared widgets use dark theme surfaces and text colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Column(
            children: [
              ActiveEkskulSelector(
                ekskuls: const [
                  {'id': 11, 'nama_ekskul': 'Basket'},
                  {'id': 12, 'nama_ekskul': 'Futsal'},
                ],
                selectedId: 11,
                onChanged: _ignoreInt,
              ),
              const PageHeader(title: 'Dark dashboard'),
              const StatCard(label: 'Hadir', value: '8'),
              const StatusFilterChips(
                items: [StatusFilter('all', 'Semua', 8)],
                selected: 'none',
                onSelected: _ignoreFilter,
              ),
            ],
          ),
        ),
      ),
    );

    final cardContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(StatCard),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      (cardContainer.decoration! as BoxDecoration).color,
      AppTheme.darkSurface,
    );
    expect(
      tester.widget<Text>(find.text('Dark dashboard')).style!.color,
      AppTheme.dark().colorScheme.onSurface,
    );

    final filterContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(const ValueKey('status-chip-all')),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      (filterContainer.decoration! as BoxDecoration).color,
      AppTheme.darkSurface,
    );
    expect(find.text('Pilih ekskul'), findsOneWidget);
    expect(find.text('Menampilkan data Basket'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('brand hero gradient tones down in dark mode', (tester) async {
    List<Color>? gradientColors;
    Widget captureGradient(ThemeData theme) => MaterialApp(
      home: Theme(
        data: theme,
        child: Builder(
          builder: (context) {
            gradientColors = AppTheme.brandHeroGradient(context).colors;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pumpWidget(captureGradient(AppTheme.light()));
    final lightColors = gradientColors;
    await tester.pumpWidget(captureGradient(AppTheme.dark()));
    final darkColors = gradientColors;

    expect(lightColors, isNotNull);
    expect(darkColors, isNotNull);
    expect(darkColors, isNot(equals(lightColors)));
    expect(darkColors!.first, const Color(0xFF17283D));
    expect(darkColors.last, const Color(0xFF1D4ED8));
  });

  testWidgets('app boots and shows splash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SoulApp()));
    await tester.pump();
    expect(find.text('SOUL'), findsOneWidget);
  });

  testWidgets('profile settings can switch to dark mode', (tester) async {
    final container = ProviderContainer(
      overrides: [themeModeProvider.overrideWith(_MemoryThemeController.new)],
    );
    addTearDown(container.dispose);
    const user = AuthUser(
      id: 1,
      username: 'student',
      email: 'student@example.test',
      role: 'siswa',
      needsOnboarding: false,
      needsProfileCompletion: false,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: ProfilScreen(user: user)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    final modeSwitch = tester.widget<Switch>(find.byType(Switch));
    expect(modeSwitch.value, isFalse);
    final modeTitle = tester.widget<Text>(find.text('Mode gelap'));
    final modeSubtitle = tester.widget<Text>(
      find.text('Gunakan tampilan gelap aplikasi.'),
    );
    expect(modeTitle.style?.fontFamily, startsWith('PlusJakartaSans'));
    expect(modeTitle.style?.fontWeight, FontWeight.w800);
    expect(modeTitle.style?.fontSize, 14);
    expect(modeSubtitle.style?.fontFamily, startsWith('PlusJakartaSans'));
    expect(modeSubtitle.style?.fontSize, 11);
    expect(
      tester.getTopLeft(find.text('Mode gelap')).dx,
      tester.getTopLeft(find.text('Edit Profil')).dx,
    );
    expect(
      tester.getTopLeft(find.text('Gunakan tampilan gelap aplikasi.')).dx,
      tester.getTopLeft(find.text('Perbarui data pribadimu.')).dx,
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exit request action is only shown to regular students', (
    tester,
  ) async {
    const studentRecord = Siswa(
      id: 7,
      nama: 'Ketua Uji',
      nis: '123',
      jenisKelamin: 'laki-laki',
      jabatan: 'ketua',
      isKetua: true,
      isProfileComplete: true,
    );
    const ketua = AuthUser(
      id: 7,
      username: 'ketua',
      email: 'ketua@example.test',
      role: 'siswa',
      needsOnboarding: false,
      needsProfileCompletion: false,
      siswa: studentRecord,
    );
    const student = AuthUser(
      id: 8,
      username: 'siswa',
      email: 'siswa@example.test',
      role: 'siswa',
      needsOnboarding: false,
      needsProfileCompletion: false,
      siswa: Siswa(
        id: 8,
        nama: 'Siswa Uji',
        nis: '456',
        jenisKelamin: 'perempuan',
        jabatan: 'siswa',
        isKetua: false,
        isProfileComplete: true,
      ),
    );
    final container = ProviderContainer(
      overrides: [themeModeProvider.overrideWith(_MemoryThemeController.new)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: ProfilScreen(user: ketua)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pengajuan Keluar'), findsNothing);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: ProfilScreen(user: student)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('Pengajuan Keluar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('theme preference defaults to light mode', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  testWidgets('login screen scrolls without overflow with keyboard open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_TestAuthController.new),
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: const LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Log In Akun'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Log In Akun')).style?.fontFamily,
      startsWith('PlusJakartaSans'),
    );
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      AppTheme.darkCanvas,
    );
    final formSurface = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Log In Akun'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(formSurface.color, AppTheme.darkCanvas);
    expect(find.textContaining('Password default'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login error banner uses dark semantic colors', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_LoginErrorAuthController.new),
        ],
        child: MaterialApp(theme: AppTheme.dark(), home: const LoginScreen()),
      ),
    );

    final banner = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Server tidak tersedia.'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      (banner.decoration! as BoxDecoration).color,
      AppTheme.dangerSurface(
        tester.element(find.text('Server tidak tersedia.')),
      ),
    );
    expect(
      (banner.decoration! as BoxDecoration).color,
      isNot(const Color(0xFFFFF1F2)),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('incomplete profile prompt can be skipped after login', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            _IncompleteProfileAuthController.new,
          ),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Lengkapi data diri'), findsOneWidget);
    expect(find.text('Nanti saja'), findsOneWidget);

    await tester.tap(find.text('Nanti saja'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Lengkapi data diri'), findsNothing);
    expect(tester.widgetList(find.byType(NavigationBar)).isNotEmpty, true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first-login onboarding requires new credentials or logout', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FirstLoginAuthController.new),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Amankan akunmu'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('Simpan dan lanjutkan'), findsOneWidget);
    expect(find.text('Kembali ke login'), findsOneWidget);
    expect(find.text('Nanti saja'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Amankan akunmu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navbar builds a tab when selected after initial render', (
    tester,
  ) async {
    const user = AuthUser(
      id: 1,
      username: 'student',
      email: 'student@example.test',
      role: 'siswa',
      needsOnboarding: false,
      needsProfileCompletion: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_TestAuthController.new),
          siswaDashboardProvider.overrideWith((ref) async => {}),
          siswaPresensiProvider.overrideWith((ref, ekskulId) async => {}),
          katalogProvider.overrideWith((ref) async => {}),
        ],
        child: const MaterialApp(home: MainShell(user: user)),
      ),
    );
    await tester.pump();

    expect(find.byType(KatalogScreen), findsNothing);
    await tester.tap(find.text('Ekskul').last);
    await tester.pumpAndSettle();

    expect(find.byType(KatalogScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cached profile tab refreshes when session user changes', (
    tester,
  ) async {
    const user = AuthUser(
      id: 1,
      username: 'student-old',
      email: 'student@example.test',
      role: 'siswa',
      needsOnboarding: false,
      needsProfileCompletion: false,
    );
    const updatedUser = AuthUser(
      id: 1,
      username: 'student-new',
      email: 'student@example.test',
      role: 'siswa',
      needsOnboarding: false,
      needsProfileCompletion: false,
      foto: 'storage/profile/new-photo.jpg',
    );
    final container = ProviderContainer(
      overrides: [authControllerProvider.overrideWith(_TestAuthController.new)],
    );
    addTearDown(container.dispose);
    container.read(shellTabProvider.notifier).set(4);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MainShell(user: user)),
      ),
    );
    expect(find.text('student-old'), findsWidgets);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MainShell(user: updatedUser)),
      ),
    );
    expect(find.text('student-new'), findsWidgets);
    expect(find.text('student-old'), findsNothing);
  });

  testWidgets('ketua menu hero lightly blurs ekskul cover', (tester) async {
    const userWithoutCover = AuthUser(
      id: 1,
      username: 'ketua',
      email: 'ketua@example.test',
      role: 'siswa',
      needsOnboarding: false,
      needsProfileCompletion: false,
      aktivEkskul: Ekskul(
        id: 1,
        namaEkskul: 'Klub Teater',
        status: true,
        anggotaCount: 8,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ketuaProfilEkskulProvider.overrideWith(
            (ref) async => {
              'ekskul': {
                'id': 1,
                'nama_ekskul': 'Klub Teater',
                'cover': 'http://localhost:8000/storage/ekskul/cover.jpg',
                'status': true,
                'anggota_count': 8,
              },
            },
          ),
        ],
        child: const MaterialApp(home: KetuaMenuScreen(user: userWithoutCover)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate((widget) => widget is ImageFiltered),
      findsOneWidget,
    );
    expect(find.byType(Image), findsOneWidget);
    expect(
      tester.getSize(
        find.byKey(const ValueKey('ketua-menu-identity-background')),
      ),
      tester.getSize(find.byKey(const ValueKey('ketua-menu-identity-card'))),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ketuaProfilEkskulProvider.overrideWith(
            (ref) async => {
              'ekskul': {
                'id': 1,
                'nama_ekskul': 'Klub Teater',
                'is_open_recruitment': true,
                'status': true,
                'anggota_count': 8,
              },
            },
          ),
        ],
        child: const MaterialApp(home: KetuaMenuScreen(user: userWithoutCover)),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate((widget) => widget is ImageFiltered),
      findsNothing,
    );
    expect(find.text('Klub Teater'), findsOneWidget);
  });

  testWidgets('catalog filters activities by category', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const user = AuthUser(
      id: 1,
      username: 'student',
      email: 'student@example.test',
      role: 'siswa',
      needsOnboarding: false,
      needsProfileCompletion: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          katalogProvider.overrideWith(
            (ref) async => {
              'joinable': [
                {
                  'id': 1,
                  'nama_ekskul': 'Klub Teater',
                  'kategori': 'Seni',
                  'logo': 'storage/ekskul/teater.png',
                  'status': true,
                  'is_open_recruitment': true,
                  'anggota_count': 12,
                },
                {
                  'id': 2,
                  'nama_ekskul': 'Klub Bahasa',
                  'kategori': 'Bahasa',
                  'status': true,
                  'is_open_recruitment': true,
                  'anggota_count': 8,
                },
              ],
            },
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: KatalogScreen(user: user)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Klub Teater'), findsWidgets);
    expect(find.text('Klub Bahasa'), findsWidgets);
    expect(find.byType(Image), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Seni'));
    await tester.pumpAndSettle();

    expect(find.text('Klub Teater'), findsWidgets);
    expect(find.text('Klub Bahasa'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('auth user reads profile photo from nested student resource', () {
    final user = AuthUser.fromJson({
      'id': 1,
      'username': 'student',
      'role': 'siswa',
      'siswa': {
        'id': 10,
        'nama': 'Siswa Uji',
        'foto': 'http://localhost:8000/storage/profile-photos/photo.jpg',
      },
    });

    expect(
      user.fotoUrl,
      'http://localhost:8000/storage/profile-photos/photo.jpg',
    );
  });

  testWidgets(
    'student recap uses the server personal recap for selected month',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            siswaRekapMonthProvider((bulan: null, ekskulId: null)).overrideWith(
              (ref) async => {
                'bulan': '2026-10',
                'available_months': ['2026-10', '2026-09'],
                'rekap_siswa': {
                  'nama': 'Siswa Uji',
                  'kelas': 'X-1',
                  'hadir': 4,
                  'izin': 1,
                  'sakit': 0,
                  'alpha': 0,
                  'total': 5,
                  'persentase_kehadiran': 80,
                },
              },
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SiswaAktivitasScreen(initialTab: 1)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rekap'));
      await tester.pumpAndSettle();

      expect(find.text('Oktober 2026'), findsOneWidget);
      await tester.drag(find.byType(ListView).last, const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(find.text('Rekap Kehadiran Saya'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('student-recap-percentage')),
        findsOneWidget,
      );
      expect(find.textContaining('kegiatan pada periode'), findsNothing);
      expect(find.text('Hadir'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('student attendance shows colored history without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          siswaPresensiProvider(null).overrideWith(
            (ref) async => {
              'presensi': [
                {
                  'status': 'hadir',
                  'kegiatan': {
                    'materi': 'Latihan Futsal',
                    'tanggal_kegiatan': '2026-10-02',
                    'tanggal_text': '2 Oktober 2026',
                  },
                },
                {
                  'status': 'izin',
                  'kegiatan': {
                    'materi': 'Pertemuan Rutin',
                    'tanggal_kegiatan': '2026-10-01',
                    'tanggal_text': '1 Oktober 2026',
                  },
                },
              ],
            },
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SiswaAktivitasScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Riwayat Kegiatan (2)'), findsOneWidget);
    expect(find.text('Latihan Futsal'), findsOneWidget);
    expect(find.text('hadir'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('student activity follows the global club selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          siswaPresensiProvider.overrideWith((ref, ekskulId) async {
            final selectedId = ekskulId ?? 11;
            final name = selectedId == 11 ? 'Basket' : 'Futsal';
            return {
              'pendaftaran': {
                'ekskul': {'id': selectedId},
              },
              'active_ekskuls': [
                {'id': 11, 'nama_ekskul': 'Basket'},
                {'id': 12, 'nama_ekskul': 'Futsal'},
              ],
              'presensi': [
                {
                  'status': 'hadir',
                  'kegiatan': {
                    'materi': 'Latihan $name',
                    'tanggal_kegiatan': '2026-10-02',
                    'tanggal_text': '2 Oktober 2026',
                  },
                },
              ],
            };
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: SiswaAktivitasScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Latihan Basket'), findsOneWidget);
    expect(find.text('Pilih ekskul'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('student activity grade tab uses the full grade view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          siswaNilaiProvider(null).overrideWith(
            (ref) async => {
              'pendaftaran': {'id': 1},
              'ekskul': {'nama_ekskul': 'Klub Teater'},
              'periode': {'label': 'Semester 1 2026'},
              'penilaian': {
                'periode': 'Semester 1 2026',
                'total_pertemuan': 5,
                'total_hadir': 4,
                'total_izin': 1,
                'total_sakit': 0,
                'total_alpha': 0,
                'persentase_kehadiran': 80,
                'nilai_sikap': 90,
                'nilai_keaktifan': 92,
                'nilai_keterampilan': 94,
                'nilai_akhir': 92,
                'predikat': 'A',
                'catatan': 'Pertahankan semangat belajarmu.',
                'penilai': {'nama': 'Pembina'},
              },
            },
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SiswaAktivitasScreen(initialTab: 2)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NILAI AKHIR'), findsOneWidget);
    expect(find.text('92.00'), findsOneWidget);
    expect(find.text('Rincian Komponen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kegiatan detail renders data and attendance summary', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kegiatanDetailProvider(7).overrideWith(
            (ref) async => {
              'kegiatan': {
                'id': 7,
                'materi': 'Latihan Rutin',
                'tanggal_text': '2 Oktober 2026',
                'is_event': false,
              },
              'presensi': List.generate(
                8,
                (index) => {'nama': 'Siswa $index', 'status': 'hadir'},
              ),
              'rekap': {'hadir': 3, 'izin': 1, 'sakit': 0, 'alpha': 0},
            },
          ),
        ],
        child: const MaterialApp(home: KegiatanDetailScreen(kegiatanId: 7)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Edit Kegiatan'), findsOneWidget);
    expect(
      tester
          .widget<Icon>(
            find.descendant(
              of: find.byTooltip('Edit Kegiatan'),
              matching: find.byIcon(Icons.edit_outlined),
            ),
          )
          .icon,
      Icons.edit_outlined,
    );
    await tester.tap(find.byTooltip('Edit Kegiatan'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Kegiatan'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Ringkasan Kehadiran'), findsOneWidget);
    expect(find.text('Hadir'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    final statCards = tester.widgetList<StatCard>(find.byType(StatCard));
    expect(statCards, hasLength(4));
    expect(
      statCards.every((card) => card.icon != null && !card.compact),
      isTrue,
    );
    await tester.scrollUntilVisible(
      find.text('Siswa 0'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Siswa 0'), findsOneWidget);
    expect(find.text('Siswa 5'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Lihat semua 8 siswa'), findsOneWidget);
    await tester.tap(find.text('Lihat semua 8 siswa'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.text('Siswa 7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ketua member management keeps its three navigation tabs', (
    tester,
  ) async {
    const ketua = AuthUser(
      id: 1,
      username: 'ketua',
      email: 'ketua@example.test',
      role: 'ketua',
      needsOnboarding: false,
      needsProfileCompletion: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ketuaAnggotaProvider.overrideWith(
            (ref) async => {
              'anggotas': [
                {
                  'id': 1,
                  'status': 'diterima',
                  'status_label': 'Aktif',
                  'is_active': true,
                  'siswa': {
                    'id': 10,
                    'nama': 'Alya Anggota',
                    'foto': 'storage/profile-photos/alya.jpg',
                    'jabatan': 'anggota',
                  },
                  'jabatan_ekskul': 'sekretaris',
                },
                {
                  'id': 2,
                  'status': 'diterima',
                  'status_label': 'Aktif',
                  'is_active': true,
                  'siswa': {
                    'id': 11,
                    'nama': 'Bima Anggota',
                    'foto': 'storage/profile-photos/bima.jpg',
                    'jabatan': 'anggota',
                  },
                },
              ],
            },
          ),
          ketuaPendaftaranProvider.overrideWith(
            (ref, status) async => {'pendaftarans': []},
          ),
          ketuaPengajuanProvider.overrideWith(
            (ref, status) async => {'pengajuans': []},
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AnggotaScreen(user: ketua)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('anggota-pill-tabs')), findsOneWidget);
    expect(find.text('Kelola Anggota'), findsOneWidget);
    expect(find.text('Pendaftaran'), findsOneWidget);
    expect(find.text('Pengajuan'), findsOneWidget);
    expect(find.byKey(const ValueKey('open-add-members')), findsNothing);

    await tester.tap(find.text('Pendaftaran'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open-add-members')), findsOneWidget);
    expect(find.text('Tambah Anggota'), findsOneWidget);
    final addMembersFab = tester.widget<FloatingActionButton>(
      find.byKey(const ValueKey('open-add-members')),
    );
    expect(addMembersFab.backgroundColor, AppTheme.blue);
    expect(addMembersFab.foregroundColor, Colors.white);

    await tester.tap(find.text('Kelola Anggota'));
    await tester.pumpAndSettle();
    expect(find.text('Alya Anggota'), findsOneWidget);
    expect(find.text('Sekretaris'), findsOneWidget);
    expect(find.text('Anggota'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is PersonAvatar &&
            widget.photoUrl == 'storage/profile-photos/alya.jpg',
      ),
      findsWidgets,
    );
    await tester.enterText(
      find.byKey(const ValueKey('Cari nama anggota...')),
      'Bima',
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('Cari nama anggota...')))
          .controller!
          .text,
      'Bima',
    );
    expect(find.text('Bima Anggota'), findsOneWidget);
    expect(find.text('Alya Anggota'), findsNothing);

    await tester.tap(find.text('Pendaftaran'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open-add-members')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('Cari nama pendaftar...')),
      findsOneWidget,
    );

    await tester.tap(find.text('Pengajuan'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('Cari nama siswa...')), findsOneWidget);

    await tester.drag(find.byType(NestedScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('PENGELOLAAN EKSKUL'), findsNothing);
    expect(find.byKey(const ValueKey('anggota-tab-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('Cari nama siswa...')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ketua can select and add students directly', (tester) async {
    final api = _DirectMembershipApiClient();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(api)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                key: const ValueKey('open-add-students-test'),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const TambahAnggotaScreen(),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-add-students-test')));
    await tester.pumpAndSettle();

    expect(api.requestedPaths, contains('/ketua/anggota/calon-siswa'));
    expect(api.requestedPaths, contains('/siswa/kelas'));
    await tester.tap(find.byType(DropdownButtonFormField<int?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('XI IPA 1').last);
    await tester.pumpAndSettle();
    expect(api.getQueries.any((query) => query['kelas_id'] == 5), isTrue);
    expect(find.text('Calon Anggota'), findsOneWidget);
    expect(find.text('Sudah Aktif'), findsOneWidget);
    expect(find.text('Tambahkan 0 siswa'), findsOneWidget);
    await tester.tap(find.text('Calon Anggota'));
    await tester.pump();
    expect(find.text('Tambahkan 1 siswa'), findsOneWidget);
    expect(find.byType(InputChip), findsNothing);
    await tester.enterText(find.byType(TextField), 'hasil baru');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Hasil Cari'), findsOneWidget);
    expect(find.text('Tambahkan 1 siswa'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('submit-direct-members')));
    await tester.pumpAndSettle();

    expect(api.requestedPaths, contains('/ketua/anggota'));
    expect(api.submittedData, {
      'siswa_ids': [42],
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new search supersedes an in-flight next-page request', (
    tester,
  ) async {
    final api = _DirectMembershipApiClient()
      ..paginate = true
      ..pendingPageTwo = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(api)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                key: const ValueKey('open-add-students-race-test'),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const TambahAnggotaScreen(),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-add-students-race-test')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Berikutnya'));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'hasil baru');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(
      api.getQueries.any(
        (query) => query['q'] == 'hasil baru' && query['page'] == 1,
      ),
      isTrue,
    );
    expect(find.text('Hasil Cari'), findsOneWidget);
    api.pendingPageTwo!.complete({
      'data': {
        'items': [
          {
            'id': 45,
            'nama': 'Hasil Lama',
            'nis': '4567890123',
            'kelas': 'XI IPA 4',
            'sudah_aktif': false,
          },
        ],
        'current_page': 2,
        'last_page': 2,
      },
    });
    await tester.pumpAndSettle();

    expect(find.text('Hasil Lama'), findsNothing);
    expect(find.text('Hasil Cari'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leader dashboard shows four cards and complete hero', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const ketua = AuthUser(
      id: 1,
      username: 'ketua',
      email: 'ketua@example.test',
      role: 'siswa',
      needsOnboarding: false,
      needsProfileCompletion: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ketuaDashboardProvider.overrideWith(
            (ref) async => {
              'total_anggota': 4,
              'anggota_baru_bulan_ini': 1,
              'kegiatan_bulan_ini': 2,
              'testimoni_pending_count': 1,
              'faq_pending_count': 2,
              'ekskul': {'nama_ekskul': 'Karate'},
              'chart_kegiatan': {
                'labels': [],
                'hadir': [],
                'izin': [],
                'sakit': [],
                'alpha': [],
              },
              'chart_kelas': {'labels': [], 'data': []},
            },
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: BerandaKetua(user: ketua)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Anggota'), findsWidgets);
    expect(find.text('Anggota Baru'), findsOneWidget);
    expect(find.text('Kegiatan Bulan Ini'), findsOneWidget);
    expect(find.text('Moderasi'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('DASHBOARD KETUA'), findsOneWidget);
    expect(find.text('Memimpin Karate'), findsOneWidget);
    expect(find.text('Pengajuan Keluar'), findsNothing);
    final heroRect = tester.getRect(
      find.byKey(const ValueKey('ketua-dashboard-hero')),
    );
    final markRect = tester.getRect(
      find.byKey(const ValueKey('ketua-dashboard-hero-mark')),
    );
    expect(markRect.left, greaterThanOrEqualTo(heroRect.left));
    expect(markRect.top, greaterThanOrEqualTo(heroRect.top));
    expect(markRect.right, lessThanOrEqualTo(heroRect.right));
    expect(markRect.bottom, lessThanOrEqualTo(heroRect.bottom));
    final createActionRect = tester.getRect(
      find.byKey(const ValueKey('ketua-hero-create-action')),
    );
    final reviewActionRect = tester.getRect(
      find.byKey(const ValueKey('ketua-hero-add-members-action')),
    );
    expect(createActionRect.height, 42);
    expect(reviewActionRect.height, 42);
    expect(createActionRect.width, reviewActionRect.width);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2400));
    await tester.pumpAndSettle();
    for (final key in const [
      ValueKey('moderation-tile-testimoni'),
      ValueKey('moderation-tile-faq'),
      ValueKey('priority-review-tile'),
      ValueKey('quick-action-anggota'),
      ValueKey('quick-action-kegiatan'),
      ValueKey('quick-action-laporan bulanan'),
    ]) {
      final height = tester.getSize(find.byKey(key)).height;
      expect(height, inInclusiveRange(44, 64), reason: '$key height: $height');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('activity list provides clear search and no-result feedback', (
    tester,
  ) async {
    const ketua = AuthUser(
      id: 1,
      username: 'ketua',
      email: 'ketua@example.test',
      role: 'ketua',
      needsOnboarding: false,
      needsProfileCompletion: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ketuaKegiatanProvider.overrideWith(
            (ref) async => {
              'kegiatans': [
                {
                  'id': 1,
                  'materi': 'Latihan Rutin',
                  'tanggal_text': '2 Oktober 2026',
                  'presensis_count': 8,
                  'dokumentasi': 'storage/kegiatan/latihan-rutin.jpg',
                },
                {
                  'id': 2,
                  'materi':
                      'Persiapan Lomba Karate Tingkat Nasional Antar Sekolah',
                  'tanggal_text': '8 Oktober 2026',
                  'is_event': true,
                },
              ],
            },
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: KegiatanScreen(user: ketua)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    final fab = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(fab.backgroundColor, AppTheme.blue);
    expect(fab.shape, const CircleBorder());
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.text('Buat Kegiatan'), findsNothing);
    expect(find.text('2 kegiatan'), findsOneWidget);
    expect(find.text('Latihan Rutin'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('activity-documentation-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('activity-documentation-fallback')),
      findsOneWidget,
    );
    final eventBadgeRect = tester.getRect(
      find.byKey(const ValueKey('activity-event-badge-2')),
    );
    final eventTitleRect = tester.getRect(
      find.byKey(const ValueKey('activity-title-2')),
    );
    final eventChevronRect = tester.getRect(
      find.byKey(const ValueKey('activity-chevron-2')),
    );
    expect(eventBadgeRect.left - eventTitleRect.right, lessThanOrEqualTo(8));
    expect(eventBadgeRect.right, lessThan(eventChevronRect.left));
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'tidak ada');
    await tester.pumpAndSettle();
    expect(find.text('0 hasil pencarian'), findsOneWidget);
    expect(find.text('Kegiatan tidak ditemukan'), findsOneWidget);
    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.pumpAndSettle();
    expect(find.text('2 kegiatan'), findsOneWidget);
    await tester.drag(find.byType(NestedScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('AKTIVITAS EKSKUL'), findsNothing);
    expect(find.byKey(const ValueKey('kegiatan-tab-bar')), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'closing the create activity dialog does not reuse disposed fields',
    (tester) async {
      const ketua = AuthUser(
        id: 1,
        username: 'ketua',
        email: 'ketua@example.test',
        role: 'ketua',
        needsOnboarding: false,
        needsProfileCompletion: false,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ketuaKegiatanProvider.overrideWith(
              (ref) async => {'kegiatans': []},
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: KegiatanScreen(user: ketua)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Buat kegiatan'));
      await tester.pumpAndSettle();
      expect(find.text('Buat Kegiatan'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('attendance month filter stays visible while records scroll', (
    tester,
  ) async {
    const ketua = AuthUser(
      id: 1,
      username: 'ketua',
      email: 'ketua@example.test',
      role: 'ketua',
      needsOnboarding: false,
      needsProfileCompletion: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ketuaKegiatanProvider.overrideWith((ref) async => {'kegiatans': []}),
          ketuaLaporanProvider.overrideWith((ref) async => {}),
          ketuaRekapMonthProvider(null).overrideWith(
            (ref) async => {
              'bulan': '2026-10',
              'available_months': ['2026-10'],
              'rows': List.generate(
                16,
                (index) => {
                  'nama': 'Anggota $index',
                  'kelas': 'X-1',
                  'persentase_kehadiran': 75,
                  'hadir': 3,
                  'izin': 1,
                  'sakit': 0,
                  'alpha': 0,
                },
              ),
            },
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: KegiatanScreen(user: ketua)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rekap Kehadiran'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('rekap-period-tap')), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('rekap-period-tap')), findsOneWidget);
    expect(find.text('Oktober 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification card offers a confirmed delete action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notifikasiProvider.overrideWith(
            (ref) async => {
              'notifikasis': [
                {
                  'id': 7,
                  'judul': 'Pengumuman',
                  'pesan': 'Ada pembaruan untuk ekskul.',
                  'is_read': true,
                  'created_label': '11 Oktober 2026',
                },
              ],
            },
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: NotifikasiScreen(isKetua: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Hapus notifikasi'));
    await tester.pumpAndSettle();

    expect(find.text('Hapus notifikasi?'), findsOneWidget);
    expect(
      find.text('Notifikasi ini akan dihapus secara permanen.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Pengumuman'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('monthly report list highlights revision status', (tester) async {
    const ketua = AuthUser(
      id: 1,
      username: 'ketua',
      email: 'ketua@example.test',
      role: 'ketua',
      needsOnboarding: false,
      needsProfileCompletion: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ketuaLaporanProvider.overrideWith(
            (ref) async => {
              'laporans': [
                {
                  'id': 8,
                  'bulan': '2026-09',
                  'status': 'ditolak',
                  'ringkasan': 'Evaluasi perlu dilengkapi.',
                },
              ],
            },
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: LaporanScreen(user: ketua)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 laporan tersimpan'), findsNothing);
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('Perlu Revisi'), findsOneWidget);
    expect(find.text('Perlu diperbaiki dan dikirim ulang'), findsOneWidget);
    expect(find.text('Evaluasi perlu dilengkapi.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('monthly report creation opens a dedicated form', (tester) async {
    const ketua = AuthUser(
      id: 1,
      username: 'ketua',
      email: 'ketua@example.test',
      role: 'ketua',
      needsOnboarding: false,
      needsProfileCompletion: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ketuaLaporanProvider.overrideWith((ref) async => {'laporans': []}),
        ],
        child: const MaterialApp(
          home: Scaffold(body: LaporanScreen(user: ketua)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Buat laporan baru'));
    await tester.pumpAndSettle();

    expect(find.byType(LaporanCreateScreen), findsOneWidget);
    expect(find.text('Data otomatis'), findsOneWidget);
    expect(find.text('Tujuan Kegiatan'), findsOneWidget);
    expect(find.text('Evaluasi Keberhasilan'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('Evaluasi Kendala'), findsOneWidget);
    expect(find.text('Solusi / Tindak Lanjut'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing a monthly report opens populated edit form', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          laporanDetailProvider(42).overrideWith(
            (ref) async => {
              'laporan': {
                'id': 42,
                'bulan': '2026-09',
                'status': 'ditolak',
                'catatan_pembina': 'Mohon lengkapi evaluasi kegiatan.',
                'materi_kegiatan': 'Latihan rutin',
                'kehadiran': 'Hadir: 12',
                'tujuan': 'Tujuan lama',
                'evaluasi_keberhasilan': 'Capaian lama',
                'evaluasi_kendala': 'Kendala lama',
                'evaluasi_solusi': 'Solusi lama',
              },
            },
          ),
        ],
        child: const MaterialApp(home: LaporanDetailScreen(laporanId: 42)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('Perlu diperbaiki'), findsOneWidget);
    expect(find.text('Mohon lengkapi evaluasi kegiatan.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Materi Kegiatan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Materi Kegiatan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Rekap Kehadiran'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Rekap Kehadiran'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Evaluasi Keberhasilan'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Evaluasi Keberhasilan'), findsOneWidget);
    expect(find.text('Kirim Ulang ke Pembina'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit laporan'));
    await tester.pumpAndSettle();

    expect(find.byType(LaporanCreateScreen), findsOneWidget);
    expect(find.text('Edit Laporan Bulanan'), findsOneWidget);
    expect(find.textContaining('September 2026'), findsOneWidget);
    final loadedValues = <String>{};
    for (var i = 0; i < 4; i++) {
      loadedValues.addAll(
        tester
            .widgetList<TextField>(find.byType(TextField))
            .map((field) => field.controller!.text),
      );
      await tester.drag(find.byType(ListView).last, const Offset(0, -900));
      await tester.pumpAndSettle();
    }
    expect(
      loadedValues,
      containsAll([
        'Tujuan lama',
        'Capaian lama',
        'Kendala lama',
        'Solusi lama',
      ]),
    );
    expect(find.text('Simpan Perubahan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attendance input builds member rows lazily', (tester) async {
    final members = List.generate(
      300,
      (index) => {
        'id': index + 1,
        'status': 'aktif',
        'is_active': true,
        'siswa': {'nama': 'Member $index'},
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          presensiFormProvider(9)
              .overrideWith((ref) async => {'anggotas': members}),
        ],
        child: const MaterialApp(
          home: PresensiInputScreen(kegiatanId: 9, materi: 'Latihan'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pelatih belum ada di ekskul ini.'), findsOneWidget);
    expect(find.text('Member 0'), findsOneWidget);
    expect(find.text('Member 299'), findsNothing);
    await tester.enterText(find.byType(TextField).last, 'Member 299');
    await tester.pumpAndSettle();
    expect(find.text('Member 299'), findsNWidgets(2));
    expect(find.text('Member 0'), findsNothing);
    await tester.enterText(find.byType(TextField).last, '');
    await tester.pumpAndSettle();
    expect(find.text('Member 0'), findsOneWidget);

    await tester.tap(find.text('Hadir').first);
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsWidgets);
    await tester.tap(find.text('Alpha').first);
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);

    for (var i = 0; i < 20 && find.text('Member 299').evaluate().isEmpty; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
      await tester.pumpAndSettle();
    }
    expect(find.text('Member 299'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
