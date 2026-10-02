import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../profil_ekskul/profil_ekskul_screen.dart';
import '../faq/ketua_faq_screen.dart';
import '../testimoni/testimoni_manage_screen.dart';
import 'profil_edit_screen.dart';

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siswa = user.siswa;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const PageHeader(
            title: 'Profil & Pengaturan',
            subtitle: 'Informasi akun dan preferensi keamanan.',
            eyebrow: 'AKUN',
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.sky, Color(0xFF60A5FA), AppTheme.blue],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
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
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.namaTampilan,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        siswa?.kelas?.nama.isNotEmpty == true
                            ? '${siswa!.kelas!.nama} · ${user.isKetua ? 'Ketua Ekskul' : (siswa.jabatan)}'
                            : user.isKetua
                            ? 'Ketua ekstrakurikuler'
                            : 'Siswa',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.line),
            ),
            child: Column(
              children: [
                _row(Icons.badge_outlined, 'Username', user.username),
                _row(Icons.alternate_email, 'Email', user.email),
                _row(Icons.badge_outlined, 'NIS', siswa?.nis ?? '-'),
                _row(
                  Icons.person_outline,
                  'Jenis Kelamin',
                  siswa?.jenisKelamin ?? '-',
                ),
                _row(Icons.school_outlined, 'Kelas', siswa?.kelas?.nama ?? '-'),
                _row(
                  Icons.verified_outlined,
                  'Jabatan',
                  user.isKetua ? 'Ketua Ekskul' : (siswa?.jabatan ?? '-'),
                ),
                if (user.aktivEkskul != null)
                  _row(
                    Icons.explore_outlined,
                    'Ekskul Aktif',
                    user.aktivEkskul!.namaEkskul,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (user.isKetua) ...[
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilEkskulScreen(user: user),
                ),
              ),
              icon: const Icon(Icons.tune_outlined),
              label: const Text('Kelola Profil Ekskul & Prestasi'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TestimoniManageScreen(),
                ),
              ),
              icon: const Icon(Icons.reviews_outlined),
              label: const Text('Kelola Testimoni Ekskul'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KetuaFaqScreen()),
              ),
              icon: const Icon(Icons.help_outline),
              label: const Text('Kelola FAQ Ekskul'),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfilEditScreen(user: user)),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profil'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _changePassword(context, ref),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Ubah Kata Sandi'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE11D48),
              side: const BorderSide(color: Color(0xFFFECDD3)),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
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

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.sub,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
