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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const LaporanCreateScreen()),
          ),
          backgroundColor: AppTheme.blue,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          tooltip: 'Buat laporan baru',
          child: const Icon(Icons.add_rounded),
        ),
      ),
      body: const SafeArea(child: LaporanContent()),
    );
  }
}

class LaporanContent extends ConsumerStatefulWidget {
  const LaporanContent({super.key});

  @override
  ConsumerState<LaporanContent> createState() => _LaporanContentState();
}

class _LaporanContentState extends ConsumerState<LaporanContent> {
  String _statusFilter = 'semua';
  bool _isAscending = true;

  @override
  Widget build(BuildContext context) {
    final laporan = ref.watch(ketuaLaporanProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      PopupMenuButton<String>(
                        onSelected: (val) => setState(() => _statusFilter = val),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'semua', child: Text('Semua Status')),
                          const PopupMenuItem(value: 'pending', child: Text('Pending')),
                          const PopupMenuItem(value: 'diterima', child: Text('Diterima')),
                          const PopupMenuItem(value: 'draft', child: Text('Draft')),
                          const PopupMenuItem(value: 'ditolak', child: Text('Ditolak')),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surface(context),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppTheme.outline(context)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.filter_list_rounded, size: 16, color: AppTheme.blue),
                              const SizedBox(width: 6),
                              Text('Status',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.blue,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _statusFilter[0].toUpperCase() + _statusFilter.substring(1),
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: _isAscending ? 'Urutkan A-Z (Klik untuk Z-A)' : 'Urutkan Z-A (Klik untuk A-Z)',
                child: InkWell(
                  onTap: () => setState(() => _isAscending = !_isAscending),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppTheme.outline(context)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isAscending ? 'A-Z' : 'Z-A',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 14,
                          color: AppTheme.blue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ApiAsyncView(
            value: laporan,
            onRetry: () => ref.invalidate(ketuaLaporanProvider),
            builder: (context, data) {
              final allItems = listOf(data, 'laporans');
              final filtered = allItems.where((item) {
                final st = (item['status'] ?? '').toString().toLowerCase();
                if (_statusFilter == 'semua') return true;
                if (_statusFilter == 'pending') return st == 'pending' || st == 'menunggu' || st == 'diserahkan';
                if (_statusFilter == 'diterima') return st == 'diterima' || st == 'disetujui';
                if (_statusFilter == 'draft') return st == 'draft';
                if (_statusFilter == 'ditolak') return st == 'ditolak';
                return true;
              }).toList();
              final items = [...filtered];
              items.sort((a, b) {
                final titleA = (a['judul'] ?? a['bulan'] ?? '').toString();
                final titleB = (b['judul'] ?? b['bulan'] ?? '').toString();
                return _isAscending ? titleA.compareTo(titleB) : titleB.compareTo(titleA);
              });

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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
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
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: AppTheme.outline(context)),
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
                      color: AppTheme.blue.withValues(alpha: 0.1),
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
                            color: AppTheme.text(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _statusDescription(status),
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.mutedText(context),
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
                    color: AppTheme.mutedText(context),
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
                      backgroundColor: AppTheme.blue.withValues(alpha: 0.1),
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
