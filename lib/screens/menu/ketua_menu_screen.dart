import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../faq/ketua_faq_screen.dart';
import '../kegiatan/rekap_presensi_screen.dart';
import '../notifikasi/notifikasi_screen.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const PageHeader(
            title: 'Menu Ketua',
            subtitle: 'Akses pengelolaan ekskul dan akun.',
            eyebrow: 'PENGATURAN',
          ),
          const SizedBox(height: 18),
          _IdentityCard(user: user),
          const SizedBox(height: 24),
          _MenuSection(
            title: 'Kegiatan',
            children: [
              _MenuTile(
                icon: Icons.fact_check_outlined,
                title: 'Rekap Absensi',
                subtitle: 'Tinjau dan unduh rekap kehadiran.',
                onTap: () => _open(context, const RekapPresensiScreen()),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
          const SizedBox(height: 18),
          _MenuSection(
            title: 'Akun',
            children: [
              _MenuTile(
                icon: Icons.notifications_none_outlined,
                title: 'Notifikasi',
                subtitle: 'Lihat pembaruan tentang ekskul.',
                onTap: () => _open(
                  context,
                  const Scaffold(body: NotifikasiScreen(isKetua: true)),
                ),
              ),
              _MenuTile(
                icon: Icons.person_outline,
                title: 'Profil & Pengaturan',
                subtitle: 'Data diri, keamanan akun, dan keluar.',
                onTap: () => _open(
                  context,
                  Scaffold(
                    appBar: AppBar(title: const Text('Profil & Pengaturan')),
                    body: ProfilScreen(user: user),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.sky, Color(0xFF60A5FA), AppTheme.blue],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            foregroundColor: Colors.white,
            child: Text(
              user.namaTampilan.isEmpty ? '?' : user.namaTampilan[0],
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.namaTampilan,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.aktivEkskul?.namaEkskul ?? 'Ketua ekstrakurikuler',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
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
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.sub,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 56),
                children[i],
              ],
            ],
          ),
        ),
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
    return ListTile(
      minVerticalPadding: 10,
      leading: Icon(icon, color: AppTheme.blue),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.sub),
      onTap: onTap,
    );
  }
}
