import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class SiswaAktivitasScreen extends ConsumerStatefulWidget {
  const SiswaAktivitasScreen({super.key});

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
    _tabs = TabController(length: 4, vsync: this);
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text('Aktivitas', style: GoogleFonts.inter(
              color: AppTheme.ink, fontSize: 22, fontWeight: FontWeight.w900,
            )),
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

class _PresensiTab extends ConsumerWidget {
  const _PresensiTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(siswaPresensiProvider);
    return ApiAsyncView(value: value, builder: (context, data) {
      final rows = listOf(data, 'presensi');
      if (rows.isEmpty) {
        return const EmptyState(title: 'Belum ada data presensi',
            icon: Icons.fact_check_outlined);
      }
      return RefreshIndicator(
        onRefresh: () async => ref.invalidate(siswaPresensiProvider),
        child: ListView.separated(
          padding: const EdgeInsets.all(16), itemCount: rows.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final row = rows[i];
            final kegiatan = row['kegiatan'] is Map
                ? Map<String, dynamic>.from(row['kegiatan'] as Map) : {};
            return _CardRow(
              title: kegiatan['materi'] as String? ?? 'Kegiatan',
              subtitle: kegiatan['tanggal_text'] as String? ??
                  kegiatan['tanggal_kegiatan'] as String? ?? '-',
              trailing: StatusChip(row['status'] as String? ?? '-'),
            );
          },
        ),
      );
    });
  }
}

class _RekapTab extends ConsumerWidget {
  const _RekapTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(siswaRekapProvider);
    return ApiAsyncView(value: value, builder: (context, data) {
      final row = data['rekap_siswa'] is Map
          ? Map<String, dynamic>.from(data['rekap_siswa'] as Map) : null;
      if (row == null) {
        return const EmptyState(title: 'Belum ada rekap absensi',
            icon: Icons.analytics_outlined);
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(title: 'Rekap ${data['bulan'] ?? ''}', values: {
            'Hadir': row['hadir'], 'Izin': row['izin'],
            'Sakit': row['sakit'], 'Alpha': row['alpha'],
            'Kehadiran': '${row['persentase_kehadiran'] ?? 0}%',
          }),
        ],
      );
    });
  }
}

class _NilaiTab extends ConsumerWidget {
  const _NilaiTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(siswaNilaiProvider);
    return ApiAsyncView(value: value, builder: (context, data) {
      final nilai = data['penilaian'] is Map
          ? Map<String, dynamic>.from(data['penilaian'] as Map) : null;
      if (nilai == null) {
        return const EmptyState(title: 'Nilai belum tersedia',
            subtitle: 'Nilai akan tampil setelah dikirim pembina.',
            icon: Icons.workspace_premium_outlined);
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(title: nilai['periode'] as String? ?? 'Penilaian',
              values: {
            'Nilai sikap': nilai['nilai_sikap'],
            'Keaktifan': nilai['nilai_keaktifan'],
            'Keterampilan': nilai['nilai_keterampilan'],
            'Nilai akhir': nilai['nilai_akhir'],
            'Predikat': nilai['predikat'],
          }),
          if ((nilai['catatan'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Card(child: Padding(padding: const EdgeInsets.all(16), child:
              Text(nilai['catatan'] as String))),
          ],
        ],
      );
    });
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
  void dispose() { _alasan.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(siswaPengajuanProvider);
    return ApiAsyncView(value: value, builder: (context, data) {
      final items = listOf(data, 'pengajuans');
      final hasPending = items.any((e) => e['status'] == 'pending');
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (data['ekskul'] is Map) ...[
            Text('Ekskul aktif', style: GoogleFonts.inter(
              color: AppTheme.sub, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text((data['ekskul'] as Map)['nama_ekskul'] as String? ?? '-',
              style: GoogleFonts.inter(color: AppTheme.ink, fontSize: 17,
                fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            TextField(controller: _alasan, maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Alasan mengajukan keluar',
                hintText: 'Jelaskan alasanmu secara singkat'),),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: hasPending || _sending ? null : _submit,
              child: Text(_sending ? 'Mengirim...' : 'Kirim Pengajuan'),
            ),
          ] else const EmptyState(title: 'Belum terdaftar di ekskul',
              icon: Icons.exit_to_app_outlined),
          const SizedBox(height: 20),
          for (final item in items) Card(child: ListTile(
            title: Text(item['alasan'] as String? ?? '-'),
            subtitle: Text(item['tanggal_pengajuan'] as String? ?? '-'),
            trailing: StatusChip(item['status'] as String? ?? '-'),
          )),
        ],
      );
    });
  }

  Future<void> _submit() async {
    final alasan = _alasan.text.trim();
    if (alasan.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alasan wajib diisi.')));
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(apiClientProvider).post('/siswa/pengajuan-keluar',
          data: {'alasan': alasan});
      _alasan.clear();
      ref.invalidate(siswaPengajuanProvider);
      ref.invalidate(siswaDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan berhasil dikirim.')));
      }
    } catch (e) {
      if (mounted) await showErrorDialog(context, ref, e);
    } finally { if (mounted) setState(() => _sending = false); }
  }
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.title, required this.subtitle,
    required this.trailing});
  final String title, subtitle;
  final Widget trailing;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle), trailing: trailing));
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.values});
  final String title;
  final Map<String, dynamic> values;
  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.inter(fontSize: 17,
        fontWeight: FontWeight.w900, color: AppTheme.ink)),
      const SizedBox(height: 12),
      for (final entry in values.entries) Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [Expanded(child: Text(entry.key)),
          Text('${entry.value ?? '-'}', style: const TextStyle(
            fontWeight: FontWeight.w800))])),
    ])));
}
