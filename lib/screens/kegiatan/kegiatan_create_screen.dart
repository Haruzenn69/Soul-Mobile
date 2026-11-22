import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/upload_check.dart';
import '../../theme/app_theme.dart';

class KegiatanCreateScreen extends ConsumerStatefulWidget {
  const KegiatanCreateScreen({super.key});

  @override
  ConsumerState<KegiatanCreateScreen> createState() =>
      _KegiatanCreateScreenState();
}

class _KegiatanCreateScreenState extends ConsumerState<KegiatanCreateScreen> {
  final _materiController = TextEditingController();
  final _deskripsiController = TextEditingController();
  DateTime _tanggal = DateTime.now();
  DateTime? _tanggalBerakhir;
  bool _isEvent = false;
  XFile? _photo;
  Uint8List? _photoBytes;

  @override
  void dispose() {
    _materiController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
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
      if (!mounted) return;
      setState(() {
        _photo = picked;
        _photoBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _pickDate({required bool endDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ? (_tanggalBerakhir ?? _tanggal) : _tanggal,
      firstDate: endDate
          ? _tanggal
          : DateTime.now().subtract(const Duration(days: 365)),
      lastDate: endDate
          ? DateTime.now().add(const Duration(days: 3650))
          : DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (endDate) {
        _tanggalBerakhir = picked;
      } else {
        _tanggal = picked;
        if (_tanggalBerakhir != null && _tanggalBerakhir!.isBefore(picked)) {
          _tanggalBerakhir = null;
        }
      }
    });
  }

  void _submit() {
    final materi = _materiController.text.trim();
    if (materi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Materi kegiatan wajib diisi.')),
      );
      return;
    }
    Navigator.of(context).pop(<String, dynamic>{
      'materi': materi,
      'deskripsi': _deskripsiController.text.trim(),
      'tanggal_kegiatan': DateFormat('yyyy-MM-dd').format(_tanggal),
      'jenis_kegiatan': _isEvent ? 'event' : null,
      if (_tanggalBerakhir != null)
        'tanggal_berakhir': DateFormat('yyyy-MM-dd').format(_tanggalBerakhir!),
      if (_photo != null) '_photo': _photo,
      if (_photoBytes != null) '_photo_bytes': _photoBytes,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Kegiatan'),
        actions: [TextButton(onPressed: _submit, child: const Text('Simpan'))],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentSurface(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.outline(context)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.blue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lengkapi informasi kegiatan agar anggota mudah melihat agenda.',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.mutedText(context),
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _materiController,
              decoration: const InputDecoration(
                labelText: 'Materi Kegiatan',
                hintText: 'Contoh: Latihan Dasar',
                prefixIcon: Icon(Icons.edit_note_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _deskripsiController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (opsional)',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tileColor: AppTheme.surface(context),
              title: const Text('Kegiatan event/lomba'),
              subtitle: const Text(
                'Aktifkan jika kegiatan memiliki rentang waktu.',
              ),
              value: _isEvent,
              onChanged: (value) => setState(() => _isEvent = value),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () => _pickDate(endDate: false),
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Kegiatan',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(DateFormat('dd MMMM yyyy').format(_tanggal)),
              ),
            ),
            if (_isEvent) ...[
              const SizedBox(height: 14),
              InkWell(
                onTap: () => _pickDate(endDate: true),
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Berakhir',
                    prefixIcon: Icon(Icons.event_busy_outlined),
                  ),
                  child: Text(
                    _tanggalBerakhir == null
                        ? 'Pilih tanggal'
                        : DateFormat('dd MMMM yyyy').format(_tanggalBerakhir!),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _photo?.name ?? 'Tambah dokumentasi (maks. 2 MB)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Simpan Kegiatan'),
            ),
          ],
        ),
      ),
    );
  }
}
