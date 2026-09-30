import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class BerandaKetua extends ConsumerWidget {
  const BerandaKetua({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(ketuaDashboardProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(user: user)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverToBoxAdapter(
              child: ApiAsyncView(
                value: dashboard,
                builder: (context, data) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: _card,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${data['ekskul'] is Map ? (data['ekskul'] as Map)['nama_ekskul'] ?? '' : ''}',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.ink,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Ekskul yang kamu pimpin',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.sub,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.admin_panel_settings,
                                color: AppTheme.blue, size: 28),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Anggota',
                              value:
                                  '${(data['total_anggota'] as num?)?.toInt() ?? 0}',
                              icon: Icons.groups_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              label: 'Pendaftar Baru',
                              value:
                                  '${(data['pending_count'] as num?)?.toInt() ?? 0}',
                              icon: Icons.how_to_reg_outlined,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Kegiatan Bulan Ini',
                              value:
                                  '${(data['kegiatan_bulan_ini'] as num?)?.toInt() ?? 0}',
                              icon: Icons.event_available_outlined,
                              color: const Color(0xFF16803C),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              label: 'Pengajuan Keluar',
                              value:
                                  '${(data['pengajuan_count'] as num?)?.toInt() ?? 0}',
                              icon: Icons.logout_outlined,
                              color: const Color(0xFFE11D48),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const SectionTitle('Kehadiran Kegiatan'),
                      const SizedBox(height: 8),
                      _AttendanceChart(data: data),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final BoxDecoration _card = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
);

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.blue, AppTheme.blueDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                child: Text(
                  user.namaTampilan.isEmpty ? '?' : user.namaTampilan[0],
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${user.namaTampilan}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Ketua ekstrakurikuler',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              user.aktivEkskul?.namaEkskul ?? '-',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceChart extends StatelessWidget {
  const _AttendanceChart({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final chart = data['chart_kegiatan'] is Map
        ? Map<String, dynamic>.from(data['chart_kegiatan'] as Map)
        : <String, dynamic>{};
    final labels = (chart['labels'] as List?) ?? const [];
    final hadir = (chart['hadir'] as List?) ?? const [];
    if (labels.isEmpty) {
      return const EmptyState(
        title: 'Belum ada data kehadiran',
        icon: Icons.bar_chart_outlined,
      );
    }

    double maxVal = 1;
    for (final v in hadir) {
      final n = (v is num) ? v.toDouble() : 0.0;
      if (n > maxVal) maxVal = n;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anggota hadir per kegiatan',
            style: GoogleFonts.inter(
              color: AppTheme.sub,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < labels.length && i < hadir.length; i++) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${hadir[i]}',
                          style: GoogleFonts.inter(
                            color: AppTheme.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 22,
                          height: 100 * ((hadir[i] as num).toDouble() / maxVal),
                          decoration: BoxDecoration(
                            color: AppTheme.blue,
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${labels[i]}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppTheme.sub,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i != labels.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}