import 'package:material_ui/material_ui.dart';

import '../../models/models.dart';
import '../profil/profil_screen.dart';

class SiswaInfoScreen extends StatelessWidget {
  const SiswaInfoScreen({super.key, required this.pendaftaran});

  final Pendaftaran pendaftaran;

  @override
  Widget build(BuildContext context) {
    final siswaData = Map<String, dynamic>.from(
      pendaftaran.siswaRaw ?? const <String, dynamic>{},
    );
    final name = pendaftaran.siswaNama?.trim().isNotEmpty == true
        ? pendaftaran.siswaNama!.trim()
        : 'Informasi Siswa';
    siswaData['nama'] = name;
    siswaData['jabatan'] =
        pendaftaran.siswaJabatan ?? siswaData['jabatan'] ?? 'anggota';

    final user = AuthUser(
      id: (siswaData['id'] as num?)?.toInt() ?? 0,
      username: '',
      email: '',
      role: 'siswa',
      needsOnboarding: false,
      needsProfileCompletion: false,
      siswa: Siswa.fromJson(siswaData),
      aktivEkskul: pendaftaran.ekskul,
      jabatan: pendaftaran.siswaJabatan,
      foto: siswaData['foto']?.toString(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Informasi Siswa')),
      body: ProfilScreen(
        user: user,
        showHeader: false,
        readOnly: true,
        enrollment: pendaftaran,
      ),
    );
  }
}
