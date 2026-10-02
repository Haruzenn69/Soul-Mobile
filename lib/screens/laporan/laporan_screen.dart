import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../core/file_download.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../kegiatan/rekap_presensi_screen.dart';
import 'laporan_detail_screen.dart';

class LaporanScreen extends ConsumerWidget {
  const LaporanScreen({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laporan = ref.watch(ketuaLaporanProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Laporan Bulanan',
            subtitle: 'Pantau dan unduh ringkasan kegiatan ekskul.',
            eyebrow: 'DOKUMENTASI',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RekapPresensiScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.fact_check_outlined),
                  tooltip: 'Rekap kehadiran',
                ),
                IconButton.filled(
                  onPressed: () => _buatLaporan(context, ref),
                  icon: const Icon(Icons.add),
                  tooltip: 'Buat laporan bulan ini',
                ),
              ],
            ),
          ),
          Expanded(
            child: ApiAsyncView(
              value: laporan,
              builder: (context, data) {
                final items = listOf(data, 'laporans');
                if (items.isEmpty) {
                  return const EmptyState(
                    title: 'Belum ada laporan',
                    subtitle: 'Tekan + untuk membuat laporan bulan ini.',
                    icon: Icons.description_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _LaporanCard(
                    data: items[i],
                    onTap: () {
                      final id = (items[i]['id'] as num?)?.toInt();
                      if (id == null) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LaporanDetailScreen(laporanId: id),
                        ),
                      );
                    },
                    onDownload: () => _downloadPdf(context, ref, items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> report,
  ) async {
    final id = (report['id'] as num?)?.toInt();
    if (id == null) return;
    final month = report['bulan']?.toString() ?? 'laporan';
    try {
      final saved = await saveApiFile(
        api: ref.read(apiClientProvider),
        path: '/ketua/laporan-bulanan/$id/pdf',
        fileName: 'laporan-$month.pdf',
      );
      if (saved && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF laporan berhasil disimpan.')),
        );
      }
    } catch (error) {
      if (context.mounted) await showErrorDialog(context, ref, error);
    }
  }

  Future<void> _buatLaporan(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Buat Laporan Bulan Ini',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Laporan akan digenerate otomatis berdasarkan kegiatan dan presensi bulan ini.',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.sub,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Buat'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref
          .read(apiClientProvider)
          .post('/ketua/laporan-bulanan', data: {});
      ref.invalidate(ketuaLaporanProvider);
      ref.invalidate(ketuaDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan bulanan berhasil dibuat.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        await showErrorDialog(context, ref, e);
      }
    }
  }
}

class _LaporanCard extends StatelessWidget {
  const _LaporanCard({
    required this.data,
    required this.onTap,
    required this.onDownload,
  });

  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final bulan = data['bulan'] as String? ?? '-';
    final status = data['status'] as String? ?? '-';
    final ringkasan = data['ringkasan'] as String?;

    return Card(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatBulan(bulan),
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  StatusChip(_labelStatus(status)),
                  IconButton(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_outlined),
                    tooltip: 'Unduh PDF',
                  ),
                ],
              ),
              if (ringkasan?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  ringkasan!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.sub,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatBulan(String bulan) {
    final parts = bulan.split('-');
    if (parts.length != 2) return bulan;
    const nama = [
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
    final m = int.tryParse(parts[1]);
    if (m == null || m < 1 || m > 12) return bulan;
    return '${nama[m - 1]} ${parts[0]}';
  }

  String _labelStatus(String raw) {
    switch (raw) {
      case 'draft':
        return 'Draft';
      case 'diserahkan':
      case 'menunggu':
        return 'Diserahkan';
      case 'disetujui':
        return 'Disetujui';
      default:
        return raw;
    }
  }
}
