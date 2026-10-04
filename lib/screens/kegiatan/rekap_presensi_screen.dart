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
  String? _selectedMonth;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ketuaRekapMonthProvider(_selectedMonth));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Kehadiran Anggota'),
        actions: [
          IconButton(
            onPressed: () => _downloadPdf(context),
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Unduh PDF',
          ),
        ],
      ),
      body: ApiAsyncView(
        value: state,
        onRetry: () => ref.invalidate(ketuaRekapMonthProvider(_selectedMonth)),
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
            padding: const EdgeInsets.all(16),
            children: [
              if (availableMonths.isNotEmpty) ...[
                Text(
                  'Pilih Periode Bulan:',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.sub,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableMonths.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final m = availableMonths[i].toString();
                      final isSelected = (_selectedMonth ?? bulan) == m;
                      return ChoiceChip(
                        label: Text(_bulanLabel(m)),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedMonth = m);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  for (final item in [
                    ('Hadir', data['total_hadir'], const Color(0xFF16803C)),
                    ('Izin', data['total_izin'], const Color(0xFF1E5AA8)),
                    ('Sakit', data['total_sakit'], const Color(0xFFC77700)),
                    ('Alpha', data['total_alpha'], const Color(0xFFE11D48)),
                  ])
                    Expanded(
                      child: StatCard(
                        label: item.$1,
                        value: '${(item.$2 as num?)?.toInt() ?? 0}',
                        color: item.$3,
                      ),
                    ),
                ],
              ),
              if (pelatih != null && presensiPelatih != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sports, color: AppTheme.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pelatih: ${pelatih['nama'] ?? '-'}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        'Hadir: ${presensiPelatih['hadir'] ?? 0} kali',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.sub,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SectionTitle('Daftar Anggota (${rows.length})'),
              const SizedBox(height: 8),
              if (rows.isEmpty)
                const EmptyState(
                  title: 'Belum ada data presensi bulan ini',
                  icon: Icons.assignment_outlined,
                )
              else
                for (final r in rows) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                r['nama'] as String? ?? '-',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.ink,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
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
                                borderRadius: BorderRadius.circular(6),
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
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _miniBadge(
                              'H',
                              r['hadir'],
                              const Color(0xFF16803C),
                            ),
                            const SizedBox(width: 6),
                            _miniBadge('I', r['izin'], const Color(0xFF1E5AA8)),
                            const SizedBox(width: 6),
                            _miniBadge(
                              'S',
                              r['sakit'],
                              const Color(0xFFC77700),
                            ),
                            const SizedBox(width: 6),
                            _miniBadge(
                              'A',
                              r['alpha'],
                              const Color(0xFFE11D48),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
            ],
          );
        },
      ),
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
