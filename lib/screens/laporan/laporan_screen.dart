import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../core/file_download.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'laporan_create_screen.dart';
import 'laporan_detail_screen.dart';

class LaporanScreen extends ConsumerWidget {
  const LaporanScreen({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const LaporanCreateScreen()),
        ),
        backgroundColor: AppTheme.blue,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        tooltip: 'Buat laporan baru',
        child: const Icon(Icons.add_rounded),
      ),
      body: const SafeArea(child: LaporanContent()),
    );
  }
}

class LaporanContent extends ConsumerWidget {
  const LaporanContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laporan = ref.watch(ketuaLaporanProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ApiAsyncView(
            value: laporan,
            onRetry: () => ref.invalidate(ketuaLaporanProvider),
            builder: (context, data) {
              final items = listOf(data, 'laporans');
              if (items.isEmpty) {
                return const EmptyState(
                  title: 'Belum ada laporan',
                  subtitle: 'Buat laporan untuk memulai dokumentasi bulanan.',
                  icon: Icons.description_outlined,
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(ketuaLaporanProvider);
                  try {
                    await ref.read(ketuaLaporanProvider.future);
                  } catch (_) {}
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final report = items[i];
                    return _LaporanCard(
                      data: report,
                      onTap: () {
                        final id = (report['id'] as num?)?.toInt();
                        if (id == null) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LaporanDetailScreen(laporanId: id),
                          ),
                        );
                      },
                      onDownload: () => _downloadPdf(context, ref, report),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
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

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: const Color(0xFFE8EDF5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.025),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: AppTheme.blue,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatBulan(bulan),
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _statusDescription(status),
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.sub,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(_labelStatus(status)),
                ],
              ),
              if (ringkasan?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(
                  ringkasan!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.sub,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.open_in_new_rounded,
                    color: AppTheme.blue,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Buka detail laporan',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_outlined, size: 20),
                    tooltip: 'Unduh PDF',
                    style: IconButton.styleFrom(
                      foregroundColor: AppTheme.blue,
                      backgroundColor: const Color(0xFFEFF6FF),
                      minimumSize: const Size(38, 38),
                    ),
                  ),
                ],
              ),
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
      case 'ditolak':
        return 'Perlu Revisi';
      default:
        return raw;
    }
  }

  String _statusDescription(String raw) {
    switch (raw) {
      case 'draft':
        return 'Belum diserahkan ke pembina';
      case 'diserahkan':
      case 'menunggu':
        return 'Menunggu pemeriksaan pembina';
      case 'disetujui':
        return 'Sudah disetujui pembina';
      case 'ditolak':
        return 'Perlu diperbaiki dan dikirim ulang';
      default:
        return 'Laporan kegiatan ekskul';
    }
  }
}
