import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'ekskul_detail_screen.dart';

class KatalogScreen extends ConsumerStatefulWidget {
  const KatalogScreen({super.key, required this.user});

  final AuthUser user;

  @override
  ConsumerState<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends ConsumerState<KatalogScreen> {
  final _searchCtrl = TextEditingController();
  String _cari = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final katalog = ref.watch(katalogProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Jelajahi Ekskul',
            subtitle: 'Temukan kegiatan yang sesuai dengan minatmu.',
            eyebrow: 'KATALOG',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _cari = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari ekskul atau pembina...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.sub),
                suffixIcon: _cari.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _cari = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: ApiAsyncView(
              value: katalog,
              onRetry: () => ref.invalidate(katalogProvider),
              builder: (context, data) {
                return _body(context, data);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, Map<String, dynamic> data) {
    final pending = data['pending'] is Map
        ? Map<String, dynamic>.from(data['pending'] as Map)
        : null;
    final pendaftaran = data['pendaftaran'] is Map
        ? Map<String, dynamic>.from(data['pendaftaran'] as Map)
        : null;
    final adaJoinable =
        (data['joinable'] is List) && (data['joinable'] as List).isNotEmpty;
    final joinable = listOf(data, 'joinable');

    final filtered = _cari.isEmpty
        ? joinable
        : joinable.where((e) {
            final nama = (e['nama_ekskul'] as String? ?? '').toLowerCase();
            final pembinaRaw = e['pembina'];
            final pembina = pembinaRaw is Map
                ? (pembinaRaw['nama'] as String? ?? '').toLowerCase()
                : (pembinaRaw as String? ?? '').toLowerCase();
            return nama.contains(_cari) || pembina.contains(_cari);
          }).toList();

    final itemCount =
        (pending != null ? 1 : 0) + (pendaftaran != null ? 1 : 0) + filtered.length;

    if (itemCount == 0) {
      return EmptyState(
        title: adaJoinable ? 'Tidak ada yang cocok' : 'Belum ada ekskul',
        subtitle: adaJoinable
            ? 'Coba kata kunci lain.'
            : 'Belum ada ekskul yang bisa didaftar saat ini.',
        icon: Icons.unfold_more_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        var i = index;
        if (pending != null) {
          i -= 1;
          if (i < 0) {
            return _InfoBanner(
              color: const Color(0xFFFFF7E6),
              border: const Color(0xFFF0B429),
              icon: const Icon(
                Icons.hourglass_top,
                color: Color(0xFFB45309),
                size: 20,
              ),
              text:
                  'Pendaftaran kamu ke ${((pending['ekskul'] is Map) ? (pending['ekskul'] as Map)['nama_ekskul'] : 'ekskul').toString()} masih menunggu persetujuan ketua.',
              textColor: const Color(0xFF92400E),
              onTap: () => _openDetail(context, pending),
            );
          }
        }
        if (pendaftaran != null) {
          i -= 1;
          if (i < 0) {
            return _InfoBanner(
              color: const Color(0xFFEDF7EF),
              border: const Color(0xFFBBE7C5),
              icon: const Icon(
                Icons.check_circle,
                color: Color(0xFF16803C),
                size: 20,
              ),
              text:
                  'Kamu sudah aktif di ${((pendaftaran['ekskul'] is Map) ? (pendaftaran['ekskul'] as Map)['nama_ekskul'] : 'ekskul').toString()}.',
              textColor: const Color(0xFF14532D),
              onTap: () => _openDetail(context, pendaftaran),
            );
          }
        }
        if (i < filtered.length) {
          final raw = filtered[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _EkskulCard(
              ekskul: Ekskul.fromJson(raw),
              onTap: () => _openDetail(context, raw),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _openDetail(BuildContext context, Map<String, dynamic> data) {
    final ekskulRaw = data['ekskul'] is Map ? data['ekskul'] as Map : data;
    final id = (ekskulRaw['id'] as num?)?.toInt();
    if (id == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EkskulDetailScreen(ekskulId: id),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.color,
    required this.border,
    required this.icon,
    required this.text,
    required this.textColor,
    this.onTap,
  });

  final Color color;
  final Color border;
  final Widget icon;
  final String text;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.plusJakartaSans(
                      color: textColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right, color: Colors.black26, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EkskulCard extends StatelessWidget {
  const _EkskulCard({required this.ekskul, this.onTap});

  final Ekskul ekskul;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.emoji_events_outlined,
                  color: AppTheme.blue,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ekskul.namaEkskul,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ekskul.tagline?.isNotEmpty == true
                          ? ekskul.tagline!
                          : ekskul.namaEkskul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.sub,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StatusChip(ekskul.isOpenRecruitment ? 'Buka' : 'Tutup'),
                        const SizedBox(width: 8),
                        Text(
                          '${ekskul.anggotaCount} anggota',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.sub,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
