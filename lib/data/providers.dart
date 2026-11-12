import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/providers.dart';

/// Definisi tipe data peta JSON (Map &lt;String, dynamic&gt;)
typedef Json = Map<String, dynamic>;

/// Fungsi bantu untuk menginvalidasi seluruh cache provider
Future<void> invalidateAll(Ref ref) async {
  await Future<void>.delayed(Duration.zero);
}

/// Helper untuk mengekstrak objek `data` dari respons standar JSON API
Map<String, dynamic>? dataOf(Object? body) {
  if (body is! Map) return null;
  final d = body['data'];
  if (d is! Map) return null;
  return Map<String, dynamic>.from(d);
}

/// Helper untuk mengekstrak daftar list dari respons JSON API berdasarkan key tertentu
List<Map<String, dynamic>> listOf(Map<String, dynamic>? data, String key) {
  final v = data?[key];
  if (v is List) {
    return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  return const [];
}

Future<Map<String, dynamic>> _getAllPages(
  ApiClient api,
  String path,
  String collectionKey,
) async {
  final items = <Map<String, dynamic>>[];
  Map<String, dynamic>? result;
  var page = 1;

  while (true) {
    final response = await api.get(
      path,
      query: {'page': page, 'per_page': 100},
    );
    final data = dataOf(response) ?? {};
    result ??= data;
    items.addAll(listOf(data, collectionKey));

    final pagination = data['pagination'];
    final lastPage = pagination is Map
        ? (pagination['last'] as num?)?.toInt() ?? page
        : page;
    if (page >= lastPage) break;
    page++;
  }

  return {...result, collectionKey: items};
}

/// Provider untuk mengambil data Dashboard Siswa
final siswaDashboardProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final ekskulId = ref.watch(selectedSiswaEkskulProvider);
  final res = await ref
      .read(apiClientProvider)
      .get(
        '/siswa/dashboard',
        query: ekskulId == null ? null : {'ekskul_id': ekskulId},
      );
  return dataOf(res) ?? {};
});

/// Provider untuk mengambil data Katalog Ekskul Siswa
final katalogProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/siswa/katalog');
  return dataOf(res) ?? {};
});

/// Provider untuk mengambil daftar Notifikasi pengguna
final notifikasiProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/siswa/notifikasi');
  return dataOf(res) ?? {};
});

/// Provider untuk mengambil data Dashboard Ketua Ekstrakurikuler
final ketuaDashboardProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final res = await ref.read(apiClientProvider).get('/ketua/dashboard');
  return dataOf(res) ?? {};
});

/// Provider untuk mengambil daftar Kegiatan Ekskul (Ketua)
final ketuaKegiatanProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return _getAllPages(
    ref.read(apiClientProvider),
    '/ketua/kegiatan',
    'kegiatans',
  );
});

/// Provider untuk mengambil daftar Anggota Ekskul (Ketua)
final ketuaAnggotaProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return _getAllPages(
    ref.read(apiClientProvider),
    '/ketua/anggota',
    'anggotas',
  );
});

/// Provider family untuk mengambil daftar Pendaftaran berdasarkan status (Ketua)
final ketuaPendaftaranProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, status) async {
      final query = (status.isNotEmpty && status != 'semua')
          ? {'status': status}
          : null;
      final res = await ref
          .read(apiClientProvider)
          .get('/ketua/pendaftaran', query: query);
      return dataOf(res) ?? {};
    });

/// Provider family untuk mengambil daftar Pengajuan Keluar berdasarkan status (Ketua)
final ketuaPengajuanProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, status) async {
      final query = (status.isNotEmpty && status != 'semua')
          ? {'status': status}
          : null;
      final res = await ref
          .read(apiClientProvider)
          .get('/ketua/pengajuan-keluar', query: query);
      return dataOf(res) ?? {};
    });

final ketuaLaporanProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/ketua/laporan-bulanan');
  return dataOf(res) ?? {};
});

