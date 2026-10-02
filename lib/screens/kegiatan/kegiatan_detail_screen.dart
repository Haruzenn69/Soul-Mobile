import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_config.dart';
import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'presensi_input_screen.dart';

class KegiatanDetailScreen extends ConsumerStatefulWidget {
  const KegiatanDetailScreen({super.key, required this.kegiatanId});

  final int kegiatanId;

  @override
  ConsumerState<KegiatanDetailScreen> createState() =>
      _KegiatanDetailScreenState();
}

class _KegiatanDetailScreenState extends ConsumerState<KegiatanDetailScreen> {
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
                      final bytes = await picked.readAsBytes();
                      setDialogState(() {
                        photo = picked;
                        photoBytes = bytes;
                      });
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(photo?.name ?? 'Ganti dokumentasi (opsional)'),
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
                  const PopupMenuItem(
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
                          style: TextStyle(color: Color(0xFFE11D48)),
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
        builder: (context, data) {
          final keg = Kegiatan.fromJson(
            data['kegiatan'] is Map
                ? Map<String, dynamic>.from(data['kegiatan'] as Map)
                : null,
          );
          final ringkasan = data['ringkasan'] is Map
              ? Map<String, dynamic>.from(data['ringkasan'] as Map)
              : <String, dynamic>{};
          final presensi = (data['presensi'] as List?) ?? const [];

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(kegiatanDetailProvider(widget.kegiatanId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  keg.materi,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.schedule, color: AppTheme.sub, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      keg.tanggalText,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.sub,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (keg.isEvent) const StatusChip('Event'),
                  ],
                ),
                if (keg.dokumentasi?.isNotEmpty == true) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      AppConfig.imageUrl(keg.dokumentasi),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 200,
                        color: Colors.black12,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
                if (keg.deskripsi?.isNotEmpty == true) ...[
                  const SizedBox(height: 14),
                  Text(
                    keg.deskripsi!,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.sub,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SectionTitle('Ringkasan Kehadiran'),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
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
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final entry in [
                      ('hadir', 'Hadir'),
                      ('izin', 'Izin'),
                      ('sakit', 'Sakit'),
                      ('alpha', 'Alpha'),
                    ])
                      Expanded(
                        child: StatCard(
                          label: entry.$2,
                          value:
                              '${(ringkasan[entry.$1] as num?)?.toInt() ?? 0}',
                          color: _colorFor(entry.$1),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                const SectionTitle('Rekap Presensi'),
                const SizedBox(height: 8),
                if (presensi.isEmpty)
                  const EmptyState(
                    title: 'Belum ada data presensi',
                    icon: Icons.assignment_outlined,
                  )
                else
                  Column(
                    children: [
                      for (final p in presensi)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
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
                                Expanded(
                                  child: Text(
                                    '${p['nama'] ?? '-'}',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.ink,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                StatusChip('${p['status'] ?? '-'}'),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _colorFor(String key) {
    switch (key) {
      case 'hadir':
        return const Color(0xFF16803C);
      case 'izin':
        return const Color(0xFF1E5AA8);
      case 'sakit':
        return const Color(0xFFC77700);
      default:
        return const Color(0xFFE11D48);
    }
  }
}
