import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_config.dart';
import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/photo_viewer.dart';

abstract final class _DetailFont {
  static const micro = 11.0;
  static const caption = 12.0;
  static const secondary = 13.0;
  static const body = 14.0;
  static const cardTitle = 15.0;
  static const sectionTitle = 20.0;
  static const heroTitle = 23.0;
}

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
      appBar: AppBar(title: const Text('Profil ekskul')),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 136),
            children: [
              _DetailHero(
                ekskul: ekskul,
                pelatih: pelatih is Map && pelatih['is_terverifikasi'] == true
                    ? Map<String, dynamic>.from(pelatih)
                    : null,
              ),
              const SizedBox(height: 26),
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
                      eyebrow: 'PENCAPAIAN',
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
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant(context),
              borderRadius: BorderRadius.circular(17),
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
                      fontSize: _DetailFont.caption,
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
    final name = ekskul.namaEkskul.trim();
    final initials = name.isEmpty
        ? 'E'
        : name.substring(0, name.length > 1 ? 2 : 1);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.outline(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 226,
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
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.28),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.78),
                      ],
                      stops: const [0, 0.38, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: ekskul.status
                          ? AppTheme.successSurface(
                              context,
                            ).withValues(alpha: 0.94)
                          : AppTheme.surface(context).withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: ekskul.status
                                ? AppTheme.successText(context)
                                : AppTheme.mutedText(context),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          ekskul.status ? 'Ekskul aktif' : 'Belum aktif',
                          style: GoogleFonts.plusJakartaSans(
                          color: ekskul.status
                              ? AppTheme.successText(context)
                              : AppTheme.mutedText(context),
                            fontSize: _DetailFont.caption,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 17,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: (ekskul.logo ?? '').isNotEmpty
                              ? _ImageOrPlaceholder(
                                  url: AppConfig.imageUrl(ekskul.logo),
                                )
                              : DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.brandHeroGradient(
                                      context,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      initials.toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (ekskul.kategori?.isNotEmpty == true) ...[
                                Text(
                                  ekskul.kategori!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    fontSize: _DetailFont.caption,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                              ],
                              Text(
                                name.isEmpty ? 'Ekstrakurikuler' : name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: _DetailFont.heroTitle,
                                  fontWeight: FontWeight.w900,
                                  height: 1.08,
                                ),
                              ),
                              if (ekskul.tagline?.isNotEmpty == true) ...[
                                const SizedBox(height: 3),
                                Text(
                                  ekskul.tagline!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    fontSize: _DetailFont.caption,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.school_outlined,
                        label: 'Pembina',
                        value: ekskul.pembina?.nama ?? 'Belum ditentukan',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.sports_outlined,
                        label: 'Pelatih',
                        value: pelatih?['nama']?.toString() ?? 'Belum ada',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.groups_outlined,
                        label: 'Anggota aktif',
                        value: '${ekskul.anggotaCount} siswa',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.calendar_month_outlined,
                        label: 'Jadwal rutin',
                        value: ekskul.jadwal?.isNotEmpty == true
                            ? ekskul.jadwal!
                            : 'Belum diatur',
                      ),
                    ),
                  ],
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
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 58),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: AppTheme.surfaceVariant(context).withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppTheme.accent(context), size: 18),
        const SizedBox(width: 8),
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
                  fontSize: _DetailFont.micro,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.text(context),
                  fontSize: _DetailFont.caption,
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
        eyebrow.toLowerCase(),
        style: GoogleFonts.plusJakartaSans(
          color: AppTheme.accent(context),
          fontSize: _DetailFont.caption,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: AppTheme.text(context),
          fontSize: _DetailFont.sectionTitle,
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
            fontSize: _DetailFont.secondary,
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
                Icon(
                  Icons.info_outline,
                  color: AppTheme.accent(context),
                  size: 19,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tentang kegiatan',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.text(context),
                    fontSize: _DetailFont.cardTitle,
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
          color: AppTheme.surfaceVariant(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outline(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.track_changes_outlined,
                  color: AppTheme.accent(context),
                  size: 19,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tujuan kegiatan',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.text(context),
                    fontSize: _DetailFont.cardTitle,
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
        Icon(icon, color: AppTheme.accent(context), size: 26),
        const SizedBox(height: 7),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.text(context),
            fontSize: _DetailFont.cardTitle,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.mutedText(context),
            fontSize: _DetailFont.secondary,
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
            fontSize: _DetailFont.caption,
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
          color: isComplete
              ? AppTheme.warningText(context)
              : AppTheme.accent(context),
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
                  fontSize: _DetailFont.cardTitle,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.mutedText(context),
                  fontSize: _DetailFont.secondary,
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
            style: const TextStyle(
              fontSize: _DetailFont.caption,
              fontWeight: FontWeight.w700,
            ),
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
          fontSize: _DetailFont.body,
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
      borderRadius: BorderRadius.circular(18),
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
                      color: AppTheme.accent(context),
                      fontSize: _DetailFont.caption,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${data['judul'] ?? ''}',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.text(context),
                    fontSize: _DetailFont.cardTitle,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (photo?.isNotEmpty == true && data['tahun'] != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    '${data['tahun']} · Terverifikasi',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.mutedText(context),
                      fontSize: _DetailFont.caption,
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.accentSurface(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.event_outlined,
              color: AppTheme.accent(context),
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
                    fontSize: _DetailFont.cardTitle,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  kegiatan.tanggalText,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.mutedText(context),
                    fontSize: _DetailFont.secondary,
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
                      fontSize: _DetailFont.secondary,
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
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline(context)),
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
              fontSize: _DetailFont.body,
              fontStyle: FontStyle.italic,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '— ${data['nama'] ?? ''}${_kelasLabel(data['kelas']).isNotEmpty ? ' · ${_kelasLabel(data['kelas'])}' : ''}',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.mutedText(context),
              fontSize: _DetailFont.caption,
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
      borderRadius: BorderRadius.circular(18),
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
            color: AppTheme.accentSurface(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              'Q',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.accent(context),
                fontSize: _DetailFont.cardTitle,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        title: Text(
          data['pertanyaan']?.toString() ?? '',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.text(context),
            fontSize: _DetailFont.cardTitle,
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
                      fontSize: _DetailFont.caption,
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
                    fontSize: _DetailFont.secondary,
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
