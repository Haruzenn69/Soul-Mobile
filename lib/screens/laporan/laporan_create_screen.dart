import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'laporan_detail_screen.dart'; // laporan_create_screen

class LaporanCreateScreen extends ConsumerStatefulWidget {
  const LaporanCreateScreen({super.key, this.laporanId});

  final int? laporanId;

  bool get isEditing => laporanId != null;

  @override
  ConsumerState<LaporanCreateScreen> createState() =>
      _LaporanCreateScreenState();
}

class _LaporanCreateScreenState extends ConsumerState<LaporanCreateScreen> {
  final _tujuan = TextEditingController();
  final _keberhasilan = TextEditingController();
  final _kendala = TextEditingController();
  final _solusi = TextEditingController();
  bool _saving = false;
  bool _initialized = false;
  String? _bulan;

  @override
  void dispose() {
    _tujuan.dispose();
    _keberhasilan.dispose();
    _kendala.dispose();
    _solusi.dispose();
    super.dispose();
  }

  Future<void> _saveReport() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final path = widget.isEditing
          ? '/ketua/laporan-bulanan/${widget.laporanId}/update'
          : '/ketua/laporan-bulanan';
      final response = await ref
          .read(apiClientProvider)
          .post(path, data: _formData);
      ref.invalidate(ketuaLaporanProvider);
      ref.invalidate(ketuaDashboardProvider);
      final responseData = response['data'];
      final laporan = responseData is Map ? responseData['laporan'] : null;
      final id =
          widget.laporanId ??
          (laporan is Map ? (laporan['id'] as num?)?.toInt() : null);

      if (id == null) {
        throw const ApiException(
          message:
              'Server tidak mengembalikan detail laporan yang baru dibuat.',
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Draft laporan berhasil diperbarui.'
                : 'Draft laporan berhasil dibuat.',
          ),
        ),
      );
      if (widget.isEditing) {
        ref.invalidate(laporanDetailProvider(id));
        Navigator.of(context).pop(true);
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => LaporanDetailScreen(laporanId: id),
        ),
      );
    } catch (error) {
      if (mounted) await showErrorDialog(context, ref, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Map<String, String> get _formData => {
    'tujuan': _tujuan.text.trim(),
    'evaluasi_keberhasilan': _keberhasilan.text.trim(),
    'evaluasi_kendala': _kendala.text.trim(),
    'evaluasi_solusi': _solusi.text.trim(),
  };

  void _populate(Map<String, dynamic> laporan) {
    if (_initialized) return;
    _tujuan.text = laporan['tujuan']?.toString() ?? '';
    _keberhasilan.text = laporan['evaluasi_keberhasilan']?.toString() ?? '';
    _kendala.text = laporan['evaluasi_kendala']?.toString() ?? '';
    _solusi.text = laporan['evaluasi_solusi']?.toString() ?? '';
    _bulan = laporan['bulan']?.toString();
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final report = widget.laporanId == null
        ? null
        : ref.watch(laporanDetailProvider(widget.laporanId!));
    final lap = report?.when(
      data: (data) => data['laporan'],
      error: (_, _) => null,
      loading: () => null,
    );
    if (lap is Map) _populate(Map<String, dynamic>.from(lap));
    final isLoading = report?.isLoading ?? false;
    final hasError = report?.hasError ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Laporan Bulanan' : 'Buat Laporan Bulanan',
        ),
      ),
      body: widget.isEditing && isLoading
          ? const Center(child: CircularProgressIndicator())
          : widget.isEditing && hasError
          ? Center(
              child: BuildErrorCard(
                message: report?.error is ApiException
                    ? (report!.error! as ApiException).message
                    : 'Laporan gagal dimuat. Coba lagi.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Container(
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
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                        ),
                        child: const Icon(
                          Icons.assignment_outlined,
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
                              _bulan == null
                                  ? '${_monthLabel(now.month)} ${now.year}'
                                  : _formatPeriod(_bulan!),
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Materi kegiatan, rekap kehadiran, dan dokumentasi akan diambil dari periode ini.',
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
                ),
                const SizedBox(height: 14),
                _formCard(
                  icon: Icons.flag_outlined,
                  title: 'Tujuan Kegiatan',
                  subtitle: 'Jelaskan target kegiatan ekskul pada bulan ini.',
                  child: TextField(
                    controller: _tujuan,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText:
                          'Contoh: Mengembangkan kemampuan dan kekompakan...',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _formCard(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Evaluasi Keberhasilan',
                  subtitle: 'Capaian positif yang berhasil diraih.',
                  child: TextField(
                    controller: _keberhasilan,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText:
                          'Tuliskan perkembangan atau hasil yang dicapai...',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _formCard(
                  icon: Icons.warning_amber_rounded,
                  title: 'Evaluasi Kendala',
                  subtitle: 'Hambatan atau masalah yang muncul.',
                  child: TextField(
                    controller: _kendala,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText:
                          'Tuliskan kendala selama kegiatan berlangsung...',
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _formCard(
                  icon: Icons.build_circle_outlined,
                  title: 'Solusi / Tindak Lanjut',
                  subtitle: 'Rencana untuk mengatasi kendala dan memperbaiki kegiatan.',
                  child: TextField(
                    controller: _solusi,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Tuliskan langkah perbaikan berikutnya...',
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveReport,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _saving
                      ? 'Menyimpan...'
                      : widget.isEditing
                      ? 'Simpan Perubahan'
                      : 'Simpan Draft',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPeriod(String period) {
    final parts = period.split('-');
    if (parts.length != 2) return period;
    final month = int.tryParse(parts[1]);
    if (month == null || month < 1 || month > 12) return period;
    return '${_monthLabel(month)} ${parts[0]}';
  }

  Widget _formCard({
    IconData? icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.outline(context)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
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
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.text(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.mutedText(context),
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );

  String _monthLabel(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }
}
