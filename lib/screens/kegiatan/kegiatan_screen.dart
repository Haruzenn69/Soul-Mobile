import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'kegiatan_detail_screen.dart';

class KegiatanScreen extends ConsumerStatefulWidget {
  const KegiatanScreen({
    super.key,
    required this.user,
    this.openCreateOnStart = false,
  });

  final AuthUser user;
  final bool openCreateOnStart;

  @override
  ConsumerState<KegiatanScreen> createState() => _KegiatanScreenState();
}

class _KegiatanScreenState extends ConsumerState<KegiatanScreen> {
  String _cari = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.openCreateOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _buatKegiatan();
      });
    }
  }

  Future<void> _buatKegiatan() async {
    final data = await _showBuatDialog();
    if (data == null || !mounted) return;
    try {
      setState(() {});
      final photo = data.remove('_photo') as XFile?;
      final photoBytes = data.remove('_photo_bytes') as Uint8List?;
      if (photo == null) {
        await ref.read(apiClientProvider).post('/ketua/kegiatan', data: data);
      } else {
        await ref
            .read(apiClientProvider)
            .postMultipart(
              '/ketua/kegiatan',
              fields: data,
              files: [
                MultipartFile.fromBytes(photoBytes!, filename: photo.name),
              ],
              fileKeys: const ['dokumentasi'],
            );
      }
      ref.invalidate(ketuaKegiatanProvider);
      ref.invalidate(ketuaDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kegiatan berhasil dibuat.')),
        );
      }
    } catch (e) {
      if (mounted) {
        await showErrorDialog(context, ref, e);
      }
    }
  }

  Future<Map<String, dynamic>?> _showBuatDialog() async {
    final materi = TextEditingController();
    final deskripsi = TextEditingController();
    final dateCtrl = TextEditingController();
    final endDateCtrl = TextEditingController();
    DateTime tanggal = DateTime.now();
    DateTime? tanggalBerakhir;
    bool isEvent = false;
    XFile? photo;
    Uint8List? photoBytes;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        dateCtrl.text = DateFormat('yyyy-MM-dd').format(tanggal);
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(
              'Buat Kegiatan',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: materi,
                    decoration: const InputDecoration(
                      labelText: 'Materi Kegiatan',
                      hintText: 'mis. Latihan Dasar',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Kegiatan event/lomba'),
                    value: isEvent,
                    onChanged: (value) => setDialogState(() => isEvent = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deskripsi,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi (opsional)',
                    ),
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
                      suffixIcon: Icon(
                        Icons.calendar_today_outlined,
                        color: AppTheme.sub,
                        size: 18,
                      ),
                    ),
                  ),
                  if (isEvent) ...[
                    const SizedBox(height: 12),
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
                        suffixIcon: Icon(Icons.event_busy_outlined),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
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
                    label: Text(photo?.name ?? 'Tambah dokumentasi'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (materi.text.trim().isEmpty) return;
                  Navigator.of(context).pop(<String, dynamic>{
                    'materi': materi.text.trim(),
                    'deskripsi': deskripsi.text.trim().isEmpty
                        ? ''
                        : deskripsi.text.trim(),
                    'tanggal_kegiatan': dateCtrl.text,
                    'jenis_kegiatan': isEvent ? 'event' : null,
                    if (tanggalBerakhir != null)
                      'tanggal_berakhir': endDateCtrl.text,
                    ...?(photo == null ? null : {'_photo': photo}),
                    ...?(photoBytes == null
                        ? null
                        : {'_photo_bytes': photoBytes}),
                  });
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        );
      },
    );
    materi.dispose();
    deskripsi.dispose();
    dateCtrl.dispose();
    endDateCtrl.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(ketuaKegiatanProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _buatKegiatan,
        backgroundColor: AppTheme.blue,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        tooltip: 'Buat kegiatan',
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Kegiatan',
              subtitle: 'Atur agenda dan dokumentasi ekskul.',
              eyebrow: 'AKTIVITAS EKSKUL',
              topPadding: 25,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _cari = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Cari kegiatan...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.sub),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _cari = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
            Expanded(
              child: ApiAsyncView(
                value: list,
                onRetry: () => ref.invalidate(ketuaKegiatanProvider),
                builder: (context, data) {
                  final all = listOf(data, 'kegiatans');
                  final filtered = _cari.isEmpty
                      ? all
                      : all
                            .where(
                              (k) => (k['materi'] as String? ?? '')
                                  .toLowerCase()
                                  .contains(_cari),
                            )
                            .toList();
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Row(
                          children: [
                            Text(
                              _cari.isEmpty
                                  ? '${filtered.length} kegiatan'
                                  : '${filtered.length} hasil pencarian',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.sub,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            if (_cari.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _cari = '');
                                },
                                child: const Text('Hapus filter'),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? EmptyState(
                                title: _cari.isEmpty
                                    ? 'Belum ada kegiatan'
                                    : 'Kegiatan tidak ditemukan',
                                subtitle: _cari.isEmpty
                                    ? 'Tekan tombol + untuk membuat kegiatan baru.'
                                    : 'Coba kata kunci lain atau hapus pencarian.',
                                icon: _cari.isEmpty
                                    ? Icons.event_note_outlined
                                    : Icons.search_off_rounded,
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  4,
                                  16,
                                  24,
                                ),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final k = Kegiatan.fromJson(filtered[i]);
                                  return _KegiatanCard(
                                    kegiatan: k,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => KegiatanDetailScreen(
                                          kegiatanId: k.id,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KegiatanCard extends StatelessWidget {
  const _KegiatanCard({required this.kegiatan, this.onTap});

  final Kegiatan kegiatan;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EDF5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.025),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.blueBg,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.event_note,
                  color: AppTheme.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kegiatan.materi,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.ink,
                        fontSize: 14,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: AppTheme.sub,
                          size: 12,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            kegiatan.tanggalText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.sub,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (kegiatan.presensisCount != null) ...[
                          const SizedBox(width: 7),
                          const Icon(
                            Icons.people_alt_outlined,
                            color: AppTheme.sub,
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${kegiatan.presensisCount}',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.sub,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (kegiatan.isEvent)
                const StatusChip('Event')
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.sub,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
