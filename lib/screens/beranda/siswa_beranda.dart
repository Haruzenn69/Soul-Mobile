import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/api_client.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../aktivitas/siswa_aktivitas_screen.dart';
import '../katalog/ekskul_detail_screen.dart';

const _bulanIndonesia = [
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

String _formatIndonesianDate(DateTime date) =>
    '${date.day} ${_bulanIndonesia[date.month - 1]} ${date.year}';

String _monthAbbreviation(int month) =>
    _bulanIndonesia[month - 1].substring(0, 3).toUpperCase();

class BerandaSiswa extends ConsumerWidget {
  const BerandaSiswa({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(siswaDashboardProvider);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(siswaDashboardProvider);
          ref.invalidate(siswaPresensiProvider);
          await Future.wait([
            ref.read(siswaDashboardProvider.future),
            ref.read(siswaPresensiProvider.future),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverToBoxAdapter(
                child: ApiAsyncView(
                  value: dashboard,
                  onRetry: () => ref.invalidate(siswaDashboardProvider),
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
                        ? Map<String, dynamic>.from(
                            pendaftaran!['ekskul'] as Map,
                          )
                        : dashboardEkskul ??
                              (sessionEkskul == null
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
                    final isJoined =
                        pendaftaran != null ||
                        dashboardEkskul != null ||
                        sessionEkskul != null;
                    final hadir = (data['total_hadir'] as num?)?.toInt() ?? 0;
                    final upcoming = listOf(data, 'kegiatan_mendatang');
                    final latestRegistration = data['status_terakhir'] is Map
                        ? Map<String, dynamic>.from(
                            data['status_terakhir'] as Map,
                          )
                        : null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Hero(
                          user: user,
                          isJoined: isJoined,
                          registrationStatus:
                              latestRegistration?['status'] as String?,
                          unreadNotifications:
                              (data['unread_notif_count'] as num?)?.toInt() ??
                              0,
                          onCatalog: () =>
                              ref.read(shellTabProvider.notifier).set(1),
                          onAttendance: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const _SiswaActivityPage(),
                            ),
                          ),
                          onNotifications: () =>
                              ref.read(shellTabProvider.notifier).set(3),
                        ),
                        const SizedBox(height: 14),
                        if (user.needsProfileCompletion || user.needsOnboarding)
                          _OnboardingBanner(
                            needsProfile: user.needsProfileCompletion,
                            onAction: () =>
                                _completeOnboarding(context, ref, user),
                          ),
                        if (data['is_warned'] == true)
                          _MemberNotice(
                            warning: true,
                            ekskulName: ekskul['nama_ekskul'] as String?,
                            onNotifications: () =>
                                ref.read(shellTabProvider.notifier).set(3),
                          )
                        else if (data['nonaktif_status'] != null)
                          _MemberNotice(
                            warning: false,
                            ekskulName: latestRegistration?['ekskul'] is Map
                                ? (latestRegistration!['ekskul']
                                          as Map)['nama_ekskul']
                                      as String?
                                : null,
                            inactiveStatus: data['nonaktif_status']?.toString(),
                            onNotifications: () =>
                                ref.read(shellTabProvider.notifier).set(3),
                          )
                        else if (!isJoined &&
                            (latestRegistration?['status'] == 'pending' ||
                                latestRegistration?['status'] == 'ditolak'))
                          _RegistrationNotice(
                            status: latestRegistration!['status'] as String,
                            ekskulName: latestRegistration['ekskul'] is Map
                                ? (latestRegistration['ekskul']
                                          as Map)['nama_ekskul']
                                      as String?
                                : null,
                            onNotifications: () =>
                                ref.read(shellTabProvider.notifier).set(3),
                          ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _DashboardStat(
                                label: 'Status Ekskul',
                                value: isJoined ? '1' : '0',
                                detail: isJoined ? 'Terdaftar' : 'Belum',
                                icon: Icons.groups_2_outlined,
                                color: isJoined
                                    ? const Color(0xFF15803D)
                                    : const Color(0xFFD97706),
                                tint: isJoined
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFFFBEB),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _DashboardStat(
                                label: 'Total Kehadiran',
                                value: '$hadir',
                                detail: 'Pertemuan',
                                icon: Icons.fact_check_outlined,
                                color: const Color(0xFFB45309),
                                tint: const Color(0xFFFFF7ED),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _DashboardStat(
                                label: 'Kegiatan',
                                value: '${upcoming.length}',
                                detail: 'Agenda',
                                icon: Icons.event_available_outlined,
                                color: AppTheme.blue,
                                tint: const Color(0xFFEFF6FF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        SectionTitle(
                          'Ekskul Saya',
                          action: () =>
                              ref.read(shellTabProvider.notifier).set(1),
                          actionText: 'Lihat katalog',
                        ),
                        const SizedBox(height: 8),
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
                                        ekskulId: (ekskul['id'] as num).toInt(),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        if (isJoined) ...[
                          const SizedBox(height: 8),
                          _MemberActions(
                            onAttendance: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const _SiswaActivityPage(),
                              ),
                            ),
                            onLeave: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const _SiswaActivityPage(initialTab: 3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                        ],
                        SectionTitle(
                          'Agenda Kegiatan Mendatang',
                          action: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const _SiswaActivityPage(),
                            ),
                          ),
                          actionText: 'Presensi',
                        ),
                        const SizedBox(height: 8),
                        _KegiatanMendatang(data: data),
                        const SizedBox(height: 18),
                        _AttendanceTrend(totalHadir: hadir),
                        const SizedBox(height: 18),
                        _UpcomingHighlight(items: upcoming),
                        if (ekskul['id'] is num) ...[
                          const SizedBox(height: 18),
                          _StudentFeedback(
                            ekskulId: (ekskul['id'] as num).toInt(),
                            ekskulName:
                                ekskul['nama_ekskul'] as String? ?? 'ekskul',
                            hasSubmittedTestimoni:
                                data['has_submitted_testimoni'] == true,
                          ),
                        ],
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

class _Hero extends StatelessWidget {
  const _Hero({
    required this.user,
    required this.isJoined,
    required this.registrationStatus,
    required this.unreadNotifications,
    required this.onCatalog,
    required this.onAttendance,
    required this.onNotifications,
  });

  final AuthUser user;
  final bool isJoined;
  final String? registrationStatus;
  final int unreadNotifications;
  final VoidCallback onCatalog;
  final VoidCallback onAttendance;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.sky, Color(0xFF60A5FA), AppTheme.blue],
        ),
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -32,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.11),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      user.namaTampilan.isEmpty ? '?' : user.namaTampilan[0],
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${user.namaTampilan}!',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatIndonesianDate(DateTime.now()),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.86),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unreadNotifications > 0)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: onNotifications,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.notifications_none,
                                color: Colors.white,
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$unreadNotifications',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                isJoined
                    ? 'Pantau kegiatan dan kehadiran ekskulmu.'
                    : 'Temukan kegiatan yang sesuai dengan minatmu.',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.blue,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      if (!isJoined && registrationStatus != 'pending') {
                        onCatalog();
                      } else if (registrationStatus == 'pending') {
                        onNotifications();
                      } else {
                        onAttendance();
                      }
                    },
                    icon: Icon(
                      !isJoined && registrationStatus != 'pending'
                          ? Icons.add
                          : registrationStatus == 'pending'
                          ? Icons.notifications_outlined
                          : Icons.fact_check_outlined,
                      size: 17,
                    ),
                    label: Text(
                      !isJoined && registrationStatus != 'pending'
                          ? 'Daftar Ekskul'
                          : registrationStatus == 'pending'
                          ? 'Cek Status'
                          : 'Lihat Presensi',
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onCatalog,
                    child: const Text('Jelajahi Katalog'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _completeOnboarding(
  BuildContext context,
  WidgetRef ref,
  AuthUser user,
) async {
  if (user.needsProfileCompletion) {
    ref.read(shellTabProvider.notifier).set(4);
    return;
  }
  try {
    await ref.read(apiClientProvider).post('/siswa/onboarding/complete');
    await ref.read(authControllerProvider.notifier).refreshSession();
  } catch (error) {
    if (context.mounted) await showErrorDialog(context, ref, error);
  }
}

class _DashboardStat extends StatelessWidget {
  const _DashboardStat({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    required this.tint,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.sub,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  style: GoogleFonts.plusJakartaSans(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberNotice extends StatelessWidget {
  const _MemberNotice({
    required this.warning,
    required this.ekskulName,
    required this.onNotifications,
    this.inactiveStatus,
  });

  final bool warning;
  final String? ekskulName;
  final String? inactiveStatus;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final accent = warning ? const Color(0xFFB45309) : const Color(0xFFB91C1C);
    final title = warning
        ? 'Kamu mendapatkan peringatan'
        : inactiveStatus == 'keluar'
        ? 'Kamu telah keluar dari ekskul'
        : 'Status keanggotaanmu nonaktif';
    final message = warning
        ? 'Tingkatkan keaktifan dan kehadiranmu${ekskulName == null ? '.' : ' di $ekskulName.'}'
        : inactiveStatus == 'keluar'
        ? 'Pengajuan keluar${ekskulName == null ? '' : ' dari $ekskulName'} telah disetujui.'
        : 'Hubungi ketua ekskul jika status ini kurang tepat.';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warning ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: warning ? const Color(0xFFFDE68A) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warning ? Icons.warning_amber_rounded : Icons.info_outline,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: accent, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(color: accent, fontSize: 12, height: 1.4),
                ),
                TextButton(
                  onPressed: onNotifications,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: accent,
                  ),
                  child: const Text('Lihat notifikasi'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistrationNotice extends StatelessWidget {
  const _RegistrationNotice({
    required this.status,
    required this.ekskulName,
    required this.onNotifications,
  });

  final String status;
  final String? ekskulName;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final pending = status == 'pending';
    final color = pending ? const Color(0xFF92400E) : const Color(0xFF9F1239);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pending ? const Color(0xFFFFFBEB) : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: pending ? const Color(0xFFFDE68A) : const Color(0xFFFECDD3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            pending ? Icons.hourglass_top : Icons.cancel_outlined,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pending
                  ? 'Pendaftaran${ekskulName == null ? '' : ' ke $ekskulName'} sedang menunggu persetujuan.'
                  : 'Pendaftaran${ekskulName == null ? '' : ' ke $ekskulName'} ditolak. Kamu dapat memilih ekskul lain.',
              style: TextStyle(color: color, fontSize: 12, height: 1.4),
            ),
          ),
          IconButton(
            onPressed: onNotifications,
            tooltip: 'Notifikasi',
            icon: Icon(Icons.notifications_outlined, color: color),
          ),
        ],
      ),
    );
  }
}

class _MemberActions extends StatelessWidget {
  const _MemberActions({required this.onAttendance, required this.onLeave});

  final VoidCallback onAttendance;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onAttendance,
            icon: const Icon(Icons.fact_check_outlined, size: 18),
            label: const Text('Riwayat Presensi'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onLeave,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB45309),
              side: const BorderSide(color: Color(0xFFFDE68A)),
            ),
            icon: const Icon(Icons.logout_outlined, size: 18),
            label: const Text('Ajukan Keluar'),
          ),
        ),
      ],
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
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kamu belum bergabung dengan ekskul apapun',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Jelajahi katalog ekskul dan temukan kegiatan yang cocok untukmu.',
            style: GoogleFonts.plusJakartaSans(
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
    final deskripsi = ekskul['deskripsi'] as String?;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nama,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusChip('Anggota Aktif'),
            ],
          ),
          if (deskripsi?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 7),
            Text(
              deskripsi!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.sub,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          if (jadwal != null && jadwal.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, color: AppTheme.sub, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    jadwal,
                    style: GoogleFonts.plusJakartaSans(
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
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.sub,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (onTap != null)
                TextButton(onPressed: onTap, child: const Text('Detail')),
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
        for (final raw in list) _KegiatanCard(kegiatan: Kegiatan.fromJson(raw)),
      ],
    );
  }
}

class _KegiatanCard extends StatelessWidget {
  const _KegiatanCard({required this.kegiatan});

  final Kegiatan kegiatan;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(kegiatan.tanggalKegiatan ?? '');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.sky, AppTheme.blue],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: date == null
                ? const Icon(Icons.event, color: Colors.white, size: 22)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd').format(date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        _monthAbbreviation(date.month),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kegiatan.materi,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  kegiatan.tanggalText,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.sub,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (kegiatan.isEvent)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: StatusChip('Event'),
            ),
        ],
      ),
    );
  }
}

