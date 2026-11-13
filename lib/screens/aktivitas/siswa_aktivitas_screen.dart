import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../data/providers.dart';
import '../nilai/nilai_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/paginated_list.dart';

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
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppTheme.outline(context)),
              ),
              child: TabBar(
                key: const ValueKey('aktivitas-tab-bar'),
                controller: _tabs,
                dividerHeight: 0,
                overlayColor: WidgetStatePropertyAll(Colors.transparent),
                labelColor: AppTheme.blue,
                unselectedLabelColor: AppTheme.mutedText(context),
                indicatorColor: Colors.transparent,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppTheme.accentSurface(context),
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

class _PresensiTab extends ConsumerStatefulWidget {
  const _PresensiTab();

  @override
  ConsumerState<_PresensiTab> createState() => _PresensiTabState();
}

class _PresensiTabState extends ConsumerState<_PresensiTab> {
  String _statusFilter = 'semua';
  String _timeSort = 'terbaru';
  bool _isAscending = true;

  @override
  Widget build(BuildContext context) {
    final selectedEkskulId = ref.watch(selectedSiswaEkskulProvider);
    final value = ref.watch(siswaPresensiProvider(selectedEkskulId));
    return ApiAsyncView(
      value: value,
      onRetry: () => ref.invalidate(siswaPresensiProvider(selectedEkskulId)),
      builder: (context, data) {
        final rawRows = listOf(data, 'presensi');
        final filtered = rawRows.where((row) {
          if (_statusFilter == 'semua') return true;
          final st = (row['status']?.toString() ?? '').toLowerCase();
          return st == _statusFilter;
        }).toList();

        final sorted = [...filtered];
        sorted.sort((a, b) {
          final aKegiatan = a['kegiatan'] is Map
              ? Map<String, dynamic>.from(a['kegiatan'] as Map)
              : <String, dynamic>{};
          final bKegiatan = b['kegiatan'] is Map
              ? Map<String, dynamic>.from(b['kegiatan'] as Map)
              : <String, dynamic>{};
          final aDate =
              DateTime.tryParse(
                aKegiatan['tanggal_kegiatan']?.toString() ?? '',
              ) ??
              DateTime(0);
          final bDate =
              DateTime.tryParse(
                bKegiatan['tanggal_kegiatan']?.toString() ?? '',
              ) ??
              DateTime(0);
          final cmp = _timeSort == 'terbaru'
              ? bDate.compareTo(aDate)
              : aDate.compareTo(bDate);
          if (cmp != 0) return cmp;
          final nameA = aKegiatan['materi']?.toString() ?? '';
          final nameB = bKegiatan['materi']?.toString() ?? '';
          return _isAscending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
        });

        if (rawRows.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              const EmptyState(
                title: 'Belum ada data presensi',
                icon: Icons.fact_check_outlined,
              ),
            ],
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(siswaPresensiProvider(selectedEkskulId));
            try {
              await ref.read(siswaPresensiProvider(selectedEkskulId).future);
            } catch (_) {}
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'terbaru' || val == 'terlama') {
                                  setState(() => _timeSort = val);
                                } else {
                                  setState(() => _statusFilter = val);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  enabled: false,
                                  child: Text(
                                    'Status Kehadiran',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'semua',
                                  child: Row(
                                    children: [
                                      Icon(
                                        _statusFilter == 'semua'
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        size: 18,
                                        color: _statusFilter == 'semua'
                                            ? AppTheme.blue
                                            : AppTheme.mutedText(context),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Semua Status'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'hadir',
                                  child: Row(
                                    children: [
                                      Icon(
                                        _statusFilter == 'hadir'
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        size: 18,
                                        color: _statusFilter == 'hadir'
                                            ? AppTheme.blue
                                            : AppTheme.mutedText(context),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Hadir'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'izin',
                                  child: Row(
                                    children: [
                                      Icon(
                                        _statusFilter == 'izin'
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        size: 18,
                                        color: _statusFilter == 'izin'
                                            ? AppTheme.blue
                                            : AppTheme.mutedText(context),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Izin'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'sakit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        _statusFilter == 'sakit'
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        size: 18,
                                        color: _statusFilter == 'sakit'
                                            ? AppTheme.blue
                                            : AppTheme.mutedText(context),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Sakit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'alpha',
                                  child: Row(
                                    children: [
                                      Icon(
                                        _statusFilter == 'alpha'
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        size: 18,
                                        color: _statusFilter == 'alpha'
                                            ? AppTheme.blue
                                            : AppTheme.mutedText(context),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Alpha'),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  enabled: false,
                                  child: Text(
                                    'Urutkan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'terbaru',
                                  child: Row(
                                    children: [
                                      Icon(
                                        _timeSort == 'terbaru'
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        size: 18,
                                        color: _timeSort == 'terbaru'
                                            ? AppTheme.blue
                                            : AppTheme.mutedText(context),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Terbaru'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'terlama',
                                  child: Row(
                                    children: [
                                      Icon(
                                        _timeSort == 'terlama'
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        size: 18,
                                        color: _timeSort == 'terlama'
                                            ? AppTheme.blue
                                            : AppTheme.mutedText(context),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Terlama'),
                                    ],
                                  ),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface(context),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppTheme.outline(context),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.tune_rounded,
                                      size: 16,
                                      color: AppTheme.blue,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Filter',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_drop_down, size: 18),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.blue,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _statusFilter == 'semua'
                                    ? 'Semua'
                                    : (_statusFilter[0].toUpperCase() +
                                          _statusFilter.substring(1)),
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.blue,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _timeSort == 'terbaru' ? 'Terbaru' : 'Terlama',
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
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: _isAscending
                          ? 'Urutkan A-Z (Klik untuk Z-A)'
                          : 'Urutkan Z-A (Klik untuk A-Z)',
                      child: InkWell(
                        onTap: () =>
                            setState(() => _isAscending = !_isAscending),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surface(context),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppTheme.outline(context),
                            ),
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
                                _isAscending
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
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
              ListCountLabel(count: sorted.length, label: 'presensi'),
              Expanded(
                child: sorted.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 24),
                        children: [
                          EmptyState(
                            title: 'Data presensi tidak ditemukan',
                            subtitle: 'Coba ubah filter status atau urutan.',
                            icon: Icons.search_off_rounded,
                          ),
                        ],
                      )
                    : PaginatedList<Map<String, dynamic>>(
                        items: sorted,
                        pageSize: 10,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        separatorBuilder: (_, _) => const SizedBox(height: 9),
                        itemBuilder: (context, row, index) {
                          final kegiatan = row['kegiatan'] is Map
                              ? Map<String, dynamic>.from(
                                  row['kegiatan'] as Map,
                                )
                              : <String, dynamic>{};
                          return _AttendanceCard(
                            title: kegiatan['materi'] as String? ?? 'Kegiatan',
                            date:
                                kegiatan['tanggal_text'] as String? ??
                                kegiatan['tanggal_kegiatan'] as String? ??
                                '-',
                            status: row['status'] as String? ?? '-',
                          );
                        },
                      ),
              ),
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
    final selectedEkskulId = ref.watch(selectedSiswaEkskulProvider);
    final params = (bulan: _selectedMonth, ekskulId: selectedEkskulId);
    final value = ref.watch(siswaRekapMonthProvider(params));
    return ApiAsyncView(
      value: value,
      onRetry: () => ref.invalidate(siswaRekapMonthProvider(params)),
      builder: (context, data) {
        final row = data['rekap_siswa'] is Map
            ? Map<String, dynamic>.from(data['rekap_siswa'] as Map)
            : null;
        if (row == null) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              const EmptyState(
                title: 'Belum ada rekap absensi',
                icon: Icons.analytics_outlined,
              ),
            ],
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
        decoration: BoxDecoration(
          color: AppTheme.surface(sheetContext),
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
                    color: AppTheme.outline(sheetContext),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Bulan',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.text(sheetContext),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih periode untuk melihat rekap kehadiran.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.mutedText(sheetContext),
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
                          color: isActive
                              ? AppTheme.blue
                              : AppTheme.outline(context),
                        ),
                      ),
                      tileColor: isActive
                          ? AppTheme.accentSurface(context)
                          : AppTheme.surface(context),
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

Color _statusColor(String status, BuildContext context) =>
    switch (status.toLowerCase()) {
      'hadir' => const Color(0xFF15803D),
      'izin' => const Color(0xFF1E5AA8),
      'sakit' => const Color(0xFFC77700),
      'alpha' => const Color(0xFFE11D48),
      _ => AppTheme.mutedText(context),
    };

Color _statusTint(String status, BuildContext context) =>
    _statusColor(status, context).withValues(alpha: 0.1);

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
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.outline(context)),
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
            color: _statusTint(status, context),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            _statusIcon(status),
            color: _statusColor(status, context),
          ),
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
                  color: AppTheme.text(context),
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
                  color: AppTheme.mutedText(context),
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
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline(context)),
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
              color: AppTheme.text(context),
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
