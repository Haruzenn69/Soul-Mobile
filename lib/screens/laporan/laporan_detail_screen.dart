import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_config.dart';
import '../../core/file_download.dart';
import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class LaporanDetailScreen extends ConsumerStatefulWidget {
  const LaporanDetailScreen({super.key, required this.laporanId});

  final int laporanId;

  @override
  ConsumerState<LaporanDetailScreen> createState() =>
      _LaporanDetailScreenState();
}

class _LaporanDetailScreenState extends ConsumerState<LaporanDetailScreen> {
  final _tujuan = TextEditingController();
  final _keberhasilan = TextEditingController();
  final _kendala = TextEditingController();
  final _solusi = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  void _populate(Map<String, dynamic> lap) {
    if (_initialized) return;
    _tujuan.text = lap['tujuan'] as String? ?? '';
    _keberhasilan.text = lap['evaluasi_keberhasilan'] as String? ?? '';
    _kendala.text = lap['evaluasi_kendala'] as String? ?? '';
    _solusi.text = lap['evaluasi_solusi'] as String? ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _tujuan.dispose();
    _keberhasilan.dispose();
    _kendala.dispose();
    _solusi.dispose();
    super.dispose();
  }

  Future<void> _updateEvaluasi() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(apiClientProvider)
          .post(
            '/ketua/laporan-bulanan/${widget.laporanId}/update',
            data: {
              'tujuan': _tujuan.text.trim(),
              'evaluasi_keberhasilan': _keberhasilan.text.trim(),
              'evaluasi_kendala': _kendala.text.trim(),
              'evaluasi_solusi': _solusi.text.trim(),
            },
          );
      ref.invalidate(laporanDetailProvider(widget.laporanId));
      ref.invalidate(ketuaLaporanProvider);
      ref.invalidate(ketuaDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evaluasi laporan berhasil diperbarui.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) await showErrorDialog(context, ref, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _serahkanKePembina() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Serahkan Laporan?'),
        content: const Text(
          'Laporan akan dikirim ke pembina untuk diperiksa dan disetujui. Setelah diserahkan, Anda tidak dapat mengedit isi laporan kecuali diminta revisi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Serahkan'),
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
          IconButton(
            onPressed: () => _downloadPdf(context),
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Unduh PDF',
          ),
        ],
      ),
      body: ApiAsyncView(
        value: detail,
        builder: (context, data) {
          final lap = data['laporan'] is Map
              ? Map<String, dynamic>.from(data['laporan'] as Map)
              : <String, dynamic>{};
          _populate(lap);

          final bulan = lap['bulan'] as String? ?? '-';
          final status = lap['status'] as String? ?? 'draft';
          final materiKegiatan = lap['materi_kegiatan'] as String? ?? '';
          final kehadiran = lap['kehadiran'] as String? ?? '';
          final catatanPembina = lap['catatan_pembina'] as String?;
          final dokumentasi =
              (lap['dokumentasi_kegiatan'] as List?) ?? const [];
          final canEdit = status == 'draft' || status == 'ditolak';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Periode: $bulan',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  StatusChip(_labelStatus(status)),
                ],
              ),
              if (catatanPembina != null && catatanPembina.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
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
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              catatanPembina,
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF881337),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const SectionTitle('Materi Kegiatan yang Terlaksana'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Text(
                  materiKegiatan.isEmpty
                      ? 'Belum ada kegiatan yang tercatat di bulan ini.'
                      : materiKegiatan,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.ink,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle('Rekap Kehadiran'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Text(
                  kehadiran.isEmpty
                      ? 'Belum ada data presensi kegiatan di bulan ini.'
                      : kehadiran,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.ink,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              if (dokumentasi.isNotEmpty) ...[
                const SizedBox(height: 20),
                const SectionTitle('Dokumentasi Kegiatan'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: dokumentasi.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        AppConfig.imageUrl(dokumentasi[i].toString()),
                        width: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 140,
                          color: Colors.black12,
                          child: const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const SectionTitle('Evaluasi & Catatan'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _tujuan,
                      readOnly: !canEdit,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Tujuan Kegiatan Bulan Ini',
                        hintText: 'Tuliskan target kegiatan...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _keberhasilan,
                      readOnly: !canEdit,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Evaluasi Keberhasilan',
                        hintText: 'Capaian positif yang diraih...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _kendala,
                      readOnly: !canEdit,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Kendala yang Dihadapi',
                        hintText: 'Hambatan atau masalah yang muncul...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _solusi,
                      readOnly: !canEdit,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Solusi & Rencana Perbaikan',
                        hintText: 'Langkah penyelesaian ke depan...',
                      ),
                    ),
                    if (canEdit) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _saving ? null : _updateEvaluasi,
                          child: const Text('Simpan Draft Evaluasi'),
                        ),
                      ),
                    ],
                  ],
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
                  if (status != 'draft') {
                    return const SizedBox.shrink();
                  }
                  return ElevatedButton.icon(
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Serahkan Laporan ke Pembina'),
                    onPressed: _saving ? null : _serahkanKePembina,
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

  Future<void> _downloadPdf(BuildContext context) async {
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
