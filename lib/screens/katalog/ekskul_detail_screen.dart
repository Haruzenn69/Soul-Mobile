import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_config.dart';
import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class EkskulDetailScreen extends ConsumerStatefulWidget {
  const EkskulDetailScreen({super.key, required this.ekskulId});

  final int ekskulId;

  @override
  ConsumerState<EkskulDetailScreen> createState() => _EkskulDetailScreenState();
}

class _EkskulDetailScreenState extends ConsumerState<EkskulDetailScreen> {
  bool _loading = false;
  Ekskul? _ekskul;

  Future<void> _daftar(Ekskul ekskul) async {
    if (_loading) return;
    final alasan = await _showAlasanDialog();
    if (alasan == null || !mounted) return;

    setState(() => _loading = true);
    try {
      await ref.read(apiClientProvider).post('/siswa/daftar-ekskul', data: {
        'ekskul_id': ekskul.id,
        'alasan': alasan,
      });
      ref.invalidate(katalogProvider);
      ref.invalidate(siswaDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Pendaftaran terkirim. Menunggu konfirmasi ketua ekskul.'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _loading = false);
      await showErrorDialog(context, ref, e);
    }
  }

  Future<String?> _showAlasanDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alasan Bergabung',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 1000,
          decoration: const InputDecoration(
            hintText: 'Ceritakan alasanmu ingin bergabung...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.of(context).pop(text);
            },
            child: const Text('Daftar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(ekskulDetailProvider(widget.ekskulId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Ekskul')),
      body: ApiAsyncView(
        value: detail,
        builder: (context, data) {
          final ekskul = Ekskul.fromJson(data['ekskul'] is Map
              ? data['ekskul'] as Map<String, dynamic>
              : data);
          _ekskul = ekskul;
          final prestasis = listOf(data, 'prestasis');
          final kegiatans = listOf(data, 'kegiatans');
          final testimonis = listOf(data, 'testimonis');
          final galeri = (data['galeri_fotos'] as List?) ?? const [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              Text(
                ekskul.namaEkskul,
                style: GoogleFonts.inter(
                  color: AppTheme.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (ekskul.tagline?.isNotEmpty == true) ...[
                const SizedBox(height: 3),
                Text(
                  ekskul.tagline!,
                  style: GoogleFonts.inter(
                    color: AppTheme.sub,
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  StatusChip(
                      ekskul.isOpenRecruitment ? 'Buka Pendaftaran' : 'Tutup'),
                  const SizedBox(width: 8),
                  Text(
                    '${ekskul.anggotaCount} anggota',
                    style: GoogleFonts.inter(
                      color: AppTheme.sub,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (ekskul.jadwal != null && ekskul.jadwal!.isNotEmpty)
                _InfoRow(
                  icon: Icons.schedule,
                  text: ekskul.jadwal!,
                ),
              if (ekskul.pembina != null)
                _InfoRow(
                  icon: Icons.person_outline,
                  text: 'Pembina: ${ekskul.pembina!.nama}',
                ),
              if (ekskul.deskripsi?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                const SectionTitle2('Deskripsi'),
                _BodyText(ekskul.deskripsi!),
              ],
              if (ekskul.tujuan?.isNotEmpty == true) ...[
                const SizedBox(height: 18),
                const SectionTitle2('Tujuan Ekskul'),
                _BodyText(ekskul.tujuan!),
              ],
              if (galeri.isNotEmpty) ...[
                const SizedBox(height: 18),
                const SectionTitle2('Galeri'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: galeri.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 150,
                        child: _ImageOrPlaceholder(
                        url: AppConfig.imageUrl(galeri[i].toString())),
                      ),
                    ),
                  ),
                ),
              ],
              if (prestasis.isNotEmpty) ...[
                const SizedBox(height: 18),
                const SectionTitle2('Prestasi'),
                for (final p in prestasis)
                  _PrestasiCard(data: p),
              ],
              if (kegiatans.isNotEmpty) ...[
                const SizedBox(height: 18),
                const SectionTitle2('Kegiatan Terbaru'),
                for (final k in kegiatans)
                  _KegiatanMini(kegiatan: Kegiatan.fromJson(k)),
              ],
              if (testimonis.isNotEmpty) ...[
                const SizedBox(height: 18),
                const SectionTitle2('Testimoni'),
                for (final t in testimonis)
                  _TestimoniCard(data: t),
              ],
              const SizedBox(height: 8),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Consumer(
            builder: (context, ref, _) {
              final ekskul = _ekskul;
              if (ekskul == null) return const SizedBox.shrink();
              final katalog = ref.watch(katalogProvider);
              return katalog.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (data) {
                  final sudahAktif = data['pendaftaran'] is Map;
                  final sudahPending = data['pending'] is Map;
                  if (sudahAktif || sudahPending) {
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: null,
                        child: Text(sudahAktif ? 'Sudah Terdaftar' : 'Menunggu Persetujuan'),
                      ),
                    );
                  }
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: ekskul.isOpenRecruitment
                          ? () => _daftar(ekskul)
                          : null,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(_loading ? '' : 'Daftar ke Ekskul'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class SectionTitle2 extends StatelessWidget {
  const SectionTitle2(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: AppTheme.ink,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: AppTheme.ink,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.sub, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: AppTheme.sub,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrestasiCard extends StatelessWidget {
  const _PrestasiCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.military_tech, color: Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data['judul'] ?? ''}',
                  style: GoogleFonts.inter(
                    color: AppTheme.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${data['tahun'] ?? ''} · ${data['kategori'] ?? ''}',
                  style: GoogleFonts.inter(
                    color: AppTheme.sub,
                    fontSize: 11.5,
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

class _KegiatanMini extends StatelessWidget {
  const _KegiatanMini({required this.kegiatan});

  final Kegiatan kegiatan;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_outlined, color: AppTheme.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kegiatan.materi,
                  style: GoogleFonts.inter(
                    color: AppTheme.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  kegiatan.tanggalText,
                  style: GoogleFonts.inter(
                    color: AppTheme.sub,
                    fontSize: 11.5,
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

class _TestimoniCard extends StatelessWidget {
  const _TestimoniCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(AppConfig.brandBg).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“${data['quote'] ?? ''}”',
            style: GoogleFonts.inter(
              color: AppTheme.ink,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '— ${data['nama'] ?? ''}${_kelasLabel(data['kelas']).isNotEmpty ? ' · ${_kelasLabel(data['kelas'])}' : ''}',
            style: GoogleFonts.inter(
              color: AppTheme.sub,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _kelasLabel(Object? kelas) {
    if (kelas is Map) return (kelas['nama'] ?? '').toString();
    return (kelas ?? '').toString();
  }
}

class _ImageOrPlaceholder extends StatelessWidget {
  const _ImageOrPlaceholder({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: Colors.black12,
        child: const Icon(Icons.image_not_supported_outlined,
            color: Colors.white),
      ),
    );
  }
}