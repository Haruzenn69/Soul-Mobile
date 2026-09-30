import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

typedef Json = Map<String, dynamic>;

Future<void> invalidateAll(Ref ref) async {
  await Future<void>.delayed(Duration.zero);
}

Map<String, dynamic>? dataOf(Object? body) {
  if (body is! Map) return null;
  final d = body['data'];
  if (d is! Map) return null;
  return Map<String, dynamic>.from(d);
}

List<Map<String, dynamic>> listOf(Map<String, dynamic>? data, String key) {
  final v = data?[key];
  if (v is List) {
    return v
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return const [];
}

final siswaDashboardProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/siswa/dashboard');
  return dataOf(res) ?? {};
});

final katalogProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/siswa/katalog');
  return dataOf(res) ?? {};
});

final notifikasiProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/siswa/notifikasi');
  return dataOf(res) ?? {};
});

final ketuaDashboardProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/ketua/dashboard');
  return dataOf(res) ?? {};
});

final ketuaKegiatanProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/ketua/kegiatan');
  return dataOf(res) ?? {};
});

final ketuaAnggotaProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/ketua/anggota');
  return dataOf(res) ?? {};
});

final ketuaPendaftaranProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/ketua/pendaftaran');
  return dataOf(res) ?? {};
});

final ketuaPengajuanProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/ketua/pengajuan-keluar');
  return dataOf(res) ?? {};
});

final ketuaLaporanProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/ketua/laporan-bulanan');
  return dataOf(res) ?? {};
});

final kegiatanDetailProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final res =
      await ref.read(apiClientProvider).get('/ketua/kegiatan/$id');
  final data = dataOf(res);
  return {
    'kegiatan': data?['kegiatan'],
    'presensi': data?['presensi'],
    'rekap': data?['rekap'],
  };
});

final presensiFormProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final res = await ref
      .read(apiClientProvider)
      .get('/ketua/kegiatan/$id/presensi');
  return dataOf(res) ?? {};
});

final ketuaRekapProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/ketua/rekap');
  return dataOf(res) ?? {};
});

final siswaRekapProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/siswa/rekap');
  return dataOf(res) ?? {};
});

final siswaPresensiProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/siswa/presensi');
  return dataOf(res) ?? {};
});

final siswaNilaiProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/siswa/nilai');
  return dataOf(res) ?? {};
});

final siswaPengajuanProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/siswa/pengajuan-keluar');
  return dataOf(res) ?? {};
});

final siswaProfilProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/siswa/profile');
  return dataOf(res) ?? {};
});

final ekskulDetailProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final res = await ref.read(apiClientProvider).get('/catalog/$id');
  final data = dataOf(res);
  final ekskul = data?['ekskul'];
  if (ekskul is Map) return Map<String, dynamic>.from(ekskul);
  return {};
});
