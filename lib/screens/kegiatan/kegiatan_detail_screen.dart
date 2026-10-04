import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_config.dart';
import '../../core/providers.dart';
import '../../core/upload_check.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/photo_viewer.dart';
import 'presensi_input_screen.dart';

class KegiatanDetailScreen extends ConsumerStatefulWidget {
  const KegiatanDetailScreen({super.key, required this.kegiatanId});

  final int kegiatanId;

  @override
  ConsumerState<KegiatanDetailScreen> createState() =>
      _KegiatanDetailScreenState();
}

class _KegiatanDetailScreenState extends ConsumerState<KegiatanDetailScreen> {
  bool _showAllAttendance = false;

  Future<void> _editKegiatan(Kegiatan keg) async {
    final materiCtrl = TextEditingController(text: keg.materi);
    final deskripsiCtrl = TextEditingController(text: keg.deskripsi ?? '');
    final endDateCtrl = TextEditingController(text: keg.tanggalBerakhir ?? '');
    DateTime tanggal =
        DateTime.tryParse(keg.tanggalKegiatan ?? '') ?? DateTime.now();
    DateTime? tanggalBerakhir = DateTime.tryParse(keg.tanggalBerakhir ?? '');
    bool isEvent = keg.isEvent;
    XFile? photo;
    Uint8List? photoBytes;

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final dateCtrl = TextEditingController(
          text: DateFormat('yyyy-MM-dd').format(tanggal),
        );
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(
              'Edit Kegiatan',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: materiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Materi Kegiatan',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deskripsiCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateCtrl,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tanggal,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          tanggal = picked;
                          dateCtrl.text = DateFormat('yyyy-MM-dd')
                              .format(picked);
                          if (tanggalBerakhir != null &&
                              tanggalBerakhir!.isBefore(picked)) {
                            tanggalBerakhir = null;
                            endDateCtrl.clear();
                          }
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Kegiatan',
                      suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Tandai sebagai Event / Lomba',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: isEvent,
                    onChanged: (val) => setDialogState(() => isEvent = val),
                  ),
                  if (isEvent)
                    TextField(
                      controller: endDateCtrl,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tanggalBerakhir ?? tanggal,
                          firstDate: tanggal,
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            tanggalBerakhir = picked;
                            endDateCtrl.text = DateFormat('yyyy-MM-dd')
                                .format(picked);
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Tanggal berakhir (opsional)',
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (picked == null) return;
                      try {
                        final bytes = await readImageBytesChecked(
                          picked,
                          label: 'Dokumentasi kegiatan',
                        );
                        setDialogState(() {
                          photo = picked;
                          photoBytes = bytes;
                        });
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      photo?.name ?? 'Ganti dokumentasi (maks. 2 MB)',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: const Text('Simpan'),
              ),
            ],
          ),
        );
      },
    );

    if (updated != true || !mounted) {
      materiCtrl.dispose();
      deskripsiCtrl.dispose();
      endDateCtrl.dispose();
      return;
    }

    try {
      final fields = <String, dynamic>{
        'materi': materiCtrl.text.trim(),
        'deskripsi': deskripsiCtrl.text.trim(),
        'tanggal_kegiatan': DateFormat('yyyy-MM-dd').format(tanggal),
        'jenis_kegiatan': isEvent ? 'event' : null,
        'tanggal_berakhir': isEvent && tanggalBerakhir != null
            ? endDateCtrl.text
            : null,
      };
      if (photo == null) {
        await ref
            .read(apiClientProvider)
            .post('/ketua/kegiatan/${widget.kegiatanId}/update', data: fields);
      } else {
        await ref
            .read(apiClientProvider)
            .postMultipart(
              '/ketua/kegiatan/${widget.kegiatanId}/update',
              fields: fields,
              files: [
                MultipartFile.fromBytes(photoBytes!, filename: photo!.name),
              ],
              fileKeys: const ['dokumentasi'],
            );
      }
      ref.invalidate(kegiatanDetailProvider(widget.kegiatanId));
      ref.invalidate(ketuaKegiatanProvider);
      ref.invalidate(ketuaDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kegiatan berhasil diperbarui.')),
        );
      }
    } catch (e) {
      if (mounted) await showErrorDialog(context, ref, e);
    } finally {
      materiCtrl.dispose();
      deskripsiCtrl.dispose();
      endDateCtrl.dispose();
    }
  }

  Future<void> _gantiDokumentasi(Kegiatan keg) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    try {
      final bytes = await readImageBytesChecked(
        picked,
        label: 'Dokumentasi kegiatan',
      );
      final fields = <String, dynamic>{
        'materi': keg.materi.trim(),
        'deskripsi': keg.deskripsi?.trim() ?? '',
        'tanggal_kegiatan': keg.tanggalKegiatan ?? '',
        'jenis_kegiatan': keg.isEvent ? 'event' : null,
        'tanggal_berakhir': keg.isEvent ? keg.tanggalBerakhir : null,
      };
      await ref.read(apiClientProvider).postMultipart(
            '/ketua/kegiatan/${widget.kegiatanId}/update',
            fields: fields,
            files: [MultipartFile.fromBytes(bytes, filename: picked.name)],
            fileKeys: const ['dokumentasi'],
          );
      ref.invalidate(kegiatanDetailProvider(widget.kegiatanId));
      ref.invalidate(ketuaKegiatanProvider);
      ref.invalidate(ketuaDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dokumentasi berhasil diperbarui.')),
        );
      }
    } catch (e) {
      if (mounted) await showErrorDialog(context, ref, e);
    }
  }

  Future<void> _hapusKegiatan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Hapus Kegiatan?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Kegiatan beserta presensi terkait akan dihapus secara permanen.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.sub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await ref
          .read(apiClientProvider)
          .delete('/ketua/kegiatan/${widget.kegiatanId}');
      ref.invalidate(ketuaKegiatanProvider);
      ref.invalidate(ketuaDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kegiatan berhasil dihapus.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) await showErrorDialog(context, ref, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(kegiatanDetailProvider(widget.kegiatanId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kegiatan'),
        actions: [
          detail.maybeWhen(
            data: (data) {
              final keg = Kegiatan.fromJson(
                data['kegiatan'] is Map
                    ? Map<String, dynamic>.from(data['kegiatan'] as Map)
                    : null,
              );
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    _editKegiatan(keg);
                  } else if (value == 'hapus') {
                    _hapusKegiatan();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Kegiatan'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'hapus',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Color(0xFFE11D48),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Hapus Kegiatan',
                          style: GoogleFonts.plusJakartaSans(
                            color: Color(0xFFE11D48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: ApiAsyncView(
        value: detail,
        onRetry: () => ref.invalidate(kegiatanDetailProvider(widget.kegiatanId)),
        builder: (context, data) {
          final keg = Kegiatan.fromJson(
            data['kegiatan'] is Map
                ? Map<String, dynamic>.from(data['kegiatan'] as Map)
                : null,
          );
          final ringkasan = data['ringkasan'] is Map
              ? Map<String, dynamic>.from(data['ringkasan'] as Map)
              : data['rekap'] is Map
              ? Map<String, dynamic>.from(data['rekap'] as Map)
              : <String, dynamic>{};
          final presensi = (data['presensi'] as List?) ?? const [];

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(kegiatanDetailProvider(widget.kegiatanId));
              try {
                await ref
                    .read(kegiatanDetailProvider(widget.kegiatanId).future);
              } catch (_) {}
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _activityHero(keg),
                if (keg.dokumentasi?.isNotEmpty == true) ...[
                  const SizedBox(height: 14),
                  _activityContentCard(
                    title: 'Dokumentasi Kegiatan',
                    subtitle: 'Ketuk foto untuk memperbesar.',
                    icon: Icons.photo_library_outlined,
                    child: _activityPhoto(
                        AppConfig.imageUrl(keg.dokumentasi),
                        onReplace: () => _gantiDokumentasi(keg),
                      ),
                  ),
                ],
                if (keg.deskripsi?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 14),
                  _activityContentCard(
                    title: 'Tentang Kegiatan',
                    subtitle: 'Informasi tambahan kegiatan ini.',
                    icon: Icons.subject_outlined,
                    child: Text(
                      keg.deskripsi!,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.ink,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _activityContentCard(
                  title: 'Ringkasan Kehadiran',
                  subtitle: 'Rekap status kehadiran peserta kegiatan.',
                  icon: Icons.fact_check_outlined,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PresensiInputScreen(
                              kegiatanId: widget.kegiatanId,
                              materi: keg.materi,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.checklist_rtl, size: 18),
                      label: const Text('Isi Presensi'),
                    ),
                  ),
                ),
const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Hadir',
                        value:
                            '${(ringkasan['hadir'] as num?)?.toInt() ?? 0}',
                        icon: Icons.check_circle_outline,
                        color: _colorFor('hadir'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        label: 'Izin',
                        value: '${(ringkasan['izin'] as num?)?.toInt() ?? 0}',
                        icon: Icons.event_note_outlined,
                        color: _colorFor('izin'),
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
                        value: '${(ringkasan['sakit'] as num?)?.toInt() ?? 0}',
                        icon: Icons.medical_information_outlined,
                        color: _colorFor('sakit'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        label: 'Alpha',
                        value:
                            '${(ringkasan['alpha'] as num?)?.toInt() ?? 0}',
                        icon: Icons.person_off_outlined,
                        color: _colorFor('alpha'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _activityContentCard(
                  title: 'Rekap Presensi',
                  subtitle: presensi.isEmpty
                      ? 'Belum ada peserta yang mengisi presensi.'
                      : '${presensi.length} siswa tercatat pada kegiatan ini.',
                  icon: Icons.groups_2_outlined,
                  child: presensi.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Data presensi akan muncul setelah diisi.',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.sub,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            for (final p
                                in (_showAllAttendance
                                    ? presensi
                                    : presensi.take(5)))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 17,
                                        backgroundColor: AppTheme.blueBg,
                                        child: Text(
                                          _initials(p['nama']?.toString()),
                                          style: GoogleFonts.plusJakartaSans(
                                            color: AppTheme.blue,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '${p['nama'] ?? '-'}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: AppTheme.ink,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusChip('${p['status'] ?? '-'}'),
                                    ],
                                  ),
                                ),
                              ),
                            if (presensi.length > 5)
                              Align(
                                alignment: Alignment.center,
                                child: TextButton.icon(
                                  onPressed: () => setState(
                                    () => _showAllAttendance =
                                        !_showAllAttendance,
                                  ),
                                  icon: Icon(
                                    _showAllAttendance
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                  ),
                                  label: Text(
                                    _showAllAttendance
                                        ? 'Tampilkan lebih sedikit'
                                        : 'Lihat semua ${presensi.length} siswa',
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _activityHero(Kegiatan keg) {
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
                  Icons.event_available_outlined,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (keg.isEvent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Event / Lomba',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF1D4ED8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'DETAIL KEGIATAN',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            keg.materi,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 25,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.white70, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  keg.tanggalText,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activityContentCard({
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

  Widget _activityPhoto(String imageUrl, {VoidCallback? onReplace}) {
    return Semantics(
      button: true,
      label: 'Perbesar foto dokumentasi',
      child: GestureDetector(
        onTap: () => _showPhoto(context, imageUrl, onReplace: onReplace),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                width: double.infinity,
                height: 200,
                color: const Color(0xFFF1F5F9),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (_, _, _) => Container(
              width: double.infinity,
              height: 200,
              color: const Color(0xFFF1F5F9),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.broken_image_outlined,
                    color: AppTheme.sub,
                    size: 25,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Foto tidak tersedia',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.sub,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPhoto(BuildContext context, String imageUrl, {VoidCallback? onReplace}) {
    PhotoViewDialog.show(
      context,
      imageUrl: imageUrl,
      title: 'Dokumentasi Kegiatan',
      onReplace: onReplace,
    );
  }

  Color _colorFor(String key) {
    switch (key) {
      case 'hadir':
        return const Color(0xFF15803D);
      case 'izin':
        return const Color(0xFF1E5AA8);
      case 'sakit':
        return const Color(0xFFC77700);
      default:
        return const Color(0xFFE11D48);
    }
  }
}

String _initials(String? name) {
  final parts = (name ?? '').trim().split(RegExp(r'\s+'));
  if (parts.first.isEmpty) return 'S';
  final first = parts.first.substring(0, 1);
  if (parts.length == 1 || parts.last.isEmpty) return first.toUpperCase();
  return '$first${parts.last.substring(0, 1)}'.toUpperCase();
}
