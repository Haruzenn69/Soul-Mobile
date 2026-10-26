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
    final selectedEkskulId = ref.watch(selectedSiswaEkskulProvider);
    final value = ref.watch(siswaPengajuanProvider(selectedEkskulId));
    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Keluar')),
      body: ApiAsyncView(
        value: value,
        onRetry: () => ref.invalidate(siswaPengajuanProvider(selectedEkskulId)),
        builder: (context, data) {
          final activeEkskuls = listOf(data, 'active_ekskuls');
          final ekskul = data['ekskul'] is Map
              ? Map<String, dynamic>.from(data['ekskul'] as Map)
              : null;
          final ekskulId = selectedEkskulId ?? (ekskul?['id'] as num?)?.toInt();
          final items = listOf(data, 'pengajuans');
          final hasPending = items.any((item) {
            if (item['status'] != 'pending') return false;
            final itemEkskulId =
                (item['ekskul_id'] as num?)?.toInt() ??
                (item['ekskul'] is Map
                    ? ((item['ekskul'] as Map)['id'] as num?)?.toInt()
                    : null);
            return ekskulId == null || itemEkskulId == ekskulId;
          });

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              ActiveEkskulSelector(
                ekskuls: activeEkskuls,
                selectedId: ekskulId,
                onChanged: (id) =>
                    ref.read(selectedSiswaEkskulProvider.notifier).select(id),
              ),
              if (ekskul != null) ...[
                const SizedBox(height: 8),
                SectionTitle('Form Pengajuan'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.outline(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _alasan,
                        maxLines: 4,
                        maxLength: 1000,
                        decoration: InputDecoration(
                          labelText: 'Alasan mengajukan keluar',
                          hintText: 'Jelaskan alasanmu secara singkat',
                          helperText:
                              'Minimal 10 karakter dan 2 kata bermakna.',
                          prefixIcon: Icon(
                            Icons.edit_note_outlined,
                            color: AppTheme.mutedText(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: hasPending || _sending || ekskulId == null
                              ? null
                              : () => _submit(ekskulId),
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
                            color: AppTheme.warningSurface(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.warningBorder(context),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.hourglass_top,
                                color: AppTheme.warningText(context),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ada pengajuan yang masih menunggu persetujuan ketua.',
                                  style: TextStyle(
                                    color: AppTheme.warningText(context),
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
                        color: AppTheme.surface(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.outline(context)),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item['alasan'] as String? ?? '-',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.text(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          [
                                if (item['ekskul'] is Map)
                                  (item['ekskul'] as Map)['nama_ekskul']
                                      ?.toString(),
                                item['tanggal_pengajuan'] as String? ?? '-',
                              ]
                              .where(
                                (value) => value != null && value.isNotEmpty,
                              )
                              .join(' · '),
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.mutedText(context),
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

  Future<void> _submit(int ekskulId) async {
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
          .post(
            '/siswa/pengajuan-keluar',
            data: {'alasan': alasan, 'ekskul_id': ekskulId},
          );
      _alasan.clear();
      ref.invalidate(siswaPengajuanProvider(ekskulId));
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
