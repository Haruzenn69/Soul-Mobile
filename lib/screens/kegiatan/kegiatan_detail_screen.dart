import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_config.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class KegiatanDetailScreen extends ConsumerWidget {
  const KegiatanDetailScreen({super.key, required this.kegiatanId});

  final int kegiatanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(kegiatanDetailProvider(kegiatanId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Kegiatan')),
      body: ApiAsyncView(
        value: detail,
        builder: (context, data) {
          final keg = Kegiatan.fromJson(data['kegiatan'] is Map
              ? Map<String, dynamic>.from(data['kegiatan'] as Map)
              : null);
          final ringkasan = data['ringkasan'] is Map
              ? Map<String, dynamic>.from(data['ringkasan'] as Map)
              : <String, dynamic>{};
          final presensi = (data['presensi'] as List?) ?? const [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                keg.materi,
                style: GoogleFonts.inter(
                  color: AppTheme.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.schedule, color: AppTheme.sub, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    keg.tanggalText,
                    style: GoogleFonts.inter(
                      color: AppTheme.sub,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (keg.isEvent) const StatusChip('Event'),
                ],
              ),
              if (keg.dokumentasi?.isNotEmpty == true) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    AppConfig.imageUrl(keg.dokumentasi),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 200,
                      color: Colors.black12,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
              if (keg.deskripsi?.isNotEmpty == true) ...[
                const SizedBox(height: 14),
                Text(
                  keg.deskripsi!,
                  style: GoogleFonts.inter(
                    color: AppTheme.sub,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const SectionTitle('Ringkasan Kehadiran'),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final entry
                      in [('hadir', 'Hadir'), ('izin', 'Izin'), ('sakit', 'Sakit'), ('alpha', 'Alpha')])
                    Expanded(
                      child: StatCard(
                        label: entry.$2,
                        value:
                            '${(ringkasan[entry.$1] as num?)?.toInt() ?? 0}',
                        color: _colorFor(entry.$1),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              const SectionTitle('Rekap Presensi'),
              const SizedBox(height: 8),
              if (presensi.isEmpty)
                const EmptyState(
                  title: 'Belum ada data presensi',
                  icon: Icons.assignment_outlined,
                )
              else
                Column(
                  children: [
                    for (final p in presensi)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.black.withValues(alpha: 0.05)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${p['nama'] ?? '-'}',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.ink,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              StatusChip('${p['status'] ?? '-'}'),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Color _colorFor(String key) {
    switch (key) {
      case 'hadir':
        return const Color(0xFF16803C);
      case 'izin':
        return const Color(0xFF1E5AA8);
      case 'sakit':
        return const Color(0xFFC77700);
      default:
        return const Color(0xFFE11D48);
    }
  }
}