import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'profil_edit_screen.dart';

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key, required this.user, this.showHeader = true});

  final AuthUser user;
  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siswa = user.siswa;

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, showHeader ? 0 : 16, 16, 24),
        children: [
          if (showHeader)
            const PageHeader(
              title: 'Profil & Pengaturan',
              subtitle: 'Informasi akun dan preferensi keamanan.',
              eyebrow: 'AKUN',
              topPadding: 25,
            ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.sky, Color(0xFF60A5FA), AppTheme.blue],
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
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        user.namaTampilan.isEmpty
                            ? '?'
                            : user.namaTampilan[0].toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
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
                        user.isKetua ? 'KETUA' : 'SISWA',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF1D4ED8),
                          fontSize: 10,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  user.namaTampilan,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 25,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  siswa?.kelas?.nama.isNotEmpty == true
                      ? '${siswa!.kelas!.nama} · ${user.isKetua ? 'Ketua Ekskul' : (siswa.jabatan)}'
                      : user.isKetua
                      ? 'Ketua ekstrakurikuler'
                      : 'Siswa',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _contentCard(
            icon: Icons.badge_outlined,
            title: 'Data Diri',
            subtitle: 'Informasi akun dan identitas sekolahmu.',
            child: Column(
              children: [
                _row(Icons.alternate_email, 'Username', user.username),
                _divider(),
                _row(Icons.mail_outline, 'Email', user.email),
                _divider(),
                _row(Icons.badge_outlined, 'NIS', siswa?.nis ?? '-'),
                _divider(),
                _row(
                  Icons.person_outline,
                  'Jenis Kelamin',
                  siswa?.jenisKelamin ?? '-',
                ),
                _divider(),
                _row(Icons.school_outlined, 'Kelas', siswa?.kelas?.nama ?? '-'),
                _divider(),
                _row(
                  Icons.verified_outlined,
                  'Jabatan',
                  user.isKetua ? 'Ketua Ekskul' : (siswa?.jabatan ?? '-'),
                ),
                if (user.aktivEkskul != null) ...[
                  _divider(),
                  _row(
                    Icons.explore_outlined,
                    'Ekskul Aktif',
                    user.aktivEkskul!.namaEkskul,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _contentCard(
            icon: Icons.lock_outline_rounded,
            title: 'Akun & Keamanan',
            subtitle: 'Kelola akses ke akunmu.',
            child: Column(
              children: [
                _actionRow(
                  icon: Icons.edit_outlined,
                  label: 'Edit Profil',
                  subtitle: 'Perbarui data pribadimu.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilEditScreen(user: user),
                    ),
                  ),
                ),
                _divider(),
                _actionRow(
                  icon: Icons.key_outlined,
                  label: 'Ubah Kata Sandi',
                  subtitle: 'Buat kata sandi baru untuk keamanan akun.',
                  onTap: () => _changePassword(context, ref),
                ),
                _divider(),
                _actionRow(
                  icon: Icons.logout,
                  label: 'Logout',
                  subtitle: 'Keluar dari aplikasi.',
                  color: const Color(0xFFE11D48),
                  iconBackground: const Color(0xFFFFF1F2),
                  onTap: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.sub,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    Color color = AppTheme.blue,
    Color iconBackground = const Color(0xFFEFF6FF),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
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
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: AppTheme.sub, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9));
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final current = TextEditingController();
    final password = TextEditingController();
    final confirmation = TextEditingController();
    String? validationMessage;
    final payload = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.blueBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: AppTheme.blue,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Ubah Kata Sandi')),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buat kata sandi baru untuk menjaga keamanan akun.',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.sub,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: current,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Kata sandi saat ini',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Kata sandi baru',
                        helperText: 'Minimal 8 karakter',
                        prefixIcon: Icon(Icons.key_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: confirmation,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Konfirmasi kata sandi baru',
                        prefixIcon: Icon(Icons.key_rounded),
                      ),
                    ),
                    if (validationMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        validationMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFE11D48),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              FilledButton.icon(
                onPressed: () {
                  final message = current.text.isEmpty
                      ? 'Masukkan kata sandi saat ini.'
                      : password.text.length < 8
                      ? 'Kata sandi baru minimal 8 karakter.'
                      : password.text != confirmation.text
                      ? 'Konfirmasi kata sandi belum sesuai.'
                      : null;
                  if (message != null) {
                    setDialogState(() => validationMessage = message);
                    return;
                  }
                  Navigator.pop(dialogContext, {
                    'current_password': current.text,
                    'password': password.text,
                    'password_confirmation': confirmation.text,
                  });
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
    current.dispose();
    password.dispose();
    confirmation.dispose();
    if (payload == null || !context.mounted) return;

    try {
      await ref.read(apiClientProvider).post('/siswa/password', data: payload);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kata sandi berhasil diperbarui.')),
        );
      }
    } catch (error) {
      if (context.mounted) await showErrorDialog(context, ref, error);
    }
  }
}
