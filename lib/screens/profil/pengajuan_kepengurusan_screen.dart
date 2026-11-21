import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_config.dart';
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

  Future<void> _submit(int ekskulId, BuildContext modalContext) async {
    if (_namaSiswa.text.trim().isEmpty || _alasan.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mohon lengkapi data dan alasan (minimal 10 karakter).',
          ),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      await ref
          .read(apiClientProvider)
          .post(
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
      ref.invalidate(siswaDashboardProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pengajuan kepengurusan berhasil dikirim ke pembina/admin.',
          ),
        ),
      );
      if (!modalContext.mounted) return;
      Navigator.of(modalContext).pop();
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, ref, e);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openProposalForm(
    int ekskulId,
    String position,
    String positionLabel,
  ) async {
    final target = switch (position) {
      'wakil_ketua' => 'wakil',
      'sekretaris' => 'sekretaris',
      'bendahara' => 'bendahara',
      _ => null,
    };
    if (target == null) return;

    setState(() => _jabatanTarget = target);
    _namaSiswa.clear();
    _nisSiswa.clear();
    _alasan.clear();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(modalContext).bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(modalContext).height * 0.88,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surface(modalContext),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.outline(modalContext),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Usulkan ${positionLabel.toLowerCase()}',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.text(modalContext),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Masukkan data siswa yang diusulkan sebagai $positionLabel.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.mutedText(modalContext),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
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
                    onPressed: _sending
                        ? null
                        : () => _submit(ekskulId, modalContext),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(_sending ? 'Mengirim...' : 'Kirim Pengajuan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(siswaDashboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Kepengurusan')),
      body: ApiAsyncView(
        value: value,
        onRetry: () => ref.invalidate(siswaDashboardProvider),
        builder: (context, data) {
          final pengurusByJabatan = {
            for (final pengurus in listOf(data, 'pengurus_aktif'))
              if (pengurus['jabatan'] != null)
                pengurus['jabatan'].toString(): pengurus,
          };
          final ekskul = data['ekskul'] is Map
              ? Map<String, dynamic>.from(data['ekskul'] as Map)
              : null;
          final ekskulId = (ekskul?['id'] as num?)?.toInt();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              SectionTitle('Pengurus ${ekskul?['nama_ekskul'] ?? 'Ekskul'}'),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _leadershipPositions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 286,
                ),
                itemBuilder: (context, index) {
                  final position = _leadershipPositions[index];
                  return _LeadershipPositionCard(
                    position: position,
                    assignment: pengurusByJabatan[position.$1],
                    onSuggest: ekskulId == null || position.$1 == 'ketua'
                        ? null
                        : () => _openProposalForm(
                            ekskulId,
                            position.$1,
                            position.$2,
                          ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

const _leadershipPositions = [
  ('ketua', 'Ketua'),
  ('wakil_ketua', 'Wakil Ketua'),
  ('sekretaris', 'Sekretaris'),
  ('bendahara', 'Bendahara'),
];

class _LeadershipPositionCard extends StatelessWidget {
  const _LeadershipPositionCard({
    required this.position,
    required this.assignment,
    required this.onSuggest,
  });

  final (String, String) position;
  final Map<String, dynamic>? assignment;
  final VoidCallback? onSuggest;

  @override
  Widget build(BuildContext context) {
    final siswa = assignment?['siswa'] is Map
        ? Map<String, dynamic>.from(assignment!['siswa'] as Map)
        : null;
    final name = siswa?['nama']?.toString() ?? '';
    final kelas = siswa?['kelas'] is Map
        ? (siswa!['kelas'] as Map)['nama']?.toString()
        : null;
    final foto = siswa?['foto']?.toString().trim();
    final assignedAt = DateTime.tryParse(
      assignment?['created_at']?.toString() ?? '',
    );
    final isOccupied = siswa != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.infoBorder(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.blue.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.infoSurface(context),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      position.$2.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.infoText(context),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isOccupied) ...[
                const Icon(Icons.circle, size: 7, color: Color(0xFF34C99A)),
                const SizedBox(width: 4),
                Text(
                  'Aktif',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.successText(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ] else
                Text(
                  'Kosong',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.mutedText(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isOccupied
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 76,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.blue, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: foto != null && foto.isNotEmpty
                              ? Image.network(
                                  AppConfig.imageUrl(foto),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _avatarFallback(context, name),
                                )
                              : _avatarFallback(context, name),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.text(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (siswa['nis'] != null) 'NIS ${siswa['nis']}',
                          if (kelas != null && kelas.isNotEmpty) kelas,
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.mutedText(context),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        assignedAt == null
                            ? 'Pengurus aktif'
                            : 'Ditetapkan: ${DateFormat('d MMM yyyy').format(assignedAt)}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.mutedText(context),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  )
                : Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.infoSurface(context)
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.outline(context),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add_alt_1_outlined,
                          size: 24,
                          color: AppTheme.blue,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Belum Ada Pengurus',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.text(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Posisi ${position.$2} kosong.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.mutedText(context),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              key: ValueKey('leadership-position-${position.$1}'),
              onPressed: onSuggest,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(34),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                side: BorderSide(color: AppTheme.infoBorder(context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                position.$1 == 'ketua'
                    ? 'Ketua Ekskul (Anda)'
                    : isOccupied
                    ? 'Usulkan Calon Lain'
                    : 'Usulkan Siswa',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(BuildContext context, String name) => Container(
    color: AppTheme.infoSurface(context),
    alignment: Alignment.center,
    child: Text(
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        color: AppTheme.infoText(context),
        fontWeight: FontWeight.w800,
        fontSize: 24,
      ),
    ),
  );
}
