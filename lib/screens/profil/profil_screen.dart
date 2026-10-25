import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/common.dart';
import 'profil_edit_screen.dart';
import 'pengajuan_keluar_screen.dart';

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key, required this.user, this.showHeader = true});

  final AuthUser user;
  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siswa = user.siswa;
    final darkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

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
              gradient: AppTheme.brandHeroGradient(context),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brandHeroShadow(context),
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
                    PersonAvatar(
                      name: user.namaTampilan,
                      photoUrl: user.fotoUrl,
                      radius: 28,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
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
            context: context,
            icon: Icons.badge_outlined,
            title: 'Data Diri',
            subtitle: 'Informasi akun dan identitas sekolahmu.',
            child: Column(
              children: [
                _row(context, Icons.alternate_email, 'Username', user.username),
                _divider(context),
                _row(context, Icons.mail_outline, 'Email', user.email),
                _divider(context),
                _row(context, Icons.badge_outlined, 'NIS', siswa?.nis ?? '-'),
                _divider(context),
                _row(
                  context,
                  Icons.person_outline,
                  'Jenis Kelamin',
                  siswa?.jenisKelamin ?? '-',
                ),
                _divider(context),
                _row(
                  context,
                  Icons.school_outlined,
                  'Kelas',
                  siswa?.kelas?.nama ?? '-',
                ),
                _divider(context),
                _row(
                  context,
                  Icons.verified_outlined,
                  'Jabatan',
                  user.isKetua ? 'Ketua Ekskul' : (siswa?.jabatan ?? '-'),
                ),
                if (user.aktivEkskul != null) ...[
                  _divider(context),
                  _row(
                    context,
                    Icons.explore_outlined,
                    'Ekskul Aktif',
                    user.aktivEkskul!.namaEkskul,
                  ),
                ],
              ],
            ),
          ),
          if (!user.isKetua) ...[
            const SizedBox(height: 14),
            _contentCard(
              context: context,
              icon: Icons.exit_to_app_outlined,
              title: 'Ekskul',
              subtitle: 'Keanggotaan ekskul aktifmu.',
              child: Column(
                children: [
                  _actionRow(
                    context: context,
                    icon: Icons.logout_rounded,
                    label: 'Pengajuan Keluar',
                    subtitle: 'Ajukan pengunduran diri dari ekskul aktif.',
                    color: const Color(0xFFB45309),
                    iconBackground: AppTheme.warningSurface(context),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PengajuanKeluarScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          _contentCard(
            context: context,
            icon: Icons.lock_outline_rounded,
            title: 'Akun & Keamanan',
            subtitle: 'Kelola akses ke akunmu.',
            child: Column(
              children: [
                _actionRow(
                  context: context,
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
                _divider(context),
                _actionRow(
                  context: context,
                  icon: Icons.key_outlined,
                  label: 'Ubah Kata Sandi',
                  subtitle: 'Buat kata sandi baru untuk keamanan akun.',
                  onTap: () => _changePassword(context, ref),
                ),
                _divider(context),
                Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.accentSurface(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            darkMode
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: AppTheme.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mode gelap',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Gunakan tampilan gelap aplikasi.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: darkMode,
                          onChanged: (enabled) async {
                            try {
                              await ref
                                  .read(themeModeProvider.notifier)
                                  .setDarkMode(enabled);
                            } catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Preferensi tema gagal disimpan.',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                _divider(context),
                _actionRow(
                  context: context,
                  icon: Icons.logout,
                  label: 'Logout',
                  subtitle: 'Keluar dari aplikasi.',
                  color: const Color(0xFFE11D48),
                  iconBackground: AppTheme.dangerSurface(context),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Keluar?'),
                        content: const Text(
                          'Kamu akan keluar dari aplikasi dan kembali ke halaman login.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Keluar'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;
                    await ref.read(authControllerProvider.notifier).logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
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
                  color: colors.surfaceContainerHighest,
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
                        color: colors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        color: colors.onSurfaceVariant,
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

  Widget _row(BuildContext context, IconData icon, String label, String value) {
    final colors = Theme.of(context).colorScheme;
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
                color: colors.onSurfaceVariant,
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
                color: colors.onSurface,
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
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    Color color = AppTheme.blue,
    Color? iconBackground,
  }) {
    final colors = Theme.of(context).colorScheme;
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
                color: iconBackground ?? AppTheme.accentSurface(context),
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
                      color: colors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.mutedText(context),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: AppTheme.outline(context));
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
                    color: AppTheme.accentSurface(context),
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
                        color: AppTheme.mutedText(context),
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
