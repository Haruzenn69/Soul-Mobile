import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class TambahAnggotaScreen extends ConsumerStatefulWidget {
  const TambahAnggotaScreen({super.key});

  @override
  ConsumerState<TambahAnggotaScreen> createState() =>
      _TambahAnggotaScreenState();
}

class _TambahAnggotaScreenState extends ConsumerState<TambahAnggotaScreen> {
  final _searchController = TextEditingController();
  final _selectedStudents = <int, Map<String, dynamic>>{};
  final _students = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _classes = const [];
  Timer? _searchDebounce;
  String _query = '';
  String? _error;
  String? _classError;
  int? _selectedClassId;
  int _page = 0;
  int _lastPage = 1;
  int _total = 0;
  int _requestId = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _loadingClasses = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _loadStudents(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final response = await ref.read(apiClientProvider).get('/siswa/kelas');
      final classes = listOf(dataOf(response), 'kelas');
      if (!mounted) return;
      setState(() {
        _classes = classes;
        _classError = null;
        _loadingClasses = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _classError = error.toString();
        _loadingClasses = false;
      });
    }
  }

  Future<void> _loadStudents({required bool reset, int? page}) async {
    if (!reset && (_loading || _loadingMore)) return;
    final requestId = ++_requestId;
    final requestedPage = reset ? 1 : page ?? _page + 1;
    final query = _query;
    final classId = _selectedClassId;
    setState(() {
      _error = null;
      if (reset) {
        _loading = true;
        _loadingMore = false;
        _page = 0;
        _lastPage = 1;
        _students.clear();
      } else {
        _loadingMore = true;
      }
    });

    try {
      final response = await ref
          .read(apiClientProvider)
          .get(
            '/ketua/anggota/calon-siswa',
            query: {
              ...?(query.isEmpty ? null : {'q': query}),
              ...?(classId == null ? null : {'kelas_id': classId}),
              'page': requestedPage,
            },
          );
      final data = dataOf(response) ?? {};
      if (!mounted || requestId != _requestId) return;
      setState(() {
        final items = listOf(data, 'items');
        _students
          ..clear()
          ..addAll(items);
        _page = (data['current_page'] as num?)?.toInt() ?? requestedPage;
        _lastPage = (data['last_page'] as num?)?.toInt() ?? _page;
        _total = (data['total'] as num?)?.toInt() ?? items.length;
        _loading = false;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = error.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _query = value.trim();
      _loadStudents(reset: true);
    });
  }

  void _toggleStudent(Map<String, dynamic> student) {
    final id = (student['id'] as num?)?.toInt();
    if (id == null) return;
    setState(() {
      if (_selectedStudents.remove(id) != null) return;
      if (_selectedStudents.length >= 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maksimal 100 siswa per pengiriman.')),
        );
        return;
      }
      _selectedStudents[id] = student;
    });
  }

  void _toggleVisibleStudents() {
    final visibleStudents = _students.where((student) {
      final id = (student['id'] as num?)?.toInt();
      return id != null &&
          student['sudah_aktif'] != true &&
          !_selectedStudents.containsKey(id);
    });
    setState(() {
      for (final student in visibleStudents) {
        if (_selectedStudents.length >= 100) break;
        final id = (student['id'] as num).toInt();
        _selectedStudents[id] = student;
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedStudents.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .post(
            '/ketua/anggota',
            data: {'siswa_ids': _selectedStudents.keys.toList()},
          );
      ref.invalidate(ketuaAnggotaProvider);
      ref.invalidate(ketuaDashboardProvider);
      if (!mounted) return;
      Navigator.of(context).pop(
        response['message']?.toString() ??
            'Berhasil menambahkan siswa ke ekstrakurikuler.',
      );
    } catch (error) {
      if (mounted) await showErrorDialog(context, ref, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Anggota')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari nama, NIS, atau kelas...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _loadingClasses
                ? const LinearProgressIndicator()
                : _classError != null
                ? BuildErrorCard(message: _classError!, onRetry: _loadClasses)
                : DropdownButtonFormField<int?>(
                    initialValue: _selectedClassId,
                    decoration: const InputDecoration(
                      labelText: 'Filter kelas',
                      prefixIcon: Icon(Icons.class_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Semua kelas'),
                      ),
                      for (final kelas in _classes)
                        DropdownMenuItem<int?>(
                          value: (kelas['id'] as num?)?.toInt(),
                          child: Text(
                            kelas['nama']?.toString() ?? 'Kelas',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (id) {
                      setState(() => _selectedClassId = id);
                      _loadStudents(reset: true);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _loading
                        ? 'Memuat daftar siswa...'
                        : 'Halaman $_page dari $_lastPage · $_total siswa tersedia',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.mutedText(context),
                      fontSize: 11,
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      _students.any((student) {
                        final id = (student['id'] as num?)?.toInt();
                        return id != null &&
                            student['sudah_aktif'] != true &&
                            !_selectedStudents.containsKey(id);
                      })
                      ? _toggleVisibleStudents
                      : null,
                  child: const Text('Pilih hasil ini'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _page > 1 && !_loadingMore
                      ? () => _loadStudents(reset: false, page: _page - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const Text('Sebelumnya'),
                ),
                _loadingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : StatusChip('${_selectedStudents.length} dipilih'),
                TextButton.icon(
                  onPressed: _page < _lastPage && !_loadingMore
                      ? () => _loadStudents(reset: false, page: _page + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('Berikutnya'),
                ),
              ],
            ),
          ),
          Expanded(child: _buildStudentList()),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const ValueKey('submit-direct-members'),
              onPressed: _selectedStudents.isEmpty || _sending ? null : _submit,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: Text(
                _sending
                    ? 'Menambahkan...'
                    : 'Tambahkan ${_selectedStudents.length} siswa',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return BuildErrorCard(
        message: _error!,
        onRetry: () => _loadStudents(reset: true),
      );
    }
    if (_students.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 32),
        children: [
          EmptyState(
            title: _query.isEmpty
                ? 'Tidak ada siswa yang tersedia'
                : 'Siswa tidak ditemukan',
            subtitle: _query.isEmpty
                ? 'Coba muat ulang atau periksa data siswa.'
                : 'Coba kata kunci nama, NIS, atau kelas lain.',
            icon: Icons.person_search_outlined,
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadStudents(reset: true),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: _students.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final student = _students[index];
          final id = (student['id'] as num?)?.toInt();
          final alreadyActive = student['sudah_aktif'] == true;
          final selected = id != null && _selectedStudents.containsKey(id);
          return Card(
            child: InkWell(
              onTap: id == null || alreadyActive
                  ? null
                  : () => _toggleStudent(student),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    PersonAvatar(
                      name: student['nama']?.toString() ?? 'Siswa',
                      photoUrl: student['foto']?.toString(),
                      radius: 22,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student['nama']?.toString() ?? 'Siswa',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.text(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${student['kelas'] ?? 'Tanpa kelas'} · NIS ${student['nis'] ?? '-'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.mutedText(context),
                              fontSize: 10.5,
                            ),
                          ),
                          if (!alreadyActive &&
                              student['status_sebelumnya'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${student['status_sebelumnya']} · ${student['tanggal_daftar_sebelumnya'] ?? 'Riwayat sebelumnya'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.mutedText(context),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (alreadyActive)
                      const StatusChip('Sudah aktif')
                    else
                      Checkbox(
                        value: selected,
                        onChanged: id == null
                            ? null
                            : (_) => _toggleStudent(student),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
