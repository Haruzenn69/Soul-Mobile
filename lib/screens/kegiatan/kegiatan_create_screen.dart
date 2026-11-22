import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

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
  bool _saving = false;

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
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
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
    if (picked == null || !mounted) return;

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
    if (_saving) return;

    final materi = _materiController.text.trim();
    if (materi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Materi kegiatan wajib diisi.')),
      );
      return;
    }
    if (_isEvent && _tanggalBerakhir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal berakhir event.')),
      );
      return;
    }

    setState(() => _saving = true);
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
      appBar: AppBar(title: const Text('Buat Kegiatan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _KegiatanIntro(isEvent: _isEvent),
          const SizedBox(height: 14),
          _FormCard(
            icon: Icons.edit_calendar_outlined,
            title: 'Informasi kegiatan',
            children: [
              TextField(
                controller: _materiController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Materi atau nama kegiatan',
                  hintText: 'Contoh: Latihan Dasar',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _deskripsiController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Tambahkan tujuan, agenda, atau catatan kegiatan',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              Material(
                color: AppTheme.accentSurface(context),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: _isEvent
                        ? AppTheme.blue.withValues(alpha: 0.48)
                        : AppTheme.outline(context),
                  ),
                ),
                child: SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  title: Text(
                    'Event atau lomba',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.text(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    'Gunakan rentang tanggal untuk kegiatan berkelanjutan.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.mutedText(context),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  value: _isEvent,
                  onChanged: (value) => setState(() => _isEvent = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FormCard(
            icon: Icons.calendar_month_outlined,
            title: 'Waktu kegiatan',
            children: [
              _DateTile(
                label: 'Tanggal mulai',
                value: DateFormat('EEEE, dd MMMM yyyy').format(_tanggal),
                onTap: () => _pickDate(endDate: false),
              ),
              if (_isEvent) ...[
                const SizedBox(height: 12),
                _DateTile(
                  label: 'Tanggal berakhir',
                  value: _tanggalBerakhir == null
                      ? 'Pilih tanggal'
                      : DateFormat('EEEE, dd MMMM yyyy')
                            .format(_tanggalBerakhir!),
                  onTap: () => _pickDate(endDate: true),
                  needsSelection: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _FormCard(
            icon: Icons.photo_library_outlined,
            title: 'Dokumentasi',
            actionLabel: 'Opsional',
            children: [
              _PhotoPicker(
                photoBytes: _photoBytes,
                onPick: _pickPhoto,
                onRemove: () => setState(() {
                  _photo = null;
                  _photoBytes = null;
                }),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          key: const ValueKey('save-create-kegiatan'),
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_saving ? 'Menyimpan...' : 'Simpan Kegiatan'),
        ),
      ),
    );
  }
}

class _KegiatanIntro extends StatelessWidget {
  const _KegiatanIntro({required this.isEvent});

  final bool isEvent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.brandHeroGradient(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: Icon(
              isEvent
                  ? Icons.emoji_events_outlined
                  : Icons.event_available_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEvent ? 'Event atau lomba' : 'Kegiatan rutin',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Catat agenda agar anggota dan rekap tetap terhubung.',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.icon,
    required this.title,
    required this.children,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.accentSurface(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.blue, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.text(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (actionLabel != null)
                Text(
                  actionLabel!,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.mutedText(context),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.needsSelection = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool needsSelection;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value == 'Pilih tanggal';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPlaceholder && needsSelection
                ? AppTheme.warningBorder(context)
                : AppTheme.outline(context),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: isPlaceholder
                  ? AppTheme.mutedText(context)
                  : AppTheme.blue,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.mutedText(context),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      color: isPlaceholder
                          ? AppTheme.mutedText(context)
                          : AppTheme.text(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_right_rounded,
              color: AppTheme.mutedText(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photoBytes,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? photoBytes;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoBytes != null;
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      decoration: BoxDecoration(
        color: AppTheme.accentSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Stack(
              fit: StackFit.passthrough,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.memory(photoBytes!, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    tooltip: 'Hapus dokumentasi',
                    onPressed: onRemove,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.66),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: onPick,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 22,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.surface(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.outline(context)),
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppTheme.blue,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Pilih dokumentasi',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.text(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'JPG, PNG, atau WebP · Maks. 2 MB',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.mutedText(context),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
