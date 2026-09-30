import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Laporan Bulanan',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
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
                  itemBuilder: (context, i) =>
                      _LaporanCard(data: items[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buatLaporan(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Buat Laporan Bulan Ini',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Text(
          'Laporan akan digenerate otomatis berdasarkan kegiatan dan presensi bulan ini.',
          style: GoogleFonts.inter(
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
      await ref.read(apiClientProvider).post('/ketua/laporan-bulanan', data: {});
      ref.invalidate(ketuaLaporanProvider);
      ref.invalidate(ketuaDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan bulanan berhasil dibuat.')),
        );
      }
    } catch (e) {
      await showErrorDialog(context, ref, e);
    }
  }
}

class _LaporanCard extends StatelessWidget {
  const _LaporanCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final bulan = data['bulan'] as String? ?? '-';
    final status = data['status'] as String? ?? '-';
    final ringkasan = data['ringkasan'] as String?;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatBulan(bulan),
                style: GoogleFonts.inter(
                  color: AppTheme.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              StatusChip(_labelStatus(status)),
            ],
          ),
          if (ringkasan?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              ringkasan!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AppTheme.sub,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatBulan(String bulan) {
    final parts = bulan.split('-');
    if (parts.length != 2) return bulan;
    const nama = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
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
        return 'Diserahkan';
      case 'disetujui':
        return 'Disetujui';
      default:
        return raw;
    }
  }
}