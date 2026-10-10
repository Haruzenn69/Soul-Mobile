import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class PengajuanKeluarScreen extends ConsumerStatefulWidget {
  const PengajuanKeluarScreen({super.key});

  @override
  ConsumerState<PengajuanKeluarScreen> createState() =>
      _PengajuanKeluarScreenState();
}

class _PengajuanKeluarScreenState extends ConsumerState<PengajuanKeluarScreen> {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Keluar')),
      body: ApiAsyncView(
        value: value,
        onRetry: () => ref.invalidate(siswaPengajuanProvider),
        builder: (context, data) {
          final ekskul = data['ekskul'] is Map
              ? Map<String, dynamic>.from(data['ekskul'] as Map)
              : null;
          final items = listOf(data, 'pengajuans');
          final hasPending = items.any((e) => e['status'] == 'pending');

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (ekskul != null) ...[
                SectionTitle('Ekskul Aktif'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.line),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.explore_outlined,
                          color: AppTheme.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ekskul['nama_ekskul'] as String? ?? '-',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SectionTitle('Form Pengajuan'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _alasan,
                        maxLines: 4,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                          labelText: 'Alasan mengajukan keluar',
                          hintText: 'Jelaskan alasanmu secara singkat',
                          helperText:
                              'Minimal 10 karakter dan 2 kata bermakna.',
                          prefixIcon: Icon(
                            Icons.edit_note_outlined,
                            color: AppTheme.sub,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: hasPending || _sending ? null : _submit,
                          icon: const Icon(Icons.send_outlined, size: 18),
                          label: Text(
                            _sending ? 'Mengirim...' : 'Kirim Pengajuan',
                          ),
                        ),
                      ),
                      if (hasPending) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.hourglass_top,
                                color: Color(0xFFB45309),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ada pengajuan yang masih menunggu persetujuan ketua.',
                                  style: TextStyle(
                                    color: Color(0xFF92400E),
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ] else
                const EmptyState(
                  title: 'Belum terdaftar di ekskul',
                  subtitle: 'Kamu belum menjadi anggota ekskul manapun.',
                  icon: Icons.exit_to_app_outlined,
                ),
              SectionTitle('Riwayat Pengajuan'),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const EmptyState(
                  title: 'Belum ada pengajuan',
                  subtitle: 'Riwayat pengajuan keluar akan tampil di sini.',
                  icon: Icons.history,
                )
              else
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.line),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item['alasan'] as String? ?? '-',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          item['tanggal_pengajuan'] as String? ?? '-',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.sub,
                            fontSize: 12,
                          ),
                        ),
                        trailing: StatusChip(item['status'] as String? ?? '-'),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    final alasan = _alasan.text.trim();
    final error = _validateAlasan(alasan);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
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

  String? _validateAlasan(String alasan) {
    if (alasan.isEmpty) return 'Alasan wajib diisi.';
    if (alasan.runes.length < 10) {
      return 'Alasan minimal 10 karakter.';
    }

    final meaningfulWords = alasan
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(RegExp(r'[\s,\-.]+'))
        .where((word) => word.runes.length >= 3)
        .length;
    if (meaningfulWords < 2) {
      return 'Alasan harus berisi minimal 2 kata bermakna.';
    }
    return null;
  }
}
