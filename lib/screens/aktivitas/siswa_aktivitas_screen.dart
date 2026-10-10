import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/providers.dart';
import '../nilai/nilai_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

const _bulanNama = [
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

String _labelBulan(String ym) {
  final parts = ym.split('-');
  if (parts.length != 2) return ym;
  final month = int.tryParse(parts[1]);
  if (month == null || month < 1 || month > 12) return ym;
  return '${_bulanNama[month - 1]} ${parts[0]}';
}

class SiswaAktivitasScreen extends ConsumerStatefulWidget {
  const SiswaAktivitasScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<SiswaAktivitasScreen> createState() =>
      _SiswaAktivitasScreenState();
}

class _SiswaAktivitasScreenState extends ConsumerState<SiswaAktivitasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Aktivitas',
            subtitle: 'Presensi, rekap, dan nilai kegiatanmu.',
            eyebrow: 'KEGIATANMU',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: Container(
              key: const ValueKey('aktivitas-pill-tabs'),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.line),
              ),
              child: TabBar(
                key: const ValueKey('aktivitas-tab-bar'),
                controller: _tabs,
                dividerHeight: 0,
                overlayColor: WidgetStatePropertyAll(Colors.transparent),
                labelColor: AppTheme.blue,
                unselectedLabelColor: AppTheme.sub,
                indicatorColor: Colors.transparent,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppTheme.blueBg,
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                labelPadding: EdgeInsets.zero,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                tabs: const [
                  Tab(height: 30, text: 'Presensi'),
                  Tab(height: 30, text: 'Rekap'),
                  Tab(height: 30, text: 'Nilai'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [_PresensiTab(), _RekapTab(), _NilaiTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _PresensiTab extends ConsumerWidget {
  const _PresensiTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(siswaPresensiProvider);
    return ApiAsyncView(
      value: value,
      onRetry: () => ref.invalidate(siswaPresensiProvider),
      builder: (context, data) {
        final rows = listOf(data, 'presensi')
          ..sort((a, b) {
            final aKegiatan = a['kegiatan'] is Map
                ? Map<String, dynamic>.from(a['kegiatan'] as Map)
                : <String, dynamic>{};
            final bKegiatan = b['kegiatan'] is Map
                ? Map<String, dynamic>.from(b['kegiatan'] as Map)
                : <String, dynamic>{};
            return (bKegiatan['tanggal_kegiatan'] as String? ?? '').compareTo(
              aKegiatan['tanggal_kegiatan'] as String? ?? '',
            );
          });
        if (rows.isEmpty) {
          return const EmptyState(
            title: 'Belum ada data presensi',
            icon: Icons.fact_check_outlined,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(siswaPresensiProvider);
            try {
              await ref.read(siswaPresensiProvider.future);
            } catch (_) {}
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              SectionTitle('Riwayat Kegiatan (${rows.length})'),
              const SizedBox(height: 10),
              ...rows.map((row) {
                final kegiatan = row['kegiatan'] is Map
                    ? Map<String, dynamic>.from(row['kegiatan'] as Map)
                    : <String, dynamic>{};
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _AttendanceCard(
                    title: kegiatan['materi'] as String? ?? 'Kegiatan',
                    date:
                        kegiatan['tanggal_text'] as String? ??
                        kegiatan['tanggal_kegiatan'] as String? ??
                        '-',
                    status: row['status'] as String? ?? '-',
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _RekapTab extends ConsumerStatefulWidget {
  const _RekapTab();

  @override
  ConsumerState<_RekapTab> createState() => _RekapTabState();
}

class _RekapTabState extends ConsumerState<_RekapTab> {
  String? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(siswaRekapMonthProvider(_selectedMonth));
    return ApiAsyncView(
      value: value,
      onRetry: () => ref.invalidate(siswaRekapMonthProvider(_selectedMonth)),
      builder: (context, data) {
        final row = data['rekap_siswa'] is Map
            ? Map<String, dynamic>.from(data['rekap_siswa'] as Map)
            : null;
        if (row == null) {
          return const EmptyState(
            title: 'Belum ada rekap absensi',
            icon: Icons.analytics_outlined,
          );
        }
        final months = (data['available_months'] as List?) ?? const [];
        final month = data['bulan']?.toString() ?? '';
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _StudentPeriodHero(
              month: month,
              selectedMonth: _selectedMonth,
              months: months,
              onChoose: () => _showMonthPicker(months, _selectedMonth ?? month),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Hadir',
                    value: '${row['hadir'] ?? 0}',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF15803D),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: 'Izin',
                    value: '${row['izin'] ?? 0}',
                    icon: Icons.event_note_outlined,
                    color: const Color(0xFF1E5AA8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Sakit',
                    value: '${row['sakit'] ?? 0}',
                    icon: Icons.medical_information_outlined,
                    color: const Color(0xFFC77700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: 'Alpha',
                    value: '${row['alpha'] ?? 0}',
                    icon: Icons.person_off_outlined,
                    color: const Color(0xFFE11D48),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _StudentRecapCard(row: row),
          ],
        );
      },
    );
  }

  Future<void> _showMonthPicker(List months, String active) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Bulan',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih periode untuk melihat rekap kehadiran.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.sub,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: months.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final month = months[index].toString();
                    final isActive = month == active;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isActive ? AppTheme.blue : AppTheme.line,
                        ),
                      ),
                      tileColor: isActive ? AppTheme.blueBg : Colors.white,
                      title: Text(_labelBulan(month)),
                      trailing: isActive
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.blue,
                            )
                          : null,
                      onTap: () {
                        Navigator.of(context).pop();
                        setState(() => _selectedMonth = month);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NilaiTab extends StatelessWidget {
  const _NilaiTab();

  @override
  Widget build(BuildContext context) => const NilaiScreen(showAppBar: false);
}

Color _statusColor(String status) => switch (status.toLowerCase()) {
  'hadir' => const Color(0xFF15803D),
  'izin' => const Color(0xFF1E5AA8),
  'sakit' => const Color(0xFFC77700),
  'alpha' => const Color(0xFFE11D48),
  _ => AppTheme.sub,
};

Color _statusTint(String status) => _statusColor(status).withValues(alpha: 0.1);

IconData _statusIcon(String status) => switch (status.toLowerCase()) {
  'hadir' => Icons.check_circle_outline,
  'izin' => Icons.event_note_outlined,
  'sakit' => Icons.medical_information_outlined,
  'alpha' => Icons.person_off_outlined,
  _ => Icons.fact_check_outlined,
};

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.title,
    required this.date,
    required this.status,
  });

  final String title;
  final String date;
  final String status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080F172A),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _statusTint(status),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(_statusIcon(status), color: _statusColor(status)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                date,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.sub,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        StatusChip(status),
      ],
    ),
  );
}

class _StudentPeriodHero extends StatelessWidget {
  const _StudentPeriodHero({
    required this.month,
    required this.selectedMonth,
    required this.months,
    required this.onChoose,
  });

  final String month;
  final String? selectedMonth;
  final List months;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final active = selectedMonth ?? month;
    final period = active.isEmpty || active == '-' ? '' : _labelBulan(active);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.sky, Color(0xFF60A5FA), AppTheme.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.blue.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'REKAP SISWA',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 9,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'REKAP KEHADIRAN',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: months.isEmpty ? null : onChoose,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    period.isEmpty ? 'Rekap Kehadiran' : period,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (months.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.expand_more_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (months.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Ketuk untuk memilih bulan',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StudentRecapCard extends StatelessWidget {
  const _StudentRecapCard({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final rawPercentage = row['persentase_kehadiran'];
    final percentage = rawPercentage is num
        ? rawPercentage.toStringAsFixed(0)
        : rawPercentage?.toString() ?? '0';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Rekap Kehadiran Saya',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage%',
            key: const ValueKey('student-recap-percentage'),
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.blue,
              fontSize: 40,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
