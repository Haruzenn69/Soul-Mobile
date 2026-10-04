import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../faq/ketua_faq_screen.dart';
import '../nilai/nilai_screen.dart';
import '../profil/profil_screen.dart';
import '../profil_ekskul/profil_ekskul_screen.dart';
import '../testimoni/testimoni_manage_screen.dart';

class KetuaMenuScreen extends StatelessWidget {
  const KetuaMenuScreen({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const PageHeader(
            title: 'Menu Ketua',
            subtitle: 'Akses pengelolaan ekskul dan akun.',
            eyebrow: 'PENGATURAN',
          ),
          const SizedBox(height: 18),
          _IdentityCard(user: user),
          const SizedBox(height: 26),
          _MenuSection(
            title: 'Penilaian',
            children: [
              _MenuTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Nilai Akhir',
                subtitle: 'Lihat nilai akhirmu pada periode berjalan.',
                onTap: () => _open(context, const NilaiScreen()),
              ),
            ],
          ),
          const SizedBox(height: 26),
          _MenuSection(
            title: 'Kelola Katalog',
            children: [
              _MenuTile(
                icon: Icons.storefront_outlined,
                title: 'Profil Ekskul & Prestasi',
                subtitle: 'Perbarui informasi, galeri, dan prestasi.',
                onTap: () => _open(context, ProfilEkskulScreen(user: user)),
              ),
              _MenuTile(
                icon: Icons.reviews_outlined,
                title: 'Testimoni',
                subtitle: 'Tinjau testimoni tentang ekskul.',
                onTap: () => _open(context, const TestimoniManageScreen()),
              ),
              _MenuTile(
                icon: Icons.help_outline,
                title: 'FAQ',
                subtitle: 'Jawab pertanyaan dari calon anggota.',
                onTap: () => _open(context, const KetuaFaqScreen()),
              ),
            ],
          ),
          const SizedBox(height: 26),
          _MenuSection(
            title: 'Akun',
            children: [
              _MenuTile(
                icon: Icons.person_outline,
                title: 'Profil & Pengaturan',
                subtitle: 'Data diri, keamanan akun, dan keluar.',
                onTap: () => _open(
                  context,
                  Scaffold(
                    appBar: AppBar(title: const Text('Profil & Pengaturan')),
                    body: ProfilScreen(user: user, showHeader: false),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final ekskulName = user.aktivEkskul?.namaEkskul ?? 'Ekstrakurikuler';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.sky, Color(0xFF60A5FA), AppTheme.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.blue.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  user.namaTampilan.isEmpty ? '?' : user.namaTampilan[0],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'KETUA',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF1D4ED8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'EKSTRAKURIKULER',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ekskulName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 25,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Dikelola oleh ${user.namaTampilan}',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          children[i],
        ],
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppTheme.blue, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
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
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.sub,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: Icon(
                    Icons.chevron_right,
                    color: AppTheme.sub,
                    size: 22,
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
