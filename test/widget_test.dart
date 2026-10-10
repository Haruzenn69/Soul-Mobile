import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soul/core/providers.dart';
import 'package:soul/data/providers.dart';
import 'package:soul/main.dart';
import 'package:soul/models/models.dart';
import 'package:soul/screens/katalog/katalog_screen.dart';
import 'package:soul/screens/kegiatan/kegiatan_detail_screen.dart';
import 'package:soul/screens/kegiatan/kegiatan_screen.dart';
import 'package:soul/screens/kegiatan/presensi_input_screen.dart';
import 'package:soul/screens/anggota/anggota_screen.dart';
import 'package:soul/screens/aktivitas/siswa_aktivitas_screen.dart';
import 'package:soul/screens/laporan/laporan_create_screen.dart';
import 'package:soul/screens/laporan/laporan_detail_screen.dart';
import 'package:soul/screens/laporan/laporan_screen.dart';
import 'package:soul/screens/login_screen.dart';
import 'package:soul/screens/main_shell.dart';
import 'package:soul/theme/app_theme.dart';
import 'package:soul/widgets/common.dart';

class _TestAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

void main() {
  testWidgets('app boots and shows splash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SoulApp()));
    await tester.pump();
    expect(find.text('SOUL'), findsOneWidget);
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
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Log In Akun'), findsOneWidget);
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
          siswaPresensiProvider.overrideWith((ref) async => {}),
          katalogProvider.overrideWith((ref) async => {}),
        ],
        child: const MaterialApp(home: MainShell(user: user)),
      ),
    );
    await tester.pump();

    expect(find.byType(KatalogScreen), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Ekskul'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(KatalogScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    await tester.tap(find.widgetWithText(ChoiceChip, 'Seni'));
    await tester.pumpAndSettle();

    expect(find.text('Klub Teater'), findsWidgets);
    expect(find.text('Klub Bahasa'), findsNothing);
    expect(tester.takeException(), isNull);
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
            siswaRekapMonthProvider(null).overrideWith(
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
          siswaPresensiProvider.overrideWith(
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
          siswaNilaiProvider.overrideWith(
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

    expect(find.text('Latihan Rutin'), findsOneWidget);
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

  testWidgets('member management tabs search by student name', (tester) async {
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
                  'siswa': {'id': 10, 'nama': 'Alya Anggota'},
                },
                {
                  'id': 2,
                  'status': 'diterima',
                  'status_label': 'Aktif',
                  'is_active': true,
                  'siswa': {'id': 11, 'nama': 'Bima Anggota'},
                },
              ],
            },
          ),
          ketuaPendaftaranProvider.overrideWith(
            (ref, status) async => {
              'pendaftarans': [
                {
                  'id': 3,
                  'status': 'pending',
                  'status_label': 'Pending',
                  'siswa': {'nama': 'Citra Pendaftar'},
                },
              ],
            },
          ),
          ketuaPengajuanProvider.overrideWith(
            (ref, status) async => {
              'pengajuans': [
                {
                  'id': 4,
                  'status': 'pending',
                  'nama': 'Danu Pengaju',
                  'alasan': 'Alasan',
                },
              ],
            },
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AnggotaScreen(user: ketua)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pill = tester.widget<Container>(
      find.byKey(const ValueKey('anggota-pill-tabs')),
    );
    expect(
      (pill.decoration! as BoxDecoration).borderRadius,
      BorderRadius.circular(28),
    );
    expect(pill.padding, const EdgeInsets.all(5));
    final tabs = tester.widget<TabBar>(
      find.byKey(const ValueKey('anggota-tab-bar')),
    );
    expect(tabs.indicatorSize, TabBarIndicatorSize.tab);
    expect(tabs.labelPadding, EdgeInsets.zero);
    expect(
      find.byWidgetPredicate((widget) => widget is Tab && widget.height == 30),
      findsNWidgets(3),
    );

    expect(find.text('Alya Anggota'), findsOneWidget);
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
    await tester.enterText(find.byType(TextField).first, 'Citra');
    await tester.pumpAndSettle();
    expect(find.text('Citra Pendaftar'), findsOneWidget);

    await tester.tap(find.text('Pengajuan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Danu');
    await tester.pumpAndSettle();
    expect(find.text('Danu Pengaju'), findsOneWidget);
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
                },
                {
                  'id': 2,
                  'materi': 'Persiapan Lomba',
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
    await tester.enterText(find.byType(TextField), 'tidak ada');
    await tester.pumpAndSettle();
    expect(find.text('0 hasil pencarian'), findsOneWidget);
    expect(find.text('Kegiatan tidak ditemukan'), findsOneWidget);
    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.pumpAndSettle();
    expect(find.text('2 kegiatan'), findsOneWidget);
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