class _AttendanceTrend extends ConsumerWidget {
  const _AttendanceTrend({required this.totalHadir});

  final int totalHadir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref.watch(siswaPresensiProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: SectionTitle('Tren Kehadiran')),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.sky, AppTheme.blue],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$totalHadir',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    'total pertemuan hadir',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.sub,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            attendance.when(
              loading: () => const LinearProgressIndicator(minHeight: 3),
              error: (error, _) => Text(
                error is ApiException
                    ? error.message
                    : 'Tren kehadiran tidak dapat dimuat.',
                style: const TextStyle(color: AppTheme.sub, fontSize: 12),
              ),
              data: (data) {
                final rows = listOf(data, 'presensi').toList()
                  ..sort((a, b) {
                    final aKegiatan = a['kegiatan'] is Map
                        ? Map<String, dynamic>.from(a['kegiatan'] as Map)
                        : <String, dynamic>{};
                    final bKegiatan = b['kegiatan'] is Map
                        ? Map<String, dynamic>.from(b['kegiatan'] as Map)
                        : <String, dynamic>{};
                    final aDate = DateTime.tryParse(
                      aKegiatan['tanggal_kegiatan'] as String? ?? '',
                    );
                    final bDate = DateTime.tryParse(
                      bKegiatan['tanggal_kegiatan'] as String? ?? '',
                    );
                    return (aDate ?? DateTime(1970)).compareTo(
                      bDate ?? DateTime(1970),
                    );
                  });
                final recentRows = rows.length > 8
                    ? rows.sublist(rows.length - 8)
                    : rows;
                if (recentRows.isEmpty) {
                  return const Text(
                    'Riwayat kehadiran akan muncul setelah presensi kegiatan dicatat.',
                    style: TextStyle(
                      color: AppTheme.sub,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  );
                }
                return Column(
                  children: [
                    SizedBox(
                      height: 76,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final row in recentRows)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: row['status'] == 'hadir'
                                          ? 42
                                          : 18,
                                      decoration: BoxDecoration(
                                        color: row['status'] == 'hadir'
                                            ? AppTheme.blue
                                            : const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      row['status']?.toString() ?? '-',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppTheme.sub,
                                        fontSize: 8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('Lihat riwayat presensi'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const _SiswaActivityPage(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingHighlight extends StatelessWidget {
  const _UpcomingHighlight({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    final closest = items.isEmpty ? null : Kegiatan.fromJson(items.first);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Kegiatan Terdekat'),
            const SizedBox(height: 10),
            if (closest == null)
              const Text(
                'Belum ada agenda mendatang. Agenda ekskul akan muncul di sini.',
                style: TextStyle(color: AppTheme.sub, fontSize: 12),
              )
            else
              _KegiatanCard(kegiatan: closest),
          ],
        ),
      ),
    );
  }
}

class _SiswaActivityPage extends StatelessWidget {
  const _SiswaActivityPage({this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aktivitas')),
      body: SiswaAktivitasScreen(initialTab: initialTab),
    );
  }
}

class _StudentFeedback extends ConsumerStatefulWidget {
  const _StudentFeedback({
    required this.ekskulId,
    required this.ekskulName,
    required this.hasSubmittedTestimoni,
  });

  final int ekskulId;
  final String ekskulName;
  final bool hasSubmittedTestimoni;

  @override
  ConsumerState<_StudentFeedback> createState() => _StudentFeedbackState();
}

class _StudentFeedbackState extends ConsumerState<_StudentFeedback> {
  bool _sending = false;

  Future<void> _send({required bool question}) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(question ? 'Tanya Ketua' : 'Beri Testimoni'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: question ? 3 : 4,
          maxLength: question ? 255 : 2000,
          decoration: InputDecoration(
            hintText: question
                ? 'Tulis pertanyaanmu...'
                : 'Ceritakan pengalamanmu di ${widget.ekskulName}...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || !mounted) return;

    setState(() => _sending = true);
    try {
      await ref
          .read(apiClientProvider)
          .post(
            '/catalog/${widget.ekskulId}/${question ? 'faq' : 'testimoni'}',
            data: {question ? 'pertanyaan' : 'quote': text},
          );
      ref.invalidate(siswaDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              question
                  ? 'Pertanyaan dikirim untuk dijawab ketua.'
                  : 'Testimoni dikirim untuk ditinjau ketua.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) await showErrorDialog(context, ref, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('Beri Testimoni & Tanya'),
            const SizedBox(height: 2),
            Text(
              'Sampaikan pendapatmu untuk ekskul ${widget.ekskulName}.',
              style: const TextStyle(color: AppTheme.sub, fontSize: 12),
            ),
            if (widget.hasSubmittedTestimoni) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppTheme.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Testimoni sudah dikirim. Menunggu persetujuan ketua atau sudah tampil di katalog.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (!widget.hasSubmittedTestimoni)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _sending ? null : () => _send(question: false),
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  label: const Text('Kirim testimoni'),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : () => _send(question: true),
                icon: const Icon(Icons.help_outline, size: 18),
                label: const Text('Tanyakan ke ketua'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingBanner extends StatelessWidget {
  const _OnboardingBanner({required this.needsProfile, required this.onAction});

  final bool needsProfile;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: Color(0xFFB45309), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  needsProfile
                      ? 'Lengkapi Data Diri Kamu'
                      : 'Selamat Datang di SOUL!',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF92400E),
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            needsProfile
                ? 'Data profil (jenis kelamin & kontak) diperlukan agar pendaftaran ekskul dapat diproses.'
                : 'Jelajahi berbagai pilihan ekskul menarik dan ikuti kegiatan seru di sekolah.',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF78350F),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB45309),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: onAction,
              child: Text(needsProfile ? 'Lengkapi Profil' : 'Mengerti'),
            ),
          ),
        ],
      ),
    );
  }
}
