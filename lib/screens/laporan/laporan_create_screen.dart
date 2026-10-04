import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'laporan_detail_screen.dart';

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
                _infoCard(
                  icon: Icons.calendar_month_outlined,
                  title: 'Periode laporan',
                  description:
                      'Laporan ini ${widget.isEditing ? 'berisi' : 'dibuat untuk'} ${_bulan == null ? '${_monthLabel(now.month)} ${now.year}' : _formatPeriod(_bulan!)}.',
                ),
                const SizedBox(height: 12),
                _infoCard(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Data otomatis',
                  description: 'Materi kegiatan, rekap kehadiran, dan dokumentasi akan diambil dari data kegiatan pada periode laporan.',
                ),
                const SizedBox(height: 20),
                _formCard(
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

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String description,
  }) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.blueBg.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.blue.withValues(alpha: 0.12)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.blue, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.blueDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.sub,
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _formCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.line),
    ),
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
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.sub,
            fontSize: 11.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
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
