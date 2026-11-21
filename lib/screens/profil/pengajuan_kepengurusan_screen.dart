import 'package:material_ui/material_ui.dart';
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
  int? _selectedSiswaId;
  String _selectedNama = '';
  String _selectedNis = '';
  String _jabatanTarget = 'wakil_ketua';
  final _alasan = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _alasan.dispose();
    super.dispose();
  }

  Future<void> _submit(int ekskulId, BuildContext modalContext) async {
    if (_selectedSiswaId == null || _alasan.text.trim().length < 10) {
      ScaffoldMessenger.of(modalContext).showSnackBar(
        const SnackBar(
          content: Text('Pilih anggota dan isi alasan minimal 10 karakter.'),
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
              'siswa_id': _selectedSiswaId,
              'nama_siswa': _selectedNama,
              'nis': _selectedNis,
              'jabatan': _jabatanTarget,
              'alasan': _alasan.text.trim(),
            },
          );
      _alasan.clear();
      _selectedSiswaId = null;
      _selectedNama = '';
      _selectedNis = '';
      if (!mounted) return;
      ref.invalidate(siswaDashboardProvider);
      if (!modalContext.mounted) return;
      Navigator.of(modalContext).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pengajuan kepengurusan berhasil dikirim ke pembina/admin.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(modalContext).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '').trim()),
          backgroundColor: const Color(0xFFE11D48),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  List<DropdownMenuItem<int>> _memberDropdownItems(
    List<Map<String, dynamic>> members,
  ) {
    final items = <DropdownMenuItem<int>>[];
    for (final member in members) {
      if (member['siswa'] is! Map) continue;
      final siswa = Map<String, dynamic>.from(member['siswa'] as Map);
      final id = (siswa['id'] as num?)?.toInt();
      if (id == null) continue;
      final name = siswa['nama']?.toString() ?? '';
      final nis = siswa['nis']?.toString() ?? '';
      items.add(
        DropdownMenuItem<int>(
          value: id,
          child: Text(
            name.isEmpty
                ? (nis.isEmpty ? 'Siswa' : nis)
                : nis.isEmpty
                ? name
                : '$name • NIS $nis',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    return items;
  }

  Future<void> _openProposalForm(
    int ekskulId,
    String position,
    String positionLabel,
    List<Map<String, dynamic>> members,
  ) async {
    final target = switch (position) {
      'wakil_ketua' => 'wakil_ketua',
      'sekretaris' => 'sekretaris',
      'bendahara' => 'bendahara',
      _ => null,
    };
    if (target == null) return;

    setState(() => _jabatanTarget = target);
    _selectedSiswaId = null;
    _selectedNama = '';
    _selectedNis = '';
    _alasan.clear();
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            backgroundColor: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(modalContext).height * 0.88,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surface(modalContext),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
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
                    DropdownButtonFormField<int>(
                      initialValue: _selectedSiswaId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Anggota',
                        hintText: 'Pilih anggota aktif',
                        prefixIcon: Icon(Icons.person_search_outlined),
                      ),
                      items: _memberDropdownItems(members),
                      onChanged: (id) {
                        if (id == null) return;
                        final member = members
                            .cast<Map<String, dynamic>>()
                            .firstWhere((item) {
                              final siswa = item['siswa'];
                              return siswa is Map &&
                                  (siswa['id'] as num?)?.toInt() == id;
                            }, orElse: () => const <String, dynamic>{});
                        final siswa = member['siswa'] is Map
                            ? Map<String, dynamic>.from(member['siswa'] as Map)
                            : const <String, dynamic>{};
                        setState(() {
                          _selectedSiswaId = id;
                          _selectedNama = siswa['nama']?.toString() ?? '';
                          _selectedNis = siswa['nis']?.toString() ?? '';
                        });
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
                        key: const ValueKey('submit-proposal'),
                        onPressed: _sending
                            ? null
                            : () => _submit(ekskulId, modalContext),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          _sending ? 'Mengirim...' : 'Kirim Pengajuan',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(siswaDashboardProvider);
    final memberValue = ref.watch(ketuaAnggotaProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Kepengurusan')),
      body: ApiAsyncView(
        value: value,
        onRetry: () => ref.invalidate(siswaDashboardProvider),
        builder: (context, data) {
          final members = memberValue.hasValue
              ? listOf(memberValue.value, 'anggotas')
                    .where((item) {
                      final status = item['status']?.toString().toLowerCase();
                      return status == null ||
                          status == 'aktif' ||
                          status == 'diterima';
                    })
                    .map(Map<String, dynamic>.from)
                    .toList()
              : <Map<String, dynamic>>[];
          final pengurusByJabatan = {
            for (final pengurus in listOf(data, 'pengurus_aktif'))
              if (pengurus['jabatan'] != null)
                pengurus['jabatan'].toString(): pengurus,
          };
          final pengurusPendingByJabatan = {
            for (final pengurus in listOf(data, 'pengurus_pending'))
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
                  final isPending =
                      pengurusPendingByJabatan[position.$1] != null;
                  return _LeadershipPositionCard(
                    position: position,
                    assignment:
                        pengurusByJabatan[position.$1] ??
                        pengurusPendingByJabatan[position.$1],
                    onSuggest:
                        ekskulId == null || position.$1 == 'ketua' || isPending
                        ? null
                        : () => _openProposalForm(
                            ekskulId,
                            position.$1,
                            position.$2,
                            members,
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
    final isPending =
        assignment?['status']?.toString().toLowerCase() == 'menunggu';

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
                Icon(
                  Icons.circle,
                  size: 7,
                  color: isPending
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF34C99A),
                ),
                const SizedBox(width: 4),
                Text(
                  isPending ? 'Pending' : 'Aktif',
                  style: GoogleFonts.plusJakartaSans(
                    color: isPending
                        ? AppTheme.warningText(context)
                        : AppTheme.successText(context),
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
                            ? (isPending
                                  ? 'Menunggu persetujuan pembina'
                                  : 'Pengurus aktif')
                            : (isPending
                                  ? 'Diusulkan: ${DateFormat('d MMM yyyy').format(assignedAt)}'
                                  : 'Ditetapkan: ${DateFormat('d MMM yyyy').format(assignedAt)}'),
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
                side: BorderSide(
                  color: isPending
                      ? AppTheme.outline(context)
                      : AppTheme.infoBorder(context),
                ),
                disabledBackgroundColor: AppTheme.surface(context),
                disabledForegroundColor: AppTheme.mutedText(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                position.$1 == 'ketua'
                    ? 'Ketua Ekskul (Anda)'
                    : isPending
                    ? 'Pending'
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
