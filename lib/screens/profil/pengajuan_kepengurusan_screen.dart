import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Halaman untuk mengajukan perubahan atau penambahan struktur pengurus ekstrakurikuler.
class PengajuanKepengurusanScreen extends ConsumerStatefulWidget {
  const PengajuanKepengurusanScreen({super.key});

  @override
  ConsumerState<PengajuanKepengurusanScreen> createState() =>
      _PengajuanKepengurusanScreenState();
}

class _PengajuanKepengurusanScreenState
    extends ConsumerState<PengajuanKepengurusanScreen> {
  final _namaSiswa = TextEditingController();
  final _nisSiswa = TextEditingController();
  String _jabatanTarget = 'wakil';
  final _alasan = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _namaSiswa.dispose();
    _nisSiswa.dispose();
    _alasan.dispose();
    super.dispose();
  }

  Future<void> _submit(int ekskulId) async {
    if (_namaSiswa.text.trim().isEmpty || _alasan.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi data dan alasan (minimal 10 karakter).'),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await ref.read(apiClientProvider).post(
        '/siswa/pengajuan-kepengurusan',
        data: {
          'ekskul_id': ekskulId,
          'nama_siswa': _namaSiswa.text.trim(),
          'nis': _nisSiswa.text.trim(),
          'jabatan': _jabatanTarget,
          'alasan': _alasan.text.trim(),
        },
      );
      _namaSiswa.clear();
      _nisSiswa.clear();
      _alasan.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan kepengurusan berhasil dikirim ke pembina/admin.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, ref, e);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedEkskulId = ref.watch(selectedSiswaEkskulProvider);
    final value = ref.watch(siswaDashboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Kepengurusan')),
      body: ApiAsyncView(
        value: value,
        onRetry: () => ref.invalidate(siswaDashboardProvider),
        builder: (context, data) {
          final activeEkskuls = listOf(data, 'active_ekskuls');
          final ekskul = data['ekskul'] is Map
              ? Map<String, dynamic>.from(data['ekskul'] as Map)
              : null;
          final ekskulId = selectedEkskulId ?? (ekskul?['id'] as num?)?.toInt();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              ActiveEkskulSelector(
                ekskuls: activeEkskuls,
                selectedId: ekskulId,
                onChanged: (id) =>
                    ref.read(selectedSiswaEkskulProvider.notifier).select(id),
              ),
              const SizedBox(height: 8),
              const SectionTitle('Form Pengajuan Perubahan Pengurus'),
              const SizedBox(height: 4),
              Text(
                'Ajukan penambahan atau perubahan struktur jabatan pengurus ekstrakurikuler.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.mutedText(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outline(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _namaSiswa,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap Siswa',
                        hintText: 'Nama siswa yang diajukan',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _nisSiswa,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'NIS / NISN',
                        hintText: 'Nomor Induk Siswa',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _jabatanTarget,
                      decoration: const InputDecoration(
                        labelText: 'Target Jabatan',
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'wakil', child: Text('Wakil Ketua')),
                        DropdownMenuItem(value: 'sekretaris', child: Text('Sekretaris')),
                        DropdownMenuItem(value: 'bendahara', child: Text('Bendahara')),
                        DropdownMenuItem(value: 'koordinator', child: Text('Koordinator Bidang')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _jabatanTarget = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _alasan,
                      maxLines: 4,
                      maxLength: 1000,
                      decoration: const InputDecoration(
                        labelText: 'Alasan / Keterangan Pengajuan',
                        hintText: 'Jelaskan mengapa perubahan ini diajukan',
                        helperText: 'Minimal 10 karakter.',
                        prefixIcon: Icon(Icons.edit_note_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _sending || ekskulId == null
                            ? null
                            : () => _submit(ekskulId),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: Text(_sending ? 'Mengirim...' : 'Kirim Pengajuan'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
