import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_config.dart';
import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/photo_viewer.dart';

class EkskulDetailScreen extends ConsumerStatefulWidget {
  const EkskulDetailScreen({super.key, required this.ekskulId});

  final int ekskulId;

  @override
  ConsumerState<EkskulDetailScreen> createState() => _EkskulDetailScreenState();
}

class _EkskulDetailScreenState extends ConsumerState<EkskulDetailScreen> {
  bool _loading = false;
  Ekskul? _ekskul;

  Future<void> _submitCatalogFeedback({
    required String field,
    required String title,
    required String hint,
  }) async {
    final ekskul = _ekskul;
    if (ekskul == null) return;
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          maxLength: field == 'quote' ? 2000 : 255,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty || !mounted) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(apiClientProvider)
          .post(
            '/catalog/${ekskul.id}/${field == 'faq' ? 'faq' : 'testimoni'}',
            data: {field == 'faq' ? 'pertanyaan' : field: text},
          );
      ref.invalidate(ekskulDetailProvider(widget.ekskulId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            field == 'faq'
                ? 'Pertanyaan terkirim untuk dijawab.'
                : 'Testimoni terkirim untuk ditinjau.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) await showErrorDialog(context, ref, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(ekskulDetailProvider(widget.ekskulId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Ekskul')),
      body: ApiAsyncView(
        value: detail,
        onRetry: () => ref.invalidate(ekskulDetailProvider(widget.ekskulId)),
        builder: (context, data) {
          final detailData =
              data['ekskul'] is Map && (data['ekskul'] as Map)['ekskul'] is Map
              ? Map<String, dynamic>.from(data['ekskul'] as Map)
              : data;
          final ekskulData = detailData['ekskul'] is Map
              ? Map<String, dynamic>.from(detailData['ekskul'] as Map)
              : detailData;
          final ekskul = Ekskul.fromJson(ekskulData);
          _ekskul = ekskul;
          final prestasis = listOf(detailData, 'prestasis');
          final kegiatans = listOf(detailData, 'kegiatans');
          final testimonis = listOf(detailData, 'testimonis');
          final faqs = listOf(detailData, 'faqs');
          final galeri = (detailData['galeri_fotos'] as List?) ?? const [];
          final pelatih = ekskulData['pelatih'];
          final auth = ref.watch(authControllerProvider);
          final canSendFeedback =
              auth.status == AuthStatus.authenticated &&
              auth.user?.role == 'siswa';
          final hasSubmittedTestimoni =
              detailData['has_submitted_testimoni'] == true;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              _DetailHero(
                ekskul: ekskul,
                pelatih: pelatih is Map && pelatih['is_terverifikasi'] == true
                    ? Map<String, dynamic>.from(pelatih)
                    : null,
              ),
              const SizedBox(height: 20),
              _DetailSectionHeading(
                eyebrow: 'TENTANG KAMI',
                title: 'Mengenal ${ekskul.namaEkskul}',
                subtitle: 'Profil, pembinaan, dan jadwal ekstrakurikuler.',
              ),
              const SizedBox(height: 10),
              _AboutCard(ekskul: ekskul),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: _DetailSectionHeading(
                      eyebrow: 'HALL OF FAME',
                      title: 'Prestasi',
                    ),
                  ),
                  if (prestasis.isNotEmpty)
                    _CountBadge(
                      icon: Icons.emoji_events_outlined,
                      text: '${prestasis.length} prestasi',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (prestasis.isEmpty)
                const _DetailEmptyCard(
                  icon: Icons.military_tech_outlined,
                  title: 'Belum ada catatan prestasi',
                  message: 'Bergabunglah dan jadilah bagian dari pencapaian ekskul berikutnya.',
                )
              else
                for (final p in prestasis) _PrestasiCard(data: p),
              if (kegiatans.isNotEmpty) ...[
                const SizedBox(height: 20),
                const _DetailSectionHeading(
                  eyebrow: 'AKTIVITAS',
                  title: 'Agenda & Kegiatan',
                  subtitle: 'Kegiatan terbaru dari ekskul ini.',
                ),
                const SizedBox(height: 8),
                ...(() {
                  final sortedKegiatans = [...kegiatans]
                    ..sort((a, b) {
                      final dateA =
                          DateTime.tryParse(
                            a['tanggal_kegiatan']?.toString() ?? '',
                          ) ??
                          DateTime(0);
                      final dateB =
                          DateTime.tryParse(
                            b['tanggal_kegiatan']?.toString() ?? '',
                          ) ??
                          DateTime(0);
                      if (dateA != dateB) return dateB.compareTo(dateA);

                      final idA = (a['id'] as num?)?.toInt() ?? 0;
                      final idB = (b['id'] as num?)?.toInt() ?? 0;
                      return idB.compareTo(idA);
                    });
                  final limited = sortedKegiatans.take(4);
                  return limited.map(
                    (k) => _KegiatanMini(kegiatan: Kegiatan.fromJson(k)),
                  );
                }()),
              ],
              if (galeri.isNotEmpty) ...[
                const SizedBox(height: 20),
                const _DetailSectionHeading(
                  eyebrow: 'DOKUMENTASI',
                  title: 'Galeri Kegiatan',
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: galeri.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.15,
                  ),
                  itemBuilder: (context, i) {
                    final url = AppConfig.imageUrl(galeri[i].toString());
                    return Material(
                      color: AppTheme.surfaceVariant(context),
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => PhotoViewDialog.show(
                          context,
                          imageUrl: url,
                          title: ekskul.namaEkskul,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _ImageOrPlaceholder(url: url),
                            const Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  shadows: [Shadow(blurRadius: 5)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              if (testimonis.isNotEmpty) ...[
                const SizedBox(height: 20),
                const _DetailSectionHeading(
                  eyebrow: 'KATA MEREKA',
                  title: 'Cerita Anggota',
                ),
                for (final t in testimonis) _TestimoniCard(data: t),
              ],
              if (canSendFeedback) ...[
                const SizedBox(height: 8),
                _FeedbackActionCard(
                  icon: Icons.rate_review_outlined,
                  title: 'Bagikan pengalamanmu',
                  description: hasSubmittedTestimoni
                      ? 'Testimoni kamu sudah dikirim dan sedang diproses.'
                      : 'Ceritakan pengalamanmu bergabung di ekskul ini.',
                  buttonLabel: hasSubmittedTestimoni
                      ? 'Testimoni terkirim'
                      : 'Tulis testimoni',
                  isComplete: hasSubmittedTestimoni,
                  onPressed: hasSubmittedTestimoni || _loading
                      ? null
                      : () => _submitCatalogFeedback(
                          field: 'quote',
                          title: 'Tulis testimoni',
                          hint: 'Bagikan pengalamanmu di ekskul ini',
                        ),
                ),
              ],
              const SizedBox(height: 20),
              _DetailSectionHeading(
                eyebrow: 'PUSAT BANTUAN',
                title: 'Pertanyaan & Jawaban',
                subtitle:
                    'Jawaban resmi pengurus tentang ${ekskul.namaEkskul}.',
              ),
              const SizedBox(height: 8),
              if (faqs.isEmpty)
                const _DetailEmptyCard(
                  icon: Icons.help_outline,
                  title: 'Belum ada FAQ',
                  message: 'Kirim pertanyaan kepada ketua ekskul untuk mendapatkan informasi.',
                )
              else
                for (final faq in faqs) _FaqCard(data: faq),
              if (canSendFeedback) ...[
                const SizedBox(height: 8),
                _FeedbackActionCard(
                  icon: Icons.chat_bubble_outline,
                  title: 'Tanya ketua ekskul',
                  description: 'Pertanyaanmu akan ditinjau dan bisa ditampilkan sebagai FAQ.',
                  buttonLabel: 'Ajukan pertanyaan',
                  onPressed: _loading
                      ? null
                      : () => _submitCatalogFeedback(
                          field: 'faq',
                          title: 'Ajukan pertanyaan',
                          hint: 'Apa yang ingin kamu ketahui?',
                        ),
                ),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.accentSurface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.outline(context)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.accent(context),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Keanggotaan dikelola langsung oleh ketua ekskul. Hubungi ketua jika ingin bergabung.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.text(context),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.ekskul, required this.pelatih});

  final Ekskul ekskul;
  final Map<String, dynamic>? pelatih;

  @override
  Widget build(BuildContext context) {
    final initials = ekskul.namaEkskul.trim().isEmpty
        ? 'E'
        : ekskul.namaEkskul.trim().substring(
            0,
            ekskul.namaEkskul.trim().length > 1
                ? 2
                : ekskul.namaEkskul.trim().length,
          );

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if ((ekskul.cover ?? '').isNotEmpty)
                  _ImageOrPlaceholder(url: AppConfig.imageUrl(ekskul.cover))
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandHeroGradient(context),
                    ),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black38, Colors.transparent],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: ekskul.status
                          ? const Color(0xFF15803D)
                          : const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      ekskul.status ? 'Ekskul Aktif' : 'Tidak Aktif',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.outline(context)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x140F172A),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: (ekskul.logo ?? '').isNotEmpty
                          ? _ImageOrPlaceholder(
                              url: AppConfig.imageUrl(ekskul.logo),
                            )
                          : DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: AppTheme.brandHeroGradient(context),
                              ),
                              child: Center(
                                child: Text(
                                  initials.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              ekskul.namaEkskul,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.text(context),
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.verified_rounded,
                            color: AppTheme.blue,
                            size: 18,
                          ),
                        ],
                      ),
                      if (ekskul.kategori?.isNotEmpty == true) ...[
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentSurface(context),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.category_outlined,
                                color: AppTheme.blue,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ekskul.kategori!,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (ekskul.tagline?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          '“${ekskul.tagline}”',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.mutedText(context),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 2.8,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        children: [
                          _MetricTile(
                            icon: Icons.school_outlined,
                            label: 'Pembina',
                            value: ekskul.pembina?.nama ?? 'Belum ditentukan',
                            tint: AppTheme.blue.withValues(alpha: 0.1),
                            iconColor: AppTheme.blue,
                          ),
                          _MetricTile(
                            icon: Icons.sports_outlined,
                            label: 'Pelatih',
                            value: pelatih?['nama']?.toString() ?? 'Belum ada',
                            tint: AppTheme.warningSurface(context),
                            iconColor: AppTheme.warningText(context),
                          ),
                          _MetricTile(
                            icon: Icons.groups_outlined,
                            label: 'Anggota aktif',
                            value: '${ekskul.anggotaCount} siswa',
                            tint: AppTheme.successSurface(context),
                            iconColor: AppTheme.successText(context),
                          ),
                          _MetricTile(
                            icon: Icons.calendar_month_outlined,
                            label: 'Jadwal rutin',
                            value: ekskul.jadwal?.isNotEmpty == true
                                ? ekskul.jadwal!
                                : 'Belum diatur',
                            tint: AppTheme.blue.withValues(alpha: 0.1),
                            iconColor: AppTheme.blue,
                          ),
                        ],
                      ),
                    ],
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    decoration: BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: iconColor, size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.mutedText(context),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.text(context),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DetailSectionHeading extends StatelessWidget {
  const _DetailSectionHeading({
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: GoogleFonts.plusJakartaSans(
          color: AppTheme.blue,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: AppTheme.text(context),
          fontSize: 17,
          fontWeight: FontWeight.w900,
          height: 1.2,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 3),
        Text(
          subtitle!,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.mutedText(context),
            fontSize: 11.5,
            height: 1.4,
          ),
        ),
      ],
    ],
  );
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.ekskul});

  final Ekskul ekskul;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outline(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.blue, size: 19),
                const SizedBox(width: 8),
                Text(
                  'Profil & eksplorasi',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.text(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _BodyText(
              ekskul.deskripsi?.trim().isNotEmpty == true
                  ? ekskul.deskripsi!
                  : 'Deskripsi ekstrakurikuler ini belum tersedia.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppTheme.warningSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.warningBorder(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.track_changes_outlined,
                  color: AppTheme.warningText(context),
                  size: 19,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fokus & tujuan',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.text(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _BodyText(
              ekskul.tujuan?.trim().isNotEmpty == true
                  ? ekskul.tujuan!
                  : 'Mengembangkan minat dan bakat, melatih kepemimpinan, '
                        'serta membangun karakter kolaboratif.',
            ),
          ],
        ),
      ),
    ],
  );
}

