import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_config.dart';
import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class ProfilEkskulScreen extends ConsumerStatefulWidget {
  const ProfilEkskulScreen({super.key, required this.user});

  final AuthUser user;

  @override
  ConsumerState<ProfilEkskulScreen> createState() => _ProfilEkskulScreenState();
}

class _ProfilEkskulScreenState extends ConsumerState<ProfilEkskulScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Profil Ekskul'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.blue,
          unselectedLabelColor: AppTheme.sub,
          indicatorColor: AppTheme.blue,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Profil'),
            Tab(text: 'Galeri'),
            Tab(text: 'Prestasi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_ProfilTab(), _GaleriTab(), _PrestasiTab()],
      ),
    );
  }
}

class _ProfilTab extends ConsumerStatefulWidget {
  const _ProfilTab();

  @override
  ConsumerState<_ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends ConsumerState<_ProfilTab> {
  final _nama = TextEditingController();
  final _tagline = TextEditingController();
  final _deskripsi = TextEditingController();
  final _tujuan = TextEditingController();
  final _jadwal = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  bool _isOpenRecruitment = false;
  XFile? _logoFile;
  XFile? _coverFile;
  Uint8List? _logoBytes;
  Uint8List? _coverBytes;

  @override
  void dispose() {
    _nama.dispose();
    _tagline.dispose();
    _deskripsi.dispose();
    _tujuan.dispose();
    _jadwal.dispose();
    super.dispose();
  }

  void _populate(Map<String, dynamic> ekskul) {
    if (_initialized) return;
    _nama.text = ekskul['nama_ekskul'] as String? ?? '';
    _tagline.text = ekskul['tagline'] as String? ?? '';
    _deskripsi.text = ekskul['deskripsi'] as String? ?? '';
    _tujuan.text = ekskul['tujuan'] as String? ?? '';
    _jadwal.text = ekskul['jadwal'] as String? ?? '';
    _isOpenRecruitment = ekskul['is_open_recruitment'] as bool? ?? false;
    _initialized = true;
  }

  Future<void> _toggleRecruitment() async {
    try {
      await ref
          .read(apiClientProvider)
          .post('/ketua/profil-ekskul/toggle-recruitment');
      setState(() => _isOpenRecruitment = !_isOpenRecruitment);
      ref.invalidate(ketuaProfilEkskulProvider);
      ref.invalidate(ketuaDashboardProvider);
      ref.invalidate(katalogProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isOpenRecruitment
                  ? 'Pendaftaran ekskul dibuka!'
                  : 'Pendaftaran ekskul ditutup!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) await showErrorDialog(context, ref, e);
    }
  }

  Future<void> _saveProfile() async {
    if (_nama.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama ekskul tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final files = <MultipartFile>[];
      final fileKeys = <String>[];
      if (_logoFile != null) {
        files.add(
          MultipartFile.fromBytes(_logoBytes!, filename: _logoFile!.name),
        );
        fileKeys.add('logo');
      }
      if (_coverFile != null) {
        files.add(
          MultipartFile.fromBytes(_coverBytes!, filename: _coverFile!.name),
        );
        fileKeys.add('cover');
      }
      await ref
          .read(apiClientProvider)
          .postMultipart(
            '/ketua/profil-ekskul/update',
            fields: {
              'nama_ekskul': _nama.text.trim(),
              'tagline': _tagline.text.trim(),
              'deskripsi': _deskripsi.text.trim(),
              'tujuan': _tujuan.text.trim(),
              'jadwal': _jadwal.text.trim(),
            },
            files: files,
            fileKeys: fileKeys,
          );
      ref.invalidate(ketuaProfilEkskulProvider);
      ref.invalidate(ketuaDashboardProvider);
      ref.invalidate(katalogProvider);
      _logoFile = null;
      _coverFile = null;
      _logoBytes = null;
      _coverBytes = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil ekskul berhasil diperbarui!')),
        );
      }
    } catch (e) {
      if (mounted) await showErrorDialog(context, ref, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickBrandImage({required bool logo}) async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        if (logo) {
          _logoFile = image;
          _logoBytes = bytes;
        } else {
          _coverFile = image;
          _coverBytes = bytes;
        }
      });
    } catch (error) {
      if (mounted) await showErrorDialog(context, ref, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ketuaProfilEkskulProvider);

    return ApiAsyncView(
      value: state,
      builder: (context, data) {
        final ekskul = data['ekskul'] is Map
            ? Map<String, dynamic>.from(data['ekskul'] as Map)
            : <String, dynamic>{};
        _populate(ekskul);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pendaftaran Anggota Baru',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.ink,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isOpenRecruitment
                              ? 'Status: Buka (Siswa dapat mendaftar)'
                              : 'Status: Tutup (Pendaftaran dinonaktifkan)',
                          style: GoogleFonts.plusJakartaSans(
                            color: _isOpenRecruitment
                                ? const Color(0xFF16803C)
                                : AppTheme.sub,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isOpenRecruitment,
                    activeThumbImage: null,
                    onChanged: (_) => _toggleRecruitment(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi Utama Ekskul',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickBrandImage(logo: true),
                          icon: const Icon(Icons.image_outlined),
                          label: Text(
                            _logoFile?.name ?? 'Pilih logo (maks. 2 MB)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickBrandImage(logo: false),
                          icon: const Icon(Icons.panorama_outlined),
                          label: Text(
                            _coverFile?.name ?? 'Pilih cover (maks. 2 MB)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nama,
                    decoration: const InputDecoration(
                      labelText: 'Nama Ekskul *',
                      hintText: 'Contoh: Basket, Paskibra',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tagline,
                    decoration: const InputDecoration(
                      labelText: 'Tagline / Slogan',
                      hintText: 'Contoh: Sportif, Tangguh, Berprestasi',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _jadwal,
                    decoration: const InputDecoration(
                      labelText: 'Jadwal Rutin',
                      hintText: 'Contoh: Setiap Selasa & Jumat 15:30',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _deskripsi,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Ekskul',
                      hintText: 'Jelaskan profil kegiatan ekskul...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tujuan,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Tujuan & Visi',
                      hintText: 'Tujuan dibentuknya ekskul...',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveProfile,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Simpan Perubahan'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GaleriTab extends ConsumerWidget {
  const _GaleriTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ketuaProfilEkskulProvider);

    return ApiAsyncView(
      value: state,
      builder: (context, data) {
        final galeris = (data['galeris'] as List?) ?? const [];

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => _uploadGallery(context, ref),
            tooltip: 'Tambah foto galeri',
            child: const Icon(Icons.add_photo_alternate_outlined),
          ),
          body: galeris.isEmpty
              ? const EmptyState(
                  title: 'Belum ada foto galeri',
                  subtitle: 'Tekan tombol + untuk menambahkan galeri baru.',
                  icon: Icons.photo_library_outlined,
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: galeris.length,
                  itemBuilder: (context, i) {
                    final item = galeris[i] is Map
                        ? Map<String, dynamic>.from(galeris[i] as Map)
                        : <String, dynamic>{};
                    final fotoUrl = AppConfig.imageUrl(item['foto'] as String?);

                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            fotoUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: Colors.black12,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () => _deleteGaleri(
                                context,
                                ref,
                                (item['id'] as num).toInt(),
                              ),
                            ),
                          ),
                        ),
                        if ((item['caption'] as String?)?.isNotEmpty == true)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(14),
                                ),
                              ),
                              child: Text(
                                item['caption'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

  Future<void> _uploadGallery(BuildContext context, WidgetRef ref) async {
    final photos = await ImagePicker().pickMultiImage(
      imageQuality: 85,
      limit: 10,
    );
    if (photos.isEmpty || !context.mounted) return;
    final captionController = TextEditingController();
    final caption = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah foto galeri'),
        content: TextField(
          controller: captionController,
          maxLength: 255,
          decoration: const InputDecoration(labelText: 'Keterangan (opsional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, captionController.text.trim()),
            child: const Text('Unggah'),
          ),
        ],
      ),
    );
    captionController.dispose();
    if (caption == null || !context.mounted) return;

    try {
      final files = <MultipartFile>[];
      for (final photo in photos) {
        files.add(
          MultipartFile.fromBytes(
            await photo.readAsBytes(),
            filename: photo.name,
          ),
        );
      }
      await ref
          .read(apiClientProvider)
          .postMultipart(
            '/ketua/profil-ekskul/galeri',
            fields: {'caption': caption},
            files: files,
            fileKeys: List.filled(files.length, 'foto[]'),
          );
      ref.invalidate(ketuaProfilEkskulProvider);
      ref.invalidate(katalogProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto galeri berhasil ditambahkan.')),
        );
      }
    } catch (error) {
      if (context.mounted) await showErrorDialog(context, ref, error);
    }
  }

  Future<void> _deleteGaleri(
    BuildContext context,
    WidgetRef ref,
    int galeriId,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Foto Galeri?'),
        content: const Text('Foto ini akan dihapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref
          .read(apiClientProvider)
          .delete('/ketua/profil-ekskul/galeri/$galeriId');
      ref.invalidate(ketuaProfilEkskulProvider);
      ref.invalidate(katalogProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto galeri berhasil dihapus.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        await showErrorDialog(context, ref, e);
      }
    }
  }
}

class _PrestasiTab extends ConsumerStatefulWidget {
  const _PrestasiTab();

  @override
  ConsumerState<_PrestasiTab> createState() => _PrestasiTabState();
}

class _PrestasiTabState extends ConsumerState<_PrestasiTab> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ketuaPrestasiProvider);

    return Scaffold(
      body: ApiAsyncView(
        value: state,
        builder: (context, data) {
          final items = listOf(data, 'prestasis');
          if (items.isEmpty) {
            return const EmptyState(
              title: 'Belum ada prestasi',
              subtitle: 'Tekan tombol + di bawah untuk mencatat prestasi baru.',
              icon: Icons.military_tech_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final item = items[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['judul'] as String? ?? 'Prestasi',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${item['kategori'] ?? '-'} · Tahun ${item['tahun'] ?? '-'}',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.sub,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFE11D48),
                        size: 20,
                      ),
                      onPressed: () =>
                          _deletePrestasi((item['id'] as num).toInt()),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tambahPrestasi,
        tooltip: 'Tambah Prestasi',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _tambahPrestasi() async {
    final judul = TextEditingController();
    final kategori = TextEditingController();
    final tahun = TextEditingController(text: DateTime.now().year.toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Tambah Prestasi',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: judul,
                decoration: const InputDecoration(
                  labelText: 'Judul Prestasi *',
                  hintText: 'mis. Juara 1 Futsal Antar Sekolah',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: kategori,
                decoration: const InputDecoration(
                  labelText: 'Kategori / Tingkat',
                  hintText: 'mis. Kota, Provinsi, Nasional',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tahun,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tahun',
                  hintText: 'mis. 2026',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (judul.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    try {
      await ref
          .read(apiClientProvider)
          .post(
            '/ketua/prestasi',
            data: {
              'judul': judul.text.trim(),
              'kategori': kategori.text.trim().isEmpty
                  ? null
                  : kategori.text.trim(),
              'tahun': tahun.text.trim().isEmpty ? null : tahun.text.trim(),
            },
          );
      ref.invalidate(ketuaPrestasiProvider);
      ref.invalidate(katalogProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prestasi berhasil ditambahkan!')),
        );
      }
    } catch (e) {
      if (mounted) await showErrorDialog(context, ref, e);
    }
  }

  Future<void> _deletePrestasi(int prestasiId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Prestasi?'),
        content: const Text('Data prestasi ini akan dihapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(apiClientProvider).delete('/ketua/prestasi/$prestasiId');
      ref.invalidate(ketuaPrestasiProvider);
      ref.invalidate(katalogProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prestasi berhasil dihapus.')),
        );
      }
    } catch (e) {
      if (mounted) await showErrorDialog(context, ref, e);
    }
  }
}
