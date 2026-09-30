import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../katalog/ekskul_detail_screen.dart';

class BerandaSiswa extends ConsumerWidget {
  const BerandaSiswa({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(siswaDashboardProvider);

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
                  final rawPendaftaran = data['pendaftaran'];
                  final pendaftaran = rawPendaftaran is Map
                      ? Map<String, dynamic>.from(rawPendaftaran)
                      : null;
                  final rawDashboardEkskul = data['ekskul'];
                  final dashboardEkskul = rawDashboardEkskul is Map
                      ? Map<String, dynamic>.from(rawDashboardEkskul)
                      : null;
                  final sessionEkskul = user.aktivEkskul;
                  final ekskul = pendaftaran?['ekskul'] is Map
                      ? Map<String, dynamic>.from(pendaftaran!['ekskul'] as Map)
                      : dashboardEkskul ?? (sessionEkskul == null
                          ? <String, dynamic>{}
                          : {
                              'id': sessionEkskul.id,
                              'nama_ekskul': sessionEkskul.namaEkskul,
                              'jadwal': sessionEkskul.jadwal,
                              'is_open_recruitment':
                                  sessionEkskul.isOpenRecruitment,
                            });
                  // UserResource already exposes the active ekskul. Keep the
                  // home consistent with it when a stale/partial dashboard
                  // response omits the pendaftaran object.
                  final isJoined = pendaftaran != null ||
                      dashboardEkskul != null || sessionEkskul != null;
                  final hadir = (data['total_hadir'] as num?)?.toInt() ?? 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isJoined)
                        _NotJoinedCard(
                          onExplore: () =>
                              ref.read(shellTabProvider.notifier).set(1),
                        )
                      else
                        _JoinedEkskulCard(
                          ekskul: ekskul,
                          onTap: ekskul['id'] != null
                              ? () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => EkskulDetailScreen(
                                        ekskulId:
                                            (ekskul['id'] as num).toInt(),
                                      ),
                                    ),
                                  )
                              : null,
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Total Hadir',
                              value: '$hadir',
                              icon: Icons.check_circle_outline,
                              color: const Color(0xFF16803C),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              label: 'Notifikasi',
                              value:
                                  '${(data['unread_notif_count'] as num?)?.toInt() ?? 0}',
                              icon: Icons.notifications_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const SectionTitle('Kegiatan Mendatang'),
                      const SizedBox(height: 8),
                      _KegiatanMendatang(data: data),
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
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Text(
              user.namaTampilan.isEmpty ? '?' : user.namaTampilan[0],
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 22,
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
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.siswa?.kelas?.nama.isNotEmpty == true
                      ? '${user.siswa!.kelas!.nama} · NIS ${user.siswa!.nis}'
                      : 'NIS ${user.siswa?.nis ?? '-'}',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotJoinedCard extends StatelessWidget {
  const _NotJoinedCard({required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kamu belum bergabung dengan ekskul apapun',
            style: GoogleFonts.inter(
              color: AppTheme.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Jelajahi katalog ekskul dan temukan kegiatan yang cocok untukmu.',
            style: GoogleFonts.inter(
              color: AppTheme.sub,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onExplore,
            child: const Text('Jelajahi Ekskul'),
          ),
        ],
      ),
    );
  }
}

class _JoinedEkskulCard extends StatelessWidget {
  const _JoinedEkskulCard({required this.ekskul, this.onTap});

  final Map<String, dynamic> ekskul;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nama = ekskul['nama_ekskul'] as String? ?? 'Ekskul';
    final jadwal = ekskul['jadwal'] as String?;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nama,
                  style: GoogleFonts.inter(
                    color: AppTheme.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusChip(ekskul['is_open_recruitment'] == true
                  ? 'Buka Pendaftaran'
                  : 'Tutup'),
            ],
          ),
          if (jadwal != null && jadwal.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, color: AppTheme.sub, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    jadwal,
                    style: GoogleFonts.inter(
                      color: AppTheme.sub,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Ekskul aktif kamu',
                style: GoogleFonts.inter(
                  color: AppTheme.sub,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (onTap != null)
                TextButton(
                  onPressed: onTap,
                  child: const Text('Detail'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KegiatanMendatang extends StatelessWidget {
  const _KegiatanMendatang({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final list = listOf(data, 'kegiatan_mendatang');
    if (list.isEmpty) {
      return const EmptyState(
        title: 'Belum ada kegiatan mendatang',
        icon: Icons.event_available_outlined,
      );
    }
    return Column(
      children: [
        for (final raw in list)
          _KegiatanCard(kegiatan: Kegiatan.fromJson(raw)),
      ],
    );
  }
}

class _KegiatanCard extends StatelessWidget {
  const _KegiatanCard({required this.kegiatan});

  final Kegiatan kegiatan;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event, color: AppTheme.blue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kegiatan.materi,
                  style: GoogleFonts.inter(
                    color: AppTheme.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  kegiatan.tanggalText,
                  style: GoogleFonts.inter(
                    color: AppTheme.sub,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (kegiatan.isEvent) const StatusChip('Event'),
        ],
      ),
    );
  }
}
