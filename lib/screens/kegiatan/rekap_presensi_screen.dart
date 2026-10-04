import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/file_download.dart';
import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class RekapPresensiScreen extends ConsumerStatefulWidget {
  const RekapPresensiScreen({super.key});

  @override
  ConsumerState<RekapPresensiScreen> createState() =>
      _RekapPresensiScreenState();
}

String _bulanLabel(String ym) {
  final parts = ym.split('-');
  if (parts.length != 2) return ym;
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
  if (m == null || m < 1 || m > 12) return ym;
  return '${nama[m - 1]} ${parts[0]}';
}

class _RekapPresensiScreenState extends ConsumerState<RekapPresensiScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rekap Kehadiran Anggota')),
      body: const RekapPresensiContent(),
    );
  }
}

class RekapPresensiContent extends ConsumerStatefulWidget {
  const RekapPresensiContent({super.key});

  @override
  ConsumerState<RekapPresensiContent> createState() =>
      _RekapPresensiContentState();
}

class _RekapPresensiContentState extends ConsumerState<RekapPresensiContent> {
  String? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ketuaRekapMonthProvider(_selectedMonth));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ApiAsyncView(
            value: state,
            onRetry: () =>
                ref.invalidate(ketuaRekapMonthProvider(_selectedMonth)),
            builder: (context, data) {
              final bulan = data['bulan'] as String? ?? '-';
              final availableMonths =
                  (data['available_months'] as List?) ?? const [];
              final rows = (data['rows'] as List?) ?? const [];
              final pelatih = data['pelatih'] is Map
                  ? data['pelatih'] as Map
                  : null;
              final presensiPelatih = data['presensi_pelatih'] is Map
                  ? data['presensi_pelatih'] as Map
                  : null;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _periodHero(
                    bulan: bulan,
                    selected: _selectedMonth,
                    months: availableMonths,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Hadir',
                          value:
                              '${(data['total_hadir'] as num?)?.toInt() ?? 0}',
                          icon: Icons.check_circle_outline,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: 'Izin',
                          value:
                              '${(data['total_izin'] as num?)?.toInt() ?? 0}',
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
                          value:
                              '${(data['total_sakit'] as num?)?.toInt() ?? 0}',
                          icon: Icons.medical_information_outlined,
                          color: const Color(0xFFC77700),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatCard(
                          label: 'Alpha',
                          value:
                              '${(data['total_alpha'] as num?)?.toInt() ?? 0}',
                          icon: Icons.person_off_outlined,
                          color: const Color(0xFFE11D48),
                        ),
                      ),
                    ],
                  ),
                  if (pelatih != null && presensiPelatih != null) ...[
                    const SizedBox(height: 18),
                    _rekapCard(
                      title: 'Pelatih',
                      subtitle: 'Kehadiran pelatih selama bulan berjalan.',
                      icon: Icons.sports_outlined,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              pelatih['nama']?.toString() ?? '-',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _miniBadge(
                            'Hadir',
                            presensiPelatih['hadir'],
                            const Color(0xFF15803D),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SectionTitle('Daftar Anggota (${rows.length})'),
                  const SizedBox(height: 12),
                  if (rows.isEmpty)
                    const EmptyState(
                      title: 'Belum ada data presensi bulan ini',
                      icon: Icons.assignment_outlined,
                    )
                  else
                    for (final r in rows) ...[
                      _memberCard(r),
                      const SizedBox(height: 10),
                    ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      final saved = await saveApiFile(
        api: ref.read(apiClientProvider),
        path: '/ketua/rekap/pdf',
        fileName: 'rekap-absensi-${_selectedMonth ?? 'bulan-ini'}.pdf',
        query: _selectedMonth == null ? null : {'bulan': _selectedMonth},
      );
      if (!context.mounted) return;
      if (saved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF rekap berhasil disimpan.')),
        );
      }
    } catch (error) {
      if (context.mounted) await showErrorDialog(context, ref, error);
    }
  }

  Widget _periodHero({
    required String bulan,
    required String? selected,
    required List months,
  }) {
    final active = selected ?? bulan;
    final periodLabel = active.isEmpty || active == '-'
        ? ''
        : _bulanLabel(active);
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
              IconButton(
                onPressed: () => _downloadPdf(context),
                icon: const Icon(Icons.download_rounded, color: AppTheme.blue),
                tooltip: 'Unduh PDF',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
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
            key: const ValueKey('rekap-period-tap'),
            behavior: HitTestBehavior.opaque,
            onTap: months.isNotEmpty ? () => _pilihBulan(months, active) : null,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    periodLabel.isEmpty
                        ? 'Rekap Kehadiran Anggota'
                        : periodLabel,
                    key: const ValueKey('rekap-periode'),
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
          if (periodLabel.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Ringkasan presensi anggota ekskul setiap bulan.',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pilihBulan(List months, String active) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
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
                  itemBuilder: (ctx, i) {
                    final m = months[i].toString();
                    final isActive = m == active;
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        setState(() => _selectedMonth = m);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.blueBg
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive
                                ? AppTheme.blue
                                : const Color(0xFFE8EDF5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _bulanLabel(m),
                                style: GoogleFonts.plusJakartaSans(
                                  color: isActive
                                      ? const Color(0xFF1D4ED8)
                                      : AppTheme.ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (isActive)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.blue,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
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

  Widget _rekapCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.blue, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.sub,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _memberCard(Map<String, dynamic> r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppTheme.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r['nama'] as String? ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${r['persentase_kehadiran'] ?? 0}% Kehadiran',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Kelas: ${r['kelas'] ?? '-'}',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.sub,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _miniBadge('H', r['hadir'], const Color(0xFF15803D)),
                    const SizedBox(width: 6),
                    _miniBadge('I', r['izin'], const Color(0xFF1E5AA8)),
                    const SizedBox(width: 6),
                    _miniBadge('S', r['sakit'], const Color(0xFFC77700)),
                    const SizedBox(width: 6),
                    _miniBadge('A', r['alpha'], const Color(0xFFE11D48)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBadge(String label, dynamic count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: ${count ?? 0}',
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
