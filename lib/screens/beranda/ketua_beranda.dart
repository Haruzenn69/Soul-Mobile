import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_config.dart';
import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../anggota/anggota_screen.dart';
import '../faq/ketua_faq_screen.dart';
import '../laporan/laporan_screen.dart';
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
                    final kegiatanBulanIni =
                        (data['kegiatan_bulan_ini'] as num?)?.toInt() ?? 0;
                    final testimoniPending =
                        (data['testimoni_pending_count'] as num?)?.toInt() ?? 0;
                    final faqPending =
                        (data['faq_pending_count'] as num?)?.toInt() ?? 0;
                    final moderasiPending = testimoniPending + faqPending;
                    final ekskul = data['ekskul'] is Map
                        ? Map<String, dynamic>.from(data['ekskul'] as Map)
                        : <String, dynamic>{};

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          user: user,
                          ekskul: ekskul,
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
                          moderasiPending: moderasiPending,
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
                          onApplications: () =>
                              _openKetuaMembers(context, user, 1),
                        ),
                        const SizedBox(height: 18),
                        _QuickActions(
                          onMembers: () =>
                              ref.read(shellTabProvider.notifier).set(1),
                          onActivities: () =>
                              ref.read(shellTabProvider.notifier).set(2),
                          onLaporan: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => LaporanScreen(user: user),
                            ),
                          ),
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
  final titles = ['Anggota', 'Pendaftaran'];
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) {
        final tab = initialTab.clamp(0, titles.length - 1);
        return Scaffold(
          appBar: AppBar(title: Text(titles[tab])),
          body: AnggotaScreen(user: user, initialTab: tab),
        );
      },
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.user,
    required this.ekskul,
    required this.ekskulName,
    required this.onCreateActivity,
    required this.onReviewApplications,
  });

  final AuthUser user;
  final Map<String, dynamic> ekskul;
  final String ekskulName;
  final VoidCallback onCreateActivity;
  final VoidCallback onReviewApplications;

  @override
  Widget build(BuildContext context) {
    final logo = ekskul['logo']?.toString().trim();
    final hasLogo = logo != null && logo.isNotEmpty;
    return Container(
      key: const ValueKey('ketua-dashboard-hero'),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.brandHeroGradient(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandHeroShadow(context),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 12,
            top: 10,
            child: Container(
              key: const ValueKey('ketua-dashboard-hero-mark'),
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: hasLogo
                    ? Image.network(
                        AppConfig.imageUrl(logo),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.groups_2_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      )
                    : const Icon(
                        Icons.groups_2_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PersonAvatar(
                    name: user.namaTampilan,
                    photoUrl: user.fotoUrl,
                    radius: 24,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DASHBOARD KETUA',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 8,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Halo, ${user.namaTampilan}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Ketua ekstrakurikuler · ${_todayLabel()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 62),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        ekskulName.isEmpty
                            ? 'Ekskul belum dipilih'
                            : 'Memimpin $ekskulName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Kelola keanggotaan, tinjau pendaftaran, dan pantau kehadiran ekskulmu.',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final createAction = _HeroActionButton(
                    key: const ValueKey('ketua-hero-create-action'),
                    label: 'Buat kegiatan',
                    icon: Icons.add_rounded,
                    onPressed: onCreateActivity,
                  );
                  final reviewAction = _HeroActionButton(
                    key: const ValueKey('ketua-hero-review-action'),
                    label: 'Tinjau pendaftar',
                    icon: Icons.assignment_outlined,
                    secondary: true,
                    onPressed: onReviewApplications,
                  );
                  if (constraints.maxWidth < 300) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        createAction,
                        const SizedBox(height: 8),
                        reviewAction,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: createAction),
                      const SizedBox(width: 8),
                      Expanded(child: reviewAction),
                    ],
                  );
                },
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

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.secondary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: secondary
          ? Colors.white.withValues(alpha: 0.14)
          : Colors.white,
      foregroundColor: secondary ? Colors.white : AppTheme.blue,
      side: secondary
          ? BorderSide(color: Colors.white.withValues(alpha: 0.38))
          : BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      minimumSize: const Size(0, 42),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
    icon: Icon(icon, size: 16),
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
  );
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
                color: AppTheme.mutedText(context),
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
                                color: AppTheme.mutedText(context),
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
          color: AppTheme.mutedText(context),
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
    required this.moderasiPending,
  });

  final int totalAnggota;
  final int pendingCount;
  final int kegiatanBulanIni;
  final int moderasiPending;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Anggota',
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
              color: AppTheme.warningText(context),
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
              color: AppTheme.successText(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              label: 'Moderasi',
              value: '$moderasiPending',
              icon: Icons.rate_review_outlined,
              color: AppTheme.infoText(context),
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
                color: AppTheme.mutedText(context),
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
                          color: AppTheme.mutedText(context),
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
                          backgroundColor: AppTheme.accentSurface(context),
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
                          color: AppTheme.text(context),
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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Testimoni & FAQ'),
          const SizedBox(height: 2),
          Text(
            'Moderasi kontribusi siswa untuk katalog ekskul.',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.mutedText(context),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ModerationTile(
                  icon: Icons.rate_review_outlined,
                  title: 'Testimoni',
                  count: testimoniPending,
                  tint: AppTheme.accentSurface(context),
                  color: AppTheme.blue,
                  onTap: onOpenTestimoni,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ModerationTile(
                  icon: Icons.help_outline,
                  title: 'FAQ',
                  count: faqPending,
                  tint: AppTheme.warningSurface(context),
                  color: AppTheme.warningText(context),
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
  Widget build(BuildContext context) {
    final status = count > 0 ? 'Perlu ditinjau' : 'Antrian kosong';
    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: ValueKey('moderation-tile-${title.toLowerCase()}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$count',
                          style: GoogleFonts.plusJakartaSans(
                            color: color,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.text(context),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.mutedText(context),
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
}

class _PriorityActions extends StatelessWidget {
  const _PriorityActions({
    required this.pendingCount,
    required this.onApplications,
  });

  final int pendingCount;
  final VoidCallback onApplications;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionTitle('Yang Perlu Ditinjau')),
              StatusChip('$pendingCount menunggu'),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Aksi cepat untuk tugas yang menunggu.',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.mutedText(context),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          if (pendingCount > 0)
            _PriorityTile(
              icon: Icons.assignment_outlined,
              title: 'Pendaftaran baru',
              subtitle: '$pendingCount menunggu tinjauan',
              color: AppTheme.warningText(context),
              tint: AppTheme.warningSurface(context),
              onTap: onApplications,
            )
          else
            _PriorityTile(
              icon: Icons.check_circle_outline_rounded,
              title: 'Semua sudah ditinjau',
              subtitle: 'Belum ada pendaftaran yang menunggu.',
              color: AppTheme.successText(context),
              tint: AppTheme.successSurface(context),
              onTap: onApplications,
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
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      key: const ValueKey('priority-review-tile'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.text(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.mutedText(context),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onMembers,
    required this.onActivities,
    required this.onLaporan,
  });

  final VoidCallback onMembers;
  final VoidCallback onActivities;
  final VoidCallback onLaporan;

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
            const Divider(height: 1, indent: 60),
            _QuickActionTile(
              icon: Icons.event_outlined,
              title: 'Kegiatan',
              subtitle: 'Kelola agenda ekskul',
              onTap: onActivities,
            ),
            const Divider(height: 1, indent: 60),
            _QuickActionTile(
              icon: Icons.description_outlined,
              title: 'Laporan Bulanan',
              subtitle: 'Kelola laporan kegiatan',
              onTap: onLaporan,
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
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      key: ValueKey('quick-action-${title.toLowerCase()}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.accentSurface(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.accent(context), size: 19),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.text(context),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.mutedText(context),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.mutedText(context),
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}
