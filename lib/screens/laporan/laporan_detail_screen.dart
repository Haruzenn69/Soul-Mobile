import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_config.dart';
import '../../core/file_download.dart';
import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/photo_viewer.dart';
import 'laporan_create_screen.dart';

class LaporanDetailScreen extends ConsumerStatefulWidget {
  const LaporanDetailScreen({super.key, required this.laporanId});

  final int laporanId;

  @override
  ConsumerState<LaporanDetailScreen> createState() =>
      _LaporanDetailScreenState();
}

class _LaporanDetailScreenState extends ConsumerState<LaporanDetailScreen> {
  bool _saving = false;
  bool _downloading = false;

  Future<void> _editReport() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => LaporanCreateScreen(laporanId: widget.laporanId),
      ),
    );
    if (updated == true && mounted) {
      ref.invalidate(laporanDetailProvider(widget.laporanId));
      ref.invalidate(ketuaLaporanProvider);
      ref.invalidate(ketuaDashboardProvider);
    }
  }

  Future<void> _serahkanKePembina(String status) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          status == 'ditolak' ? 'Kirim Ulang Laporan?' : 'Serahkan Laporan?',
        ),
        content: Text(
          status == 'ditolak'
              ? 'Laporan revisi akan dikirim kembali ke pembina untuk ditinjau.'
              : 'Laporan akan dikirim ke pembina untuk ditinjau. Setelah diserahkan, isi laporan tidak dapat diedit kecuali diminta revisi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(status == 'ditolak' ? 'Kirim Ulang' : 'Serahkan'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(apiClientProvider)
          .post('/ketua/laporan-bulanan/${widget.laporanId}/serahkan');
      ref.invalidate(laporanDetailProvider(widget.laporanId));
      ref.invalidate(ketuaLaporanProvider);
      ref.invalidate(ketuaDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan berhasil diserahkan ke pembina!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) await showErrorDialog(context, ref, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(laporanDetailProvider(widget.laporanId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan Bulanan'),
        actions: [
          detail.maybeWhen(
            data: (data) {
              final lap = data['laporan'] is Map
                  ? data['laporan'] as Map
                  : const <String, dynamic>{};
              final status = lap['status'] as String? ?? 'draft';
              if (status != 'draft' && status != 'ditolak') {
                return const SizedBox.shrink();
              }
              return IconButton(
                onPressed: _editReport,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit laporan',
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _downloading ? null : () => _downloadPdf(context),
              icon: _downloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              tooltip: 'Unduh PDF',
            ),
          ),
        ],
      ),
      body: ApiAsyncView(
        value: detail,
        onRetry: () => ref.invalidate(laporanDetailProvider(widget.laporanId)),
        builder: (context, data) {
          final lap = data['laporan'] is Map
              ? Map<String, dynamic>.from(data['laporan'] as Map)
              : <String, dynamic>{};

          final bulan = lap['bulan'] as String? ?? '-';
          final status = lap['status'] as String? ?? 'draft';
          final materiKegiatan = lap['materi_kegiatan'] as String? ?? '';
          final kehadiran = lap['kehadiran'] as String? ?? '';
          final catatanPembina = lap['catatan_pembina'] as String?;
          final dokumentasi =
              (lap['dokumentasi_kegiatan'] as List?) ?? const [];
          final ringkasan = lap['ringkasan']?.toString();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _reportHero(bulan, status, ringkasan),
              const SizedBox(height: 14),
              _reviewStatusCard(status),
              if (catatanPembina != null && catatanPembina.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFE11D48),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Catatan dari Pembina:',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF9F1239),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              catatanPembina,
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF881337),
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              _contentCard(
                title: 'Materi Kegiatan',
                subtitle: 'Kegiatan yang tercatat selama periode ini.',
                icon: Icons.event_note_outlined,
                child: _reportText(
                  materiKegiatan,
                  empty: 'Belum ada kegiatan yang tercatat pada periode ini.',
                ),
              ),
              const SizedBox(height: 14),
              _contentCard(
                title: 'Rekap Kehadiran',
                subtitle: 'Ringkasan presensi kegiatan ekskul.',
                icon: Icons.fact_check_outlined,
                child: _reportText(
                  kehadiran,
                  empty: 'Belum ada data presensi pada periode ini.',
                ),
              ),
              if (dokumentasi.isNotEmpty) ...[
                const SizedBox(height: 14),
                _contentCard(
                  title: 'Dokumentasi',
                  subtitle:
                      '${dokumentasi.length} foto kegiatan · Ketuk foto untuk memperbesar.',
                  icon: Icons.photo_library_outlined,
                  child: SizedBox(
                    height: 132,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: dokumentasi.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final imageUrl = AppConfig.imageUrl(
                          dokumentasi[i].toString(),
                        );
                        return _reportPhoto(
                          imageUrl,
                          () => _showPhoto(context, imageUrl),
                        );
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Evaluasi & Catatan',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (status == 'draft' || status == 'ditolak')
                    TextButton.icon(
                      onPressed: _editReport,
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Edit'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _contentCard(
                title: 'Tujuan Kegiatan',
                subtitle: 'Target ekskul untuk periode ini.',
                icon: Icons.flag_outlined,
                child: _reportText(
                  lap['tujuan']?.toString() ?? '',
                  empty: 'Tujuan kegiatan belum diisi.',
                ),
              ),
              const SizedBox(height: 10),
              _contentCard(
                title: 'Evaluasi Keberhasilan',
                subtitle: 'Capaian positif yang berhasil diraih.',
                icon: Icons.emoji_events_outlined,
                child: _reportText(
                  lap['evaluasi_keberhasilan']?.toString() ?? '',
                  empty: 'Evaluasi keberhasilan belum diisi.',
                ),
              ),
              const SizedBox(height: 10),
              _contentCard(
                title: 'Kendala yang Dihadapi',
                subtitle: 'Hambatan selama kegiatan.',
                icon: Icons.warning_amber_rounded,
                child: _reportText(
                  lap['evaluasi_kendala']?.toString() ?? '',
                  empty: 'Tidak ada kendala yang dicatat.',
                ),
              ),
              const SizedBox(height: 10),
              _contentCard(
                title: 'Solusi & Tindak Lanjut',
                subtitle: 'Rencana perbaikan berikutnya.',
                icon: Icons.lightbulb_outline_rounded,
                child: _reportText(
                  lap['evaluasi_solusi']?.toString() ?? '',
                  empty: 'Belum ada solusi atau tindak lanjut.',
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Consumer(
            builder: (context, ref, _) {
              final detail = ref.watch(laporanDetailProvider(widget.laporanId));
              return detail.maybeWhen(
                data: (data) {
                  final lap = data['laporan'] is Map
                      ? data['laporan'] as Map
                      : {};
                  final status = lap['status'] as String? ?? 'draft';
                  if (status != 'draft' && status != 'ditolak') {
                    return const SizedBox.shrink();
                  }

                  return ElevatedButton.icon(
                    icon: const Icon(Icons.send_outlined),
                    label: Text(
                      status == 'ditolak'
                          ? 'Kirim Ulang ke Pembina'
                          : 'Serahkan Laporan ke Pembina',
                    ),
                    onPressed: _saving
                        ? null
                        : () => _serahkanKePembina(status),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _reportHero(String bulan, String status, String? ringkasan) {
    final monthParts = bulan.split('-');
    const monthNames = [
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
    final month = monthParts.length == 2 ? int.tryParse(monthParts[1]) : null;
    final period = month != null && month >= 1 && month <= 12
        ? '${monthNames[month - 1]} ${monthParts[0]}'
        : bulan;
    final statusColor = switch (status) {
      'disetujui' => const Color(0xFF15803D),
      'ditolak' => const Color(0xFFBE123C),
      'draft' => const Color(0xFF475569),
      _ => const Color(0xFF1D4ED8),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.sky, Color(0xFF60A5FA), AppTheme.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.blue.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _labelStatus(status),
                  style: GoogleFonts.plusJakartaSans(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'LAPORAN BULANAN',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            period,
            key: const ValueKey('laporan-periode'),
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 25,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (ringkasan != null && ringkasan.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              ringkasan,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reviewStatusCard(String status) {
    final (icon, title, message, color, background) = switch (status) {
      'draft' => (
        Icons.edit_note_rounded,
        'Masih berupa draft',
        'Periksa kembali isi laporan, lalu serahkan kepada pembina untuk ditinjau.',
        const Color(0xFF475569),
        const Color(0xFFF1F5F9),
      ),
      'ditolak' => (
        Icons.rate_review_outlined,
        'Perlu diperbaiki',
        'Baca catatan pembina di bawah, perbarui laporan, lalu kirim ulang.',
        const Color(0xFFBE123C),
        const Color(0xFFFFF1F2),
      ),
      'disetujui' => (
        Icons.verified_outlined,
        'Laporan disetujui',
        'Pembina telah menyetujui laporan untuk periode ini.',
        const Color(0xFF15803D),
        const Color(0xFFF0FDF4),
      ),
      _ => (
        Icons.hourglass_top_rounded,
        'Menunggu tinjauan pembina',
        'Laporan sudah diserahkan dan sedang menunggu pemeriksaan.',
        const Color(0xFF1D4ED8),
        const Color(0xFFEFF6FF),
      ),
    };
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.ink,
                    fontSize: 12,
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

  Widget _contentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.blue, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.sub,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _reportText(String value, {required String empty}) {
    final text = value.trim();
    return Text(
      text.isEmpty ? empty : text,
      style: GoogleFonts.plusJakartaSans(
        color: text.isEmpty ? AppTheme.sub : AppTheme.ink,
        fontSize: 13,
        height: 1.55,
      ),
    );
  }

  void _showPhoto(BuildContext context, String imageUrl) {
    PhotoViewDialog.show(
      context,
      imageUrl: imageUrl,
      title: 'Foto Dokumentasi',
    );
  }

  Widget _reportPhoto(String imageUrl, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: 'Perbesar foto dokumentasi',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            imageUrl,
            width: 148,
            height: 132,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                width: 148,
                height: 132,
                color: const Color(0xFFF1F5F9),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (_, _, _) => Container(
              width: 148,
              height: 132,
              color: const Color(0xFFF1F5F9),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.broken_image_outlined,
                    color: AppTheme.sub,
                    size: 25,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Foto tidak tersedia',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.sub,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final saved = await saveApiFile(
        api: ref.read(apiClientProvider),
        path: '/ketua/laporan-bulanan/${widget.laporanId}/pdf',
        fileName: 'laporan-${widget.laporanId}.pdf',
      );
      if (!context.mounted) return;
      if (saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF laporan berhasil disimpan.')),
        );
      }
    } catch (error) {
      if (context.mounted) await showErrorDialog(context, ref, error);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  String _labelStatus(String raw) {
    switch (raw) {
      case 'draft':
        return 'Draft';
      case 'menunggu':
      case 'diserahkan':
        return 'Menunggu Pembina';
      case 'disetujui':
        return 'Disetujui';
      case 'ditolak':
        return 'Perlu Revisi';
      default:
        return raw;
    }
  }
}
