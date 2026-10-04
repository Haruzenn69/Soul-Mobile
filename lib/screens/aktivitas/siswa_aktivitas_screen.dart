import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

const _bulanPendek = [
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

String _labelBulan(String ym) {
  final parts = ym.split('-');
  if (parts.length != 2) return ym;
  final month = int.tryParse(parts[1]);
  if (month == null || month < 1 || month > 12) return ym;
  return '${_bulanPendek[month - 1]} ${parts[0]}';
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
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 3),
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
            subtitle: 'Presensi, rekap, nilai, dan pengajuan ekskul.',
            eyebrow: 'KEGIATANMU',
          ),
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppTheme.blue,
            tabs: const [
              Tab(text: 'Presensi'),
              Tab(text: 'Rekap'),
              Tab(text: 'Nilai'),
              Tab(text: 'Pengajuan'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                _PresensiTab(),
                _RekapTab(),
                _NilaiTab(),
                _PengajuanTab(),
              ],
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
  String _search = '';
  String? _month;

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(siswaPresensiProvider);
    return ApiAsyncView(
      value: value,
      onRetry: () => ref.invalidate(siswaPresensiProvider),
      builder: (context, data) {
        final rows = listOf(data, 'presensi');
        if (rows.isEmpty) {
          return const EmptyState(
            title: 'Belum ada data presensi',
            icon: Icons.fact_check_outlined,
          );
        }
        final months =
            rows
                .map((row) {
                  final kegiatan = row['kegiatan'] is Map
                      ? Map<String, dynamic>.from(row['kegiatan'] as Map)
                      : <String, dynamic>{};
                  final date = kegiatan['tanggal_kegiatan'] as String? ?? '';
                  return date.length >= 7 ? date.substring(0, 7) : null;
                })
                .whereType<String>()
                .toSet()
                .toList()
              ..sort((a, b) => b.compareTo(a));
        final filteredRows = rows.where((row) {
          final kegiatan = row['kegiatan'] is Map
              ? Map<String, dynamic>.from(row['kegiatan'] as Map)
              : <String, dynamic>{};
          final materi = (kegiatan['materi'] as String? ?? '').toLowerCase();
          final date = kegiatan['tanggal_kegiatan'] as String? ?? '';
          return materi.contains(_search.trim().toLowerCase()) &&
              (_month == null || date.startsWith(_month!));
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(siswaPresensiProvider);
            try {
              await ref.read(siswaPresensiProvider.future);
            } catch (_) {}
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Cari kegiatan',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
              if (months.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: months.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final month = index == 0 ? null : months[index - 1];
                      return ChoiceChip(
                        label: Text(month == null ? 'Semua bulan' : _labelBulan(month)),
                        selected: _month == month,
                        onSelected: (selected) {
                          if (selected) setState(() => _month = month);
                        },
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (filteredRows.isEmpty)
                const EmptyState(
                  title: 'Presensi tidak ditemukan',
                  icon: Icons.search_off,
                )
              else
                ...filteredRows.map((row) {
                  final kegiatan = row['kegiatan'] is Map
                      ? Map<String, dynamic>.from(row['kegiatan'] as Map)
                      : <String, dynamic>{};
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _CardRow(
                      title: kegiatan['materi'] as String? ?? 'Kegiatan',
                      subtitle:
                          kegiatan['tanggal_text'] as String? ??
                          kegiatan['tanggal_kegiatan'] as String? ??
                          '-',
                      trailing: StatusChip(row['status'] as String? ?? '-'),
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
        final row = data['rekap'] is Map
            ? Map<String, dynamic>.from(data['rekap'] as Map)
            : null;
        if (row == null) {
          return const EmptyState(
            title: 'Belum ada rekap absensi',
            icon: Icons.analytics_outlined,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (data['available_months'] is List &&
                (data['available_months'] as List).isNotEmpty) ...[
              const Text('Pilih periode'),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: (data['available_months'] as List).length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final month = (data['available_months'] as List)[index]
                        .toString();
                    return ChoiceChip(
                      label: Text(_labelBulan(month)),
                      selected: (_selectedMonth ?? data['bulan']) == month,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedMonth = month);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            _SummaryCard(
              title: 'Rekap ${_labelBulan(data['bulan']?.toString() ?? '')}',
              values: {
                'Hadir': row['hadir'],
                'Izin': row['izin'],
                'Sakit': row['sakit'],
                'Alpha': row['alpha'],
                'Kehadiran': '${row['persentase_kehadiran'] ?? 0}%',
              },
            ),
          ],
        );
      },
    );
  }
}

class _NilaiTab extends ConsumerWidget {
  const _NilaiTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(siswaNilaiProvider);
    return ApiAsyncView(
      value: value,
      onRetry: () => ref.invalidate(siswaNilaiProvider),
      builder: (context, data) {
        final nilai = data['penilaian'] is Map
            ? Map<String, dynamic>.from(data['penilaian'] as Map)
            : null;
        if (nilai == null) {
          return const EmptyState(
            title: 'Nilai belum tersedia',
            subtitle: 'Nilai akan tampil setelah dikirim pembina.',
            icon: Icons.workspace_premium_outlined,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryCard(
              title: nilai['periode'] as String? ?? 'Penilaian',
              values: {
                'Nilai sikap': nilai['nilai_sikap'],
                'Keaktifan': nilai['nilai_keaktifan'],
                'Keterampilan': nilai['nilai_keterampilan'],
                'Nilai akhir': nilai['nilai_akhir'],
                'Predikat': nilai['predikat'],
              },
            ),
            if ((nilai['catatan'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(nilai['catatan'] as String),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PengajuanTab extends ConsumerStatefulWidget {
  const _PengajuanTab();

  @override
  ConsumerState<_PengajuanTab> createState() => _PengajuanTabState();
}

class _PengajuanTabState extends ConsumerState<_PengajuanTab> {
  final _alasan = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _alasan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(siswaPengajuanProvider);
    return ApiAsyncView(
      value: value,
      onRetry: () => ref.invalidate(siswaPengajuanProvider),
      builder: (context, data) {
        final items = listOf(data, 'pengajuans');
        final hasPending = items.any((e) => e['status'] == 'pending');
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (data['ekskul'] is Map) ...[
              Text(
                'Ekskul aktif',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.sub,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (data['ekskul'] as Map)['nama_ekskul'] as String? ?? '-',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _alasan,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Alasan mengajukan keluar',
                  hintText: 'Jelaskan alasanmu secara singkat',
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: hasPending || _sending ? null : _submit,
                child: Text(_sending ? 'Mengirim...' : 'Kirim Pengajuan'),
              ),
            ] else
              const EmptyState(
                title: 'Belum terdaftar di ekskul',
                icon: Icons.exit_to_app_outlined,
              ),
            const SizedBox(height: 20),
            for (final item in items)
              Card(
                child: ListTile(
                  title: Text(item['alasan'] as String? ?? '-'),
                  subtitle: Text(item['tanggal_pengajuan'] as String? ?? '-'),
                  trailing: StatusChip(item['status'] as String? ?? '-'),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    final alasan = _alasan.text.trim();
    if (alasan.length < 3) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Alasan wajib diisi.')));
      return;
    }
    setState(() => _sending = true);
    try {
      await ref
          .read(apiClientProvider)
          .post('/siswa/pengajuan-keluar', data: {'alasan': alasan});
      _alasan.clear();
      ref.invalidate(siswaPengajuanProvider);
      ref.invalidate(siswaDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan berhasil dikirim.')),
        );
      }
    } catch (e) {
      if (mounted) await showErrorDialog(context, ref, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
  final String title, subtitle;
  final Widget trailing;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: trailing,
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.values});
  final String title;
  final Map<String, dynamic> values;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in values.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(entry.key)),
                  Text(
                    '${entry.value ?? '-'}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