final kegiatanDetailProvider = FutureProvider.family<Map<String, dynamic>, int>(
  (ref, id) async {
    final res = await ref.read(apiClientProvider).get('/ketua/kegiatan/$id');
    final data = dataOf(res);
    return {
      'kegiatan': data?['kegiatan'],
      'presensi': data?['presensi'],
      'ringkasan': data?['ringkasan'] ?? data?['rekap'],
    };
  },
);

final presensiFormProvider = FutureProvider.family<Map<String, dynamic>, int>((
  ref,
  id,
) async {
  final res = await ref
      .read(apiClientProvider)
      .get('/ketua/kegiatan/$id/presensi');
  return dataOf(res) ?? {};
});

final ketuaRekapProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/ketua/rekap');
  return dataOf(res) ?? {};
});

final siswaRekapProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/siswa/rekap');
  return dataOf(res) ?? {};
});

Map<String, dynamic>? _ekskulQuery(int? ekskulId) =>
    ekskulId == null ? null : {'ekskul_id': ekskulId};

final siswaPresensiProvider = FutureProvider.family<Map<String, dynamic>, int?>(
  (ref, ekskulId) async {
    final res = await ref
        .read(apiClientProvider)
        .get('/siswa/presensi', query: _ekskulQuery(ekskulId));
    return dataOf(res) ?? {};
  },
);

final siswaNilaiProvider = FutureProvider.family<Map<String, dynamic>, int?>((
  ref,
  ekskulId,
) async {
  final res = await ref
      .read(apiClientProvider)
      .get('/siswa/nilai', query: _ekskulQuery(ekskulId));
  return dataOf(res) ?? {};
});

final siswaPengajuanProvider =
    FutureProvider.family<Map<String, dynamic>, int?>((ref, ekskulId) async {
      final res = await ref
          .read(apiClientProvider)
          .get('/siswa/pengajuan-keluar', query: _ekskulQuery(ekskulId));
      return dataOf(res) ?? {};
    });

final siswaProfilProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/siswa/profile');
  return dataOf(res) ?? {};
});

final ekskulDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((
  ref,
  id,
) async {
  final res = await ref.read(apiClientProvider).get('/catalog/$id');
  return dataOf(res) ?? {};
});

final ketuaProfilEkskulProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final res = await ref.read(apiClientProvider).get('/ketua/profil-ekskul');
  return dataOf(res) ?? {};
});

final ketuaPrestasiProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.read(apiClientProvider).get('/ketua/prestasi');
  return dataOf(res) ?? {};
});

final laporanDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((
  ref,
  id,
) async {
  final res = await ref
      .read(apiClientProvider)
      .get('/ketua/laporan-bulanan/$id');
  return dataOf(res) ?? {};
});

final siswaRekapMonthProvider =
    FutureProvider.family<
      Map<String, dynamic>,
      ({String? bulan, int? ekskulId})
    >((ref, params) async {
      final query = <String, dynamic>{
        if (params.bulan != null && params.bulan!.isNotEmpty)
          'bulan': params.bulan,
        if (params.ekskulId != null) 'ekskul_id': params.ekskulId,
      };
      final res = await ref
          .read(apiClientProvider)
          .get('/siswa/rekap', query: query.isEmpty ? null : query);
      return dataOf(res) ?? {};
    });

final ketuaRekapMonthProvider =
    FutureProvider.family<Map<String, dynamic>, String?>((ref, bulan) async {
      final query = (bulan != null && bulan.isNotEmpty)
          ? {'bulan': bulan}
          : null;
      final res = await ref
          .read(apiClientProvider)
          .get('/ketua/rekap', query: query);
      return dataOf(res) ?? {};
    });

final ketuaTestimoniProvider =
    FutureProvider.family<Map<String, dynamic>, String?>((ref, status) async {
      final query = (status != null && status.isNotEmpty && status != 'semua')
          ? {'status': status}
          : null;
      final res = await ref
          .read(apiClientProvider)
          .get('/ketua/testimoni', query: query);
      return dataOf(res) ?? {};
    });
