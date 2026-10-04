import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

const _namaBulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

String _fmtTanggal(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  final tgl = dt.toLocal();
  return '${tgl.day} ${_namaBulan[tgl.month - 1]} ${tgl.year}';
}

Color _predikatColor(String predikat) => switch (predikat) {
  'A' => const Color(0xFF16803C),
  'B' => const Color(0xFF0284C7),
  'C' => const Color(0xFFB45309),
  'D' => const Color(0xFFC2410C),
  _ => const Color(0xFFE11D48),
};

Color _predikatBg(String predikat) => switch (predikat) {
  'A' => const Color(0xFFECFDF5),
  'B' => const Color(0xFFE0F2FE),
  'C' => const Color(0xFFFFFBEB),
  'D' => const Color(0xFFFFF7ED),
  _ => const Color(0xFFFEF2F2),
};

class NilaiScreen extends ConsumerWidget {
  const NilaiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(siswaNilaiProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nilai Akhir')),
      body: SafeArea(
        top: false,
        child: ApiAsyncView(
          value: value,
          onRetry: () => ref.invalidate(siswaNilaiProvider),
          builder: (context, data) {
            final pendaftaran = data['pendaftaran'] is Map
                ? Map<String, dynamic>.from(data['pendaftaran'] as Map)
                : null;
            final ekskul = data['ekskul'] is Map
                ? Map<String, dynamic>.from(data['ekskul'] as Map)
                : null;
            final periode = data['periode'] is Map
                ? Map<String, dynamic>.from(data['periode'] as Map)
                : null;
            final penilaian = data['penilaian'] is Map
                ? Map<String, dynamic>.from(data['penilaian'] as Map)
                : null;

            if (pendaftaran == null) {
              return const EmptyState(
                title: 'Belum Terdaftar di Ekskul',
                subtitle:
                    'Nilai akan muncul setelah kamu menjadi anggota aktif '
                    'sebuah ekskul dan pembina menilai.',
                icon: Icons.workspace_premium_outlined,
              );
            }

            final periodeLabel = periode?['label']?.toString();

            if (penilaian == null) {
              final rekap = data['rekap'] is Map
                  ? Map<String, dynamic>.from(data['rekap'] as Map)
                  : null;
              return _NilaiBelumAda(
                ekskulNama: ekskul?['nama_ekskul']?.toString(),
                periodeLabel: periodeLabel,
                rekap: rekap,
              );
            }

            return _NilaiDetail(
              ekskulNama: ekskul?['nama_ekskul']?.toString(),
              periodeLabel: periodeLabel,
              penilaian: penilaian,
            );
          },
        ),
      ),
    );
  }
}

class _NilaiBelumAda extends StatelessWidget {
  const _NilaiBelumAda({this.ekskulNama, this.periodeLabel, this.rekap});

  final String? ekskulNama;
  final String? periodeLabel;
  final Map<String, dynamic>? rekap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.line),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Color(0xFFB45309),
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Nilai Belum Diumumkan',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pembina ekskul ${ekskulNama ?? 'kamu'} belum mengirimkan nilai '
                'periode ${periodeLabel ?? 'berjalan'}. Nilai akan tampil di sini '
                'begitu pembina merilisnya.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.sub,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        if (rekap != null) ...[
          const SizedBox(height: 14),
          _RekapSementaraCard(rekap: rekap!),
        ],
      ],
    );
  }
}

class _RekapSementaraCard extends StatelessWidget {
  const _RekapSementaraCard({required this.rekap});

  final Map<String, dynamic> rekap;

  @override
  Widget build(BuildContext context) {
    final pertemuan = rekap['total_pertemuan'] ?? 0;
    final hadir = rekap['total_hadir'] ?? 0;
    final izin = rekap['total_izin'] ?? 0;
    final sakit = rekap['total_sakit'] ?? 0;
    final alpha = rekap['total_alpha'] ?? 0;
    final persen = rekap['persentase_kehadiran'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.blueBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Icon(Icons.check_circle_outline, color: AppTheme.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rekap kehadiran sementara',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$pertemuan pertemuan · $persen% hadir',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.sub,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9EEF5)),
            ),
            child: Text(
              'Kehadiran: H$hadir I$izin S$sakit A$alpha',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.sub,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NilaiDetail extends StatelessWidget {
  const _NilaiDetail({
    this.ekskulNama,
    this.periodeLabel,
    required this.penilaian,
  });

  final String? ekskulNama;
  final String? periodeLabel;
  final Map<String, dynamic> penilaian;

  @override
  Widget build(BuildContext context) {
    final dikirimAt = _fmtTanggal(penilaian['dikirim_at']?.toString());
    final penilai = penilaian['penilai'] is Map
        ? Map<String, dynamic>.from(penilaian['penilai'] as Map)
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                (ekskulNama?.trim().isNotEmpty == true)
                    ? ekskulNama![0].toUpperCase()
                    : '?',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ekskulNama ?? 'Ekstrakurikuler',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Periode ${periodeLabel ?? '-'}',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.sub,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (dikirimAt.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  'Dikeluarkan $dikirimAt',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF16803C),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _NilaiHero(penilaian: penilaian),
        const SizedBox(height: 14),
        _KomponenCard(penilaian: penilaian),
        const SizedBox(height: 14),
        _RekapStatCard(penilaian: penilaian),
        const SizedBox(height: 14),
        _CatatanCard(penilaian: penilaian),
        const SizedBox(height: 14),
        _DinilaiCard(penilaiNama: penilai?['nama']?.toString()),
      ],
    );
  }
}

