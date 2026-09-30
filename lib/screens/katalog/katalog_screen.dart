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
  String _cari = '';

  @override
  Widget build(BuildContext context) {
    final katalog = ref.watch(katalogProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Katalog Ekskul',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _cari = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Cari ekskul atau pembina...',
                prefixIcon: Icon(Icons.search, color: AppTheme.sub),
              ),
            ),
          ),
          Expanded(
            child: ApiAsyncView(
              value: katalog,
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
    final joinable = listOf(data, 'joinable');

    final filtered = _cari.isEmpty
        ? joinable
        : joinable.where((e) {
            final nama =
                (e['nama_ekskul'] as String? ?? '').toLowerCase();
            final pembinaRaw = e['pembina'];
            final pembina = pembinaRaw is Map
                ? (pembinaRaw['nama'] as String? ?? '').toLowerCase()
                : (pembinaRaw as String? ?? '').toLowerCase();
            return nama.contains(_cari) || pembina.contains(_cari);
          }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (pending != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF0B429)),
            ),
            child: Row(
              children: [
                const Icon(Icons.hourglass_top, color: Color(0xFFB45309), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pendaftaran kamu ke ${
                        ((pending['ekskul'] is Map)
                            ? (pending['ekskul'] as Map)['nama_ekskul']
                            : 'ekskul')
                            .toString()
                      } masih menunggu persetujuan ketua.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF92400E),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (pendaftaran != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF7EF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBE7C5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF16803C), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kamu sudah aktif di ',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF14532D),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 4),
        for (final raw in filtered)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _EkskulCard(
              ekskul: Ekskul.fromJson(raw),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EkskulDetailScreen(
                    ekskulId: Ekskul.fromJson(raw).id,
                  ),
                ),
              ),
            ),
          ),
        if (filtered.isEmpty)
          const EmptyState(
            title: 'Tidak ada ekskul',
            subtitle: 'Coba kata kunci lain atau cek kembali nanti.',
            icon: Icons.unfold_more_outlined,
          ),
      ],
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
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
                      style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
                        color: AppTheme.sub,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StatusChip(
                          ekskul.isOpenRecruitment
                              ? 'Buka'
                              : 'Tutup',
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${ekskul.anggotaCount} anggota',
                          style: GoogleFonts.inter(
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