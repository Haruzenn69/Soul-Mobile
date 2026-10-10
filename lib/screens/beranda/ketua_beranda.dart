import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../core/app_config.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../anggota/anggota_screen.dart';
import '../faq/ketua_faq_screen.dart';
import '../kegiatan/kegiatan_screen.dart';
import '../testimoni/testimoni_manage_screen.dart';

class BerandaKetua extends ConsumerWidget {
  const BerandaKetua({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(ketuaDashboardProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ketuaDashboardProvider);
          await ref.read(ketuaDashboardProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverToBoxAdapter(
                child: ApiAsyncView(
                  value: dashboard,
                  onRetry: () => ref.invalidate(ketuaDashboardProvider),
                  builder: (context, data) {
                    final totalAnggota =
                        (data['total_anggota'] as num?)?.toInt() ?? 0;
                    final pendingCount =
                        (data['pending_count'] as num?)?.toInt() ?? 0;
                    final pengajuanCount =
                        (data['pengajuan_count'] as num?)?.toInt() ?? 0;
                    final kegiatanBulanIni =
                        (data['kegiatan_bulan_ini'] as num?)?.toInt() ?? 0;
                    final testimoniPending =
                        (data['testimoni_pending_count'] as num?)?.toInt() ?? 0;
                    final faqPending =
                        (data['faq_pending_count'] as num?)?.toInt() ?? 0;
                    final ekskul = data['ekskul'] is Map
                        ? Map<String, dynamic>.from(data['ekskul'] as Map)
                        : <String, dynamic>{};

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          user: user,
                          ekskulName:
                              ekskul['nama_ekskul'] as String? ??
                              user.aktivEkskul?.namaEkskul ??
                              '',
                          onCreateActivity: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => Scaffold(
                                appBar: AppBar(
                                  title: const Text('Kegiatan Baru'),
                                ),
                                body: KegiatanScreen(
                                  user: user,
                                  openCreateOnStart: true,
                                ),
                              ),
                            ),
                          ),
                          onReviewApplications: () =>
                              _openKetuaMembers(context, user, 1),
                        ),
                        const SizedBox(height: 14),
                        _StatsGrid(
                          totalAnggota: totalAnggota,
                          pendingCount: pendingCount,
                          kegiatanBulanIni: kegiatanBulanIni,
                          pengajuanCount: pengajuanCount,
                        ),
                        const SizedBox(height: 20),
                        _AttendanceChart(data: data),
                        const SizedBox(height: 18),
                        _ClassDistribution(data: data),
                        const SizedBox(height: 18),
                        _ModerationSummary(
                          testimoniPending: testimoniPending,
                          faqPending: faqPending,
                          onOpenTestimoni: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const TestimoniManageScreen(),
                            ),
                          ),
                          onOpenFaq: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const KetuaFaqScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _PriorityActions(
                          pendingCount: pendingCount,
                          pengajuanCount: pengajuanCount,
                          onApplications: () =>
                              _openKetuaMembers(context, user, 1),
                          onLeaveRequests: () =>
                              _openKetuaMembers(context, user, 2),
                        ),
                        const SizedBox(height: 18),
                        _QuickActions(
                          onMembers: () =>
                              ref.read(shellTabProvider.notifier).set(1),
                          onApplications: () =>
                              _openKetuaMembers(context, user, 1),
                          onActivities: () =>
                              ref.read(shellTabProvider.notifier).set(2),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openKetuaMembers(BuildContext context, AuthUser user, int initialTab) {
  final titles = ['Anggota', 'Pendaftaran', 'Pengajuan Keluar'];
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(titles[initialTab.clamp(0, 2)])),
        body: AnggotaScreen(user: user, initialTab: initialTab),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.user,
    required this.ekskulName,
    required this.onCreateActivity,
    required this.onReviewApplications,
  });

  final AuthUser user;
  final String ekskulName;
  final VoidCallback onCreateActivity;
  final VoidCallback onReviewApplications;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.sky, Color(0xFF60A5FA), AppTheme.blue],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    backgroundImage:
                        (user.fotoUrl != null && user.fotoUrl!.isNotEmpty)
                        ? NetworkImage(AppConfig.imageUrl(user.fotoUrl))
                        : null,
                    child: (user.fotoUrl == null || user.fotoUrl!.isEmpty)
                        ? Text(
                            user.namaTampilan.isEmpty
                                ? '?'
                                : user.namaTampilan[0],
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${user.namaTampilan}',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Ketua ekstrakurikuler · ${_todayLabel()}',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  ekskulName.isEmpty
                      ? 'Ekskul belum dipilih'
                      : 'Memimpin $ekskulName',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kelola keanggotaan, tinjau pendaftaran, dan pantau kehadiran ekskulmu.',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onCreateActivity,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.blue,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.add, size: 17),
                    label: const Text('Buat kegiatan'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onReviewApplications,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.assignment_outlined, size: 17),
                    label: const Text('Tinjau pendaftar'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _todayLabel() {
    final date = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
    final series = [
      _AttendanceSeries('Hadir', const Color(0xFF2563EB), chart['hadir']),
      _AttendanceSeries('Izin', const Color(0xFFF59E0B), chart['izin']),
      _AttendanceSeries('Sakit', const Color(0xFF14B8A6), chart['sakit']),
      _AttendanceSeries('Alpha', const Color(0xFFF43F5E), chart['alpha']),
    ];
    if (labels.isEmpty) {
      return const EmptyState(
        title: 'Belum ada data kehadiran',
        icon: Icons.bar_chart_outlined,
      );
    }

    double maxVal = 1;
    for (final item in series) {
      for (final value in item.values) {
        if (value > maxVal) maxVal = value;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Tren Kehadiran Pertemuan'),
            const SizedBox(height: 3),
            Text(
              'Statistik kehadiran anggota pada 6 pertemuan terbaru.',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.sub,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 142,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 102,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (final item in series)
                                    if (item.values.length > i)
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 1,
                                          ),
                                          child: Container(
                                            height: item.values[i] == 0
                                                ? 2
                                                : 84 * item.values[i] / maxVal,
                                            decoration: BoxDecoration(
                                              color: item.color.withValues(
                                                alpha: item.values[i] == 0
                                                    ? 0.2
                                                    : 1,
                                              ),
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(3),
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${labels[i]}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.sub,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final item in series)
                  _LegendItem(color: item.color, label: item.label),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceSeries {
  _AttendanceSeries(this.label, this.color, Object? raw)
    : values = raw is List
          ? raw.map((value) => value is num ? value.toDouble() : 0.0).toList()
          : const [];

  final String label;
  final Color color;
  final List<double> values;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: AppTheme.sub,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.totalAnggota,
    required this.pendingCount,
    required this.kegiatanBulanIni,
    required this.pengajuanCount,
  });

  final int totalAnggota;
  final int pendingCount;
  final int kegiatanBulanIni;
  final int pengajuanCount;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Anggota Aktif',
              value: '$totalAnggota',
              icon: Icons.groups_outlined,
              color: AppTheme.blue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              label: 'Pendaftaran',
              value: '$pendingCount',
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
              value: '$kegiatanBulanIni',
              icon: Icons.event_available_outlined,
              color: const Color(0xFF15803D),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              label: 'Pengajuan Keluar',
              value: '$pengajuanCount',
              icon: Icons.logout_outlined,
              color: const Color(0xFFE11D48),
            ),
          ),
        ],
      ),
    ],
  );
}

