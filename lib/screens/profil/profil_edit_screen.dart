import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../core/upload_check.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class ProfilEditScreen extends ConsumerStatefulWidget {
  const ProfilEditScreen({super.key, required this.user});

  final AuthUser user;

  @override
  ConsumerState<ProfilEditScreen> createState() => _ProfilEditScreenState();
}

class _ProfilEditScreenState extends ConsumerState<ProfilEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {};
  bool _loading = true;
  bool _saving = false;
  Object? _loadError;
  String? _gender;
  XFile? _photo;
  Uint8List? _photoBytes;

  @override
  void initState() {
    super.initState();
    _createFields();
    _loadProfile();
  }

  void _createFields([Map<String, dynamic> profile = const {}]) {
    final initialValues = <String, String>{
      'username': profile['username']?.toString() ?? widget.user.username,
      'email': profile['email']?.toString() ?? widget.user.email,
      'tempat_lahir': profile['tempat_lahir']?.toString() ?? '',
      'tanggal_lahir': profile['tanggal_lahir']?.toString() ?? '',
      'agama': profile['agama']?.toString() ?? '',
      'angkatan': profile['angkatan']?.toString() ?? '',
      'no_telp': profile['no_telp']?.toString() ?? '',
      'alamat': profile['alamat']?.toString() ?? '',
      'medsos': profile['medsos']?.toString() ?? '',
    };
    for (final entry in initialValues.entries) {
      _fields.putIfAbsent(
        entry.key,
        () => TextEditingController(text: entry.value),
      );
      _fields[entry.key]!.text = entry.value;
    }
    _gender =
        profile['jenis_kelamin']?.toString() ?? widget.user.siswa?.jenisKelamin;
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final response = await ref.read(apiClientProvider).get('/siswa/profile');
      final data = response['data'];
      final raw = data is Map ? data['siswa'] : null;
      final profile = raw is Map
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _createFields(profile);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await readImageBytesChecked(picked, label: 'Foto profil');
      if (!mounted) return;
      setState(() {
        _photo = picked;
        _photoBytes = bytes;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(apiClientProvider)
          .postMultipart(
            '/siswa/profile',
            fields: {
              for (final entry in _fields.entries)
                entry.key: entry.value.text.trim(),
              'jenis_kelamin': _gender ?? '',
            },
            files: _photo == null
                ? const []
                : [
                    MultipartFile.fromBytes(
                      _photoBytes!,
                      filename: _photo!.name,
                    ),
                  ],
            fileKeys: const ['foto'],
          );
      ref.invalidate(siswaProfilProvider);
      ref.invalidate(siswaDashboardProvider);
      ref.read(authControllerProvider.notifier).refreshSession();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) await showErrorDialog(context, ref, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _loadFailure()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _introCard(),
                  const SizedBox(height: 16),
                  _photoCard(),
                  const SizedBox(height: 16),
                  _personalInfoCard(),
                  const SizedBox(height: 16),
                  _additionalInfoCard(),
                ],
              ),
            ),
      bottomNavigationBar: _loading || _loadError != null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Menyimpan...' : 'Simpan Perubahan'),
              ),
            ),
    );
  }

  Widget _loadFailure() {
    final message = _loadError is ApiException
        ? (_loadError! as ApiException).message
        : 'Profil gagal dimuat. Periksa koneksi lalu coba lagi.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BuildErrorCard(message: message),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _introCard() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppTheme.blue, Color(0xFF38BDF8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.manage_accounts_outlined,
          color: Colors.white,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Pastikan informasi akun dan data diri kamu selalu terbaru.',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _photoCard() => _formCard(
    title: 'Foto Profil',
    subtitle: 'Gunakan foto yang jelas dan mudah dikenali.',
    child: Row(
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: AppTheme.blueBg,
          backgroundImage: _photoBytes == null
              ? null
              : MemoryImage(_photoBytes!),
          child: _photoBytes == null
              ? const Icon(Icons.person_outline, color: AppTheme.blue, size: 34)
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Pilih Foto'),
          ),
        ),
      ],
    ),
  );

  Widget _personalInfoCard() => _formCard(
    title: 'Informasi Akun',
    subtitle: 'Data yang digunakan untuk mengenali akun kamu.',
    child: Column(
      children: [
        _field(
          'username',
          'Username',
          validator: (value) => (value ?? '').trim().length < 3
              ? 'Username minimal 3 karakter.'
              : null,
        ),
        _field(
          'email',
          'Email',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            final email = (value ?? '').trim();
            return email.isNotEmpty && !email.contains('@')
                ? 'Format email tidak valid.'
                : null;
          },
        ),
        DropdownButtonFormField<String>(
          initialValue: _gender == 'laki-laki' || _gender == 'perempuan'
              ? _gender
              : null,
          decoration: const InputDecoration(labelText: 'Jenis kelamin'),
          items: const [
            DropdownMenuItem(value: 'laki-laki', child: Text('Laki-laki')),
            DropdownMenuItem(value: 'perempuan', child: Text('Perempuan')),
          ],
          onChanged: (value) => setState(() => _gender = value),
          validator: (value) =>
              value == null ? 'Jenis kelamin wajib dipilih.' : null,
        ),
      ],
    ),
  );

  Widget _additionalInfoCard() => _formCard(
    title: 'Data Diri',
    subtitle: 'Lengkapi informasi tambahan agar data tetap akurat.',
    child: Column(
      children: [
        _field('tempat_lahir', 'Tempat lahir'),
        _field('tanggal_lahir', 'Tanggal lahir (YYYY-MM-DD)'),
        _field('agama', 'Agama'),
        _field('angkatan', 'Angkatan'),
        _field('no_telp', 'Nomor telepon', keyboardType: TextInputType.phone),
        _field('alamat', 'Alamat', maxLines: 3),
        _field('medsos', 'Media sosial'),
      ],
    ),
  );

  Widget _formCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.sub,
            fontSize: 11.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );

  Widget _field(
    String key,
    String label, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: _fields[key],
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: validator,
    ),
  );
}
