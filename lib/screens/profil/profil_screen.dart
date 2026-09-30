import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

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
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.blue,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.blue.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Icon(Icons.person, color: Colors.white, size: 46),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              user.namaTampilan,
              style: GoogleFonts.inter(
                color: AppTheme.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (siswa?.kelas?.nama.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${siswa!.kelas!.nama} · ${siswa.jabatan}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppTheme.sub,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                _row(Icons.badge_outlined, 'Username', user.username),
                _row(Icons.alternate_email, 'Email', user.email),
                _row(Icons.badge_outlined, 'NIS',
                    siswa?.nis ?? '-'),
                _row(Icons.person_outline, 'Jenis Kelamin',
                    siswa?.jenisKelamin ?? '-'),
                _row(Icons.school_outlined, 'Kelas',
                    siswa?.kelas?.nama ?? '-'),
                _row(Icons.verified_outlined, 'Jabatan',
                    user.isKetua ? 'Ketua Ekskul' : (siswa?.jabatan ?? '-')),
                if (user.aktivEkskul != null)
                  _row(Icons.explore_outlined, 'Ekskul Aktif',
                      user.aktivEkskul!.namaEkskul),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _editProfile(context, ref, user),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profil'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).logout(),
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

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    AuthUser user,
  ) async {
    final email = TextEditingController(text: user.email);
    var gender = user.siswa?.jenisKelamin;
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Profil'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: gender == 'laki-laki' || gender == 'perempuan'
                      ? gender
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Jenis kelamin',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'laki-laki', child: Text('Laki-laki')),
                    DropdownMenuItem(
                      value: 'perempuan', child: Text('Perempuan')),
                  ],
                  onChanged: (value) => setState(() => gender = value),
                  validator: (value) => value == null
                      ? 'Jenis kelamin wajib dipilih' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    if (!value.contains('@')) return 'Email tidak valid';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await ref.read(apiClientProvider).post('/siswa/profile',
                    data: {
                      'jenis_kelamin': gender,
                      'email': email.text.trim().isEmpty
                          ? null : email.text.trim(),
                    });
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, true);
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    await showErrorDialog(dialogContext, ref, e);
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    email.dispose();

    if (saved == true) {
      ref.invalidate(siswaProfilProvider);
      ref.invalidate(siswaDashboardProvider);
      ref.read(authControllerProvider.notifier).refreshSession();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui.')),
        );
      }
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
              style: GoogleFonts.inter(
                color: AppTheme.sub,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
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
