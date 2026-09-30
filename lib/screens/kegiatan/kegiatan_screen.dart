import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'kegiatan_detail_screen.dart';

class KegiatanScreen extends ConsumerStatefulWidget {
  const KegiatanScreen({super.key, required this.user});

  final AuthUser user;

  @override
  ConsumerState<KegiatanScreen> createState() => _KegiatanScreenState();
}

class _KegiatanScreenState extends ConsumerState<KegiatanScreen> {
  String _cari = '';

  Future<void> _buatKegiatan() async {
    final data = await _showBuatDialog();
    if (data == null || !mounted) return;
    try {
      setState(() {});
      await ref.read(apiClientProvider).post('/ketua/kegiatan', data: data);
      ref.invalidate(ketuaKegiatanProvider);
      ref.invalidate(ketuaDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kegiatan berhasil dibuat.')),
        );
      }
    } catch (e) {
      await showErrorDialog(context, ref, e);
    }
  }

  Future<Map<String, String>?> _showBuatDialog() async {
    final materi = TextEditingController();
    final deskripsi = TextEditingController();
    DateTime tanggal = DateTime.now();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        final dateCtrl = TextEditingController(
            text: DateFormat('yyyy-MM-dd').format(tanggal));
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('Buat Kegiatan',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: materi,
                    decoration: const InputDecoration(
                        labelText: 'Materi Kegiatan',
                        hintText: 'mis. Latihan Dasar'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deskripsi,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Deskripsi (opsional)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateCtrl,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tanggal,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          tanggal = picked;
                          dateCtrl.text =
                              DateFormat('yyyy-MM-dd').format(picked);
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Kegiatan',
                      suffixIcon: Icon(Icons.calendar_today_outlined,
                          color: AppTheme.sub, size: 18),
                    ),
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
                  Navigator.of(context).pop({
                    'materi': materi.text.trim(),
                    'deskripsi': deskripsi.text.trim().isEmpty
                        ? ''
                        : deskripsi.text.trim(),
                    'tanggal_kegiatan': dateCtrl.text,
                  });
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(ketuaKegiatanProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kegiatan',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                IconButton.filled(
                  onPressed: _buatKegiatan,
                  icon: const Icon(Icons.add),
                  tooltip: 'Buat kegiatan',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _cari = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Cari kegiatan...',
                prefixIcon: Icon(Icons.search, color: AppTheme.sub),
              ),
            ),
          ),
          Expanded(
            child: ApiAsyncView(
              value: list,
              builder: (context, data) {
                final all = listOf(data, 'kegiatans');
                final filtered = _cari.isEmpty
                    ? all
                    : all.where((k) =>
                        (k['materi'] as String? ?? '')
                            .toLowerCase()
                            .contains(_cari)).toList();
                if (filtered.isEmpty) {
                  return const EmptyState(
                    title: 'Belum ada kegiatan',
                    subtitle:
                        'Tekan tombol + untuk membuat kegiatan baru.',
                    icon: Icons.event_note_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final k = Kegiatan.fromJson(filtered[i]);
                    return _KegiatanCard(
                      kegiatan: k,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              KegiatanDetailScreen(kegiatanId: k.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_note,
                    color: AppTheme.blue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kegiatan.materi,
                      style: GoogleFonts.inter(
                        color: AppTheme.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      kegiatan.tanggalText,
                      style: GoogleFonts.inter(
                        color: AppTheme.sub,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (kegiatan.isEvent) const StatusChip('Event'),
              const SizedBox(width: 4),
              if (kegiatan.presensisCount != null)
                Text(
                  '${kegiatan.presensisCount} hadir',
                  style: GoogleFonts.inter(
                    color: AppTheme.sub,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}