class _NilaiHero extends StatelessWidget {
  const _NilaiHero({required this.penilaian});

  final Map<String, dynamic> penilaian;

  @override
  Widget build(BuildContext context) {
    final nilaiAkhir = penilaian['nilai_akhir'] ?? 0;
    final predikat = penilaian['predikat']?.toString() ?? '-';

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 130,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF3B4CCA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.blue.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (nilaiAkhir as num).toStringAsFixed(2),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NILAI AKHIR',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 9.5,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Container(
          width: 112,
          height: 130,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _predikatBg(predikat),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _predikatColor(predikat).withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  predikat,
                  style: GoogleFonts.plusJakartaSans(
                    color: _predikatColor(predikat),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Predikat',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.sub,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KomponenCard extends StatelessWidget {
  const _KomponenCard({required this.penilaian});

  final Map<String, dynamic> penilaian;

  @override
  Widget build(BuildContext context) {
    final komponen = [
      (
        'Kehadiran',
        '30%',
        penilaian['persentase_kehadiran'] ?? 0,
        AppTheme.blue,
      ),
      ('Sikap', '25%', penilaian['nilai_sikap'] ?? 0, const Color(0xFFB45309)),
      (
        'Keaktifan',
        '25%',
        penilaian['nilai_keaktifan'] ?? 0,
        const Color(0xFF16803C),
      ),
      (
        'Keterampilan',
        '20%',
        penilaian['nilai_keterampilan'] ?? 0,
        const Color(0xFFE11D48),
      ),
    ];

    return _whiteCard(
      title: 'Rincian Komponen',
      child: Column(
        children: [
          for (var i = 0; i < komponen.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _komponenRow(
              label: komponen[i].$1,
              bobot: komponen[i].$2,
              value: komponen[i].$3,
              color: komponen[i].$4,
            ),
          ],
        ],
      ),
    );
  }

  Widget _komponenRow({
    required String label,
    required String bobot,
    required Object value,
    required Color color,
  }) {
    final numValue = value is num
        ? value.toDouble()
        : double.tryParse('$value') ?? 0;
    final fraction = (numValue / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF475569),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              numValue.toStringAsFixed(1),
              style: GoogleFonts.plusJakartaSans(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              ' / Bobot $bobot',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFCBD5E1),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RekapStatCard extends StatelessWidget {
  const _RekapStatCard({required this.penilaian});

  final Map<String, dynamic> penilaian;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        'Pertemuan',
        '${penilaian['total_pertemuan'] ?? 0}',
        const Color(0xFFF8FAFC),
        AppTheme.ink,
      ),
      (
        'Hadir',
        '${penilaian['total_hadir'] ?? 0}',
        const Color(0xFFECFDF5),
        const Color(0xFF16803C),
      ),
      (
        'Izin',
        '${penilaian['total_izin'] ?? 0}',
        const Color(0xFFF0F9FF),
        const Color(0xFF0284C7),
      ),
      (
        'Sakit',
        '${penilaian['total_sakit'] ?? 0}',
        const Color(0xFFFFFBEB),
        const Color(0xFFB45309),
      ),
      (
        'Alpha',
        '${penilaian['total_alpha'] ?? 0}',
        const Color(0xFFFEF2F2),
        const Color(0xFFE11D48),
      ),
    ];

    return _whiteCard(
      title: 'Rekap Kehadiran',
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: stats[i].$3,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9EEF5)),
                ),
                child: Column(
                  children: [
                    Text(
                      stats[i].$2,
                      style: GoogleFonts.plusJakartaSans(
                        color: stats[i].$4,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stats[i].$1,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.sub,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CatatanCard extends StatelessWidget {
  const _CatatanCard({required this.penilaian});

  final Map<String, dynamic> penilaian;

  @override
  Widget build(BuildContext context) {
    final catatan = penilaian['catatan']?.toString().trim();
    return _whiteCard(
      title: 'Catatan Pembina',
      child: Text(
        (catatan != null && catatan.isNotEmpty)
            ? catatan
            : 'Tidak ada catatan dari pembina.',
        style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF475569),
          fontSize: 12.5,
          height: 1.55,
        ),
      ),
    );
  }
}

class _DinilaiCard extends StatelessWidget {
  const _DinilaiCard({this.penilaiNama});

  final String? penilaiNama;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.blueBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Icon(Icons.person_outline, color: AppTheme.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dinilai oleh ${penilaiNama ?? 'Pembina Ekskul'}',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Nilai akhir dihitung otomatis dari kehadiran dan komponen penilaian.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.sub,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _whiteCard({required String title, required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}