class _ClassDistribution extends StatelessWidget {
  const _ClassDistribution({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final distribution = data['chart_kelas'] is Map
        ? Map<String, dynamic>.from(data['chart_kelas'] as Map)
        : <String, dynamic>{};
    final labels = (distribution['labels'] as List?) ?? const [];
    final values = (distribution['data'] as List?) ?? const [];
    final counts = [
      for (var i = 0; i < labels.length; i++)
        i < values.length && values[i] is num ? values[i] as num : 0,
    ];
    final maxCount = counts.fold<num>(
      0,
      (max, count) => count > max ? count : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Distribusi Anggota'),
            const SizedBox(height: 3),
            Text(
              'Komposisi anggota berdasarkan tingkat kelas.',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.sub,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 14),
            if (counts.every((count) => count == 0))
              const EmptyState(
                title: 'Belum ada data anggota aktif',
                icon: Icons.groups_outlined,
              )
            else
              for (var i = 0; i < counts.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 68,
                      child: Text(
                        i < labels.length ? '${labels[i]}' : 'Kelas',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.sub,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: maxCount == 0
                              ? 0
                              : counts[i].toDouble() / maxCount,
                          minHeight: 9,
                          backgroundColor: const Color(0xFFEFF6FF),
                          color: i == 1
                              ? const Color(0xFFF59E0B)
                              : AppTheme.blue,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${counts[i]}',
                        textAlign: TextAlign.end,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _ModerationSummary extends StatelessWidget {
  const _ModerationSummary({
    required this.testimoniPending,
    required this.faqPending,
    required this.onOpenTestimoni,
    required this.onOpenFaq,
  });

  final int testimoniPending;
  final int faqPending;
  final VoidCallback onOpenTestimoni;
  final VoidCallback onOpenFaq;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Testimoni & FAQ'),
          const SizedBox(height: 3),
          Text(
            'Moderasi kontribusi siswa untuk katalog ekskul.',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.sub,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModerationTile(
                  icon: Icons.rate_review_outlined,
                  title: 'Testimoni',
                  count: testimoniPending,
                  tint: const Color(0xFFEFF6FF),
                  color: AppTheme.blue,
                  onTap: onOpenTestimoni,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModerationTile(
                  icon: Icons.help_outline,
                  title: 'FAQ',
                  count: faqPending,
                  tint: const Color(0xFFFFFBEB),
                  color: const Color(0xFFB45309),
                  onTap: onOpenFaq,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ModerationTile extends StatelessWidget {
  const _ModerationTile({
    required this.icon,
    required this.title,
    required this.count,
    required this.tint,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final Color tint;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: tint,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: GoogleFonts.plusJakartaSans(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$title · ${count > 0 ? 'pending' : 'antrian kosong'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.sub,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PriorityActions extends StatelessWidget {
  const _PriorityActions({
    required this.pendingCount,
    required this.pengajuanCount,
    required this.onApplications,
    required this.onLeaveRequests,
  });

  final int pendingCount;
  final int pengajuanCount;
  final VoidCallback onApplications;
  final VoidCallback onLeaveRequests;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionTitle('Yang Perlu Kamu Cek')),
              StatusChip('${pendingCount + pengajuanCount} Tertunda'),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Aksi cepat untuk tugas yang menunggu.',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.sub,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          _PriorityTile(
            icon: Icons.assignment_outlined,
            title: 'Pendaftaran baru',
            subtitle: '$pendingCount menunggu tinjauan',
            color: const Color(0xFFB45309),
            tint: const Color(0xFFFFFBEB),
            onTap: onApplications,
          ),
          const SizedBox(height: 8),
          _PriorityTile(
            icon: Icons.logout_outlined,
            title: 'Pengajuan keluar',
            subtitle: '$pengajuanCount menunggu keputusan',
            color: const Color(0xFFE11D48),
            tint: const Color(0xFFFFF1F2),
            onTap: onLeaveRequests,
          ),
        ],
      ),
    ),
  );
}

class _PriorityTile extends StatelessWidget {
  const _PriorityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: tint,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          child: Icon(icon, size: 18),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right, color: color),
      ),
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onMembers,
    required this.onApplications,
    required this.onActivities,
  });

  final VoidCallback onMembers;
  final VoidCallback onApplications;
  final VoidCallback onActivities;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionTitle('Akses Cepat'),
      const SizedBox(height: 8),
      Card(
        child: Column(
          children: [
            _QuickActionTile(
              icon: Icons.groups_outlined,
              title: 'Anggota',
              subtitle: 'Kelola anggota aktif',
              onTap: onMembers,
            ),
            const Divider(height: 1, indent: 56),
            _QuickActionTile(
              icon: Icons.assignment_outlined,
              title: 'Pendaftaran',
              subtitle: 'Tinjau pendaftar baru',
              onTap: onApplications,
            ),
            const Divider(height: 1, indent: 56),
            _QuickActionTile(
              icon: Icons.event_outlined,
              title: 'Kegiatan',
              subtitle: 'Kelola agenda ekskul',
              onTap: onActivities,
            ),
          ],
        ),
      ),
    ],
  );
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppTheme.blue),
    title: Text(
      title,
      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right, color: AppTheme.sub),
    onTap: onTap,
  );
}