class _DetailEmptyCard extends StatelessWidget {
  const _DetailEmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceVariant(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.outline(context)),
    ),
    child: Column(
      children: [
        Icon(icon, color: AppTheme.blue, size: 26),
        const SizedBox(height: 7),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.text(context),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.mutedText(context),
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: AppTheme.warningSurface(context),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: AppTheme.warningBorder(context)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.warningText(context), size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.warningText(context),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _FeedbackActionCard extends StatelessWidget {
  const _FeedbackActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
    this.isComplete = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final bool isComplete;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: isComplete
          ? AppTheme.warningSurface(context)
          : AppTheme.surface(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isComplete
            ? AppTheme.warningBorder(context)
            : AppTheme.outline(context),
      ),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          color: isComplete ? AppTheme.warningText(context) : AppTheme.blue,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.text(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.mutedText(context),
                  fontSize: 10.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        TextButton(
          onPressed: onPressed,
          child: Text(
            buttonLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
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
        style: GoogleFonts.plusJakartaSans(
          color: AppTheme.text(context),
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}

class _PrestasiCard extends StatelessWidget {
  const _PrestasiCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final photo = data['foto']?.toString();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photo?.isNotEmpty == true)
            SizedBox(
              height: 145,
              width: double.infinity,
              child: _ImageOrPlaceholder(url: AppConfig.imageUrl(photo)),
            )
          else
            Container(
              height: 66,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppTheme.warningSurface(context),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.military_tech,
                    color: AppTheme.warningText(context),
                    size: 28,
                  ),
                  const Spacer(),
                  if (data['tahun'] != null)
                    _CountBadge(
                      icon: Icons.calendar_month_outlined,
                      text: '${data['tahun']}',
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((data['kategori']?.toString() ?? '').isNotEmpty)
                  Text(
                    data['kategori'].toString().toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.blue,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${data['judul'] ?? ''}',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.text(context),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (photo?.isNotEmpty == true && data['tahun'] != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    '${data['tahun']} · Terverifikasi',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.mutedText(context),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.brandHeroGradient(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.event_outlined,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kegiatan.materi,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.text(context),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  kegiatan.tanggalText,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.mutedText(context),
                    fontSize: 11.5,
                  ),
                ),
                if (kegiatan.deskripsi?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    kegiatan.deskripsi!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.mutedText(context),
                      fontSize: 10.5,
                      height: 1.35,
                    ),
                  ),
                ],
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
        color: AppTheme.warningSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 5; i++)
                const Padding(
                  padding: EdgeInsets.only(right: 2),
                  child: Icon(
                    Icons.star_rounded,
                    color: Color(0xFFF59E0B),
                    size: 14,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '“${data['quote'] ?? ''}”',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.text(context),
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '— ${data['nama'] ?? ''}${_kelasLabel(data['kelas']).isNotEmpty ? ' · ${_kelasLabel(data['kelas'])}' : ''}',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.mutedText(context),
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

class _FaqCard extends StatelessWidget {
  const _FaqCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: AppTheme.surface(context),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.outline(context)),
    ),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(AppConfig.brandBg),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text(
              'Q',
              style: TextStyle(
                color: AppTheme.blue,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        title: Text(
          data['pertanyaan']?.toString() ?? '',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.text(context),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 23,
                height: 23,
                decoration: BoxDecoration(
                  color: AppTheme.warningSurface(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: AppTheme.warningText(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data['jawaban']?.toString() ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.mutedText(context),
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ImageOrPlaceholder extends StatelessWidget {
  const _ImageOrPlaceholder({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      cacheWidth: 1200,
      errorBuilder: (_, _, _) => Container(
        color: Colors.black12,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.white,
        ),
      ),
    );
  }
}
