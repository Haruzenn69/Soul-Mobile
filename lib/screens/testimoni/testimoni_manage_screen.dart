import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class TestimoniManageScreen extends ConsumerStatefulWidget {
  const TestimoniManageScreen({super.key});

  @override
  ConsumerState<TestimoniManageScreen> createState() =>
      _TestimoniManageScreenState();
}

class _TestimoniManageScreenState extends ConsumerState<TestimoniManageScreen> {
  String _selectedStatus = 'semua';
  String _query = '';

  Future<void> _approve(int id) async {
    try {
      await ref
          .read(apiClientProvider)
          .post('/ketua/testimoni/$id/approve', data: {});
      ref.invalidate(ketuaTestimoniProvider(_selectedStatus));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Testimoni berhasil disetujui.')),
        );
      }
    } catch (e) {
      if (mounted) await showErrorDialog(context, ref, e);
    }
  }

  Future<void> _reject(int id) async {
    try {
      await ref
          .read(apiClientProvider)
          .post('/ketua/testimoni/$id/reject', data: {});
      ref.invalidate(ketuaTestimoniProvider(_selectedStatus));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Testimoni ditolak.')));
      }
    } catch (e) {
      if (mounted) await showErrorDialog(context, ref, e);
    }
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Hapus Testimoni?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: const Text('Testimoni akan dihapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await ref.read(apiClientProvider).delete('/ketua/testimoni/$id');
      ref.invalidate(ketuaTestimoniProvider(_selectedStatus));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Testimoni berhasil dihapus.')),
        );
      }
    } catch (e) {
      if (mounted) await showErrorDialog(context, ref, e);
    }
  }

  Future<void> _tambahTestimoni() async {
    final namaCtrl = TextEditingController();
    final kelasCtrl = TextEditingController();
    final quoteCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Tambah Testimoni',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Siswa/Alumni',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: kelasCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kelas / Angkatan',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quoteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Isi Testimoni'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (namaCtrl.text.trim().isEmpty ||
                  quoteCtrl.text.trim().isEmpty) {
                return;
              }
              Navigator.of(ctx).pop(true);
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
            '/ketua/testimoni',
            data: {
              'nama': namaCtrl.text.trim(),
              'kelas': kelasCtrl.text.trim(),
              'quote': quoteCtrl.text.trim(),
            },
          );
      ref.invalidate(ketuaTestimoniProvider(_selectedStatus));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Testimoni berhasil ditambahkan.')),
        );
      }
    } catch (e) {
      if (mounted) await showErrorDialog(context, ref, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ketuaTestimoniProvider(_selectedStatus));

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Testimoni')),
      floatingActionButton: FloatingActionButton(
        onPressed: _tambahTestimoni,
        backgroundColor: AppTheme.blue,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        tooltip: 'Tambah testimoni',
        child: const Icon(Icons.add_rounded),
      ),
      body: ApiAsyncView(
        value: state,
        onRetry: () => ref.invalidate(ketuaTestimoniProvider(_selectedStatus)),
        builder: (context, data) {
          final items = listOf(data, 'testimonis');
          final filtered = _filterTestimoni(items, _query);

          return Column(
            children: [
              NameSearchField(
                hint: 'Cari testimoni...',
                onChanged: (value) => setState(() => _query = value),
              ),
              StatusFilterChips(
                items: [
                  StatusFilter('semua', 'Semua', _intCount(data['total'])),
                  StatusFilter(
                    'pending',
                    'Menunggu',
                    _intCount(data['pending_count']),
                  ),
                  StatusFilter(
                    'approved',
                    'Disetujui',
                    _intCount(data['approved_count']),
                  ),
                  StatusFilter(
                    'rejected',
                    'Ditolak',
                    _intCount(data['rejected_count']),
                  ),
                ],
                selected: _selectedStatus,
                onSelected: (value) => setState(() => _selectedStatus = value),
              ),
              ListCountLabel(count: filtered.length, label: 'testimoni'),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(ketuaTestimoniProvider(_selectedStatus));
                    try {
                      await ref.read(
                        ketuaTestimoniProvider(_selectedStatus).future,
                      );
                    } catch (_) {}
                  },
                  child: filtered.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.only(top: 40),
                          children: [
                            EmptyState(
                              title: items.isEmpty
                                  ? 'Belum ada testimoni'
                                  : 'Testimoni tidak ditemukan',
                              subtitle: items.isEmpty
                                  ? _testimoniEmptySubtitle(_selectedStatus)
                                  : 'Coba kata kunci yang lain.',
                              icon: items.isEmpty
                                  ? Icons.reviews_outlined
                                  : Icons.search_off_rounded,
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final item = filtered[i];
                            final id = (item['id'] as num?)?.toInt() ?? 0;
                            final status =
                                item['status'] as String? ?? 'pending';
                            final nama = item['nama']?.toString() ?? '-';
                            final namaAwal = nama.trim().isEmpty
                                ? '?'
                                : nama.trim()[0].toUpperCase();

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE8EDF5),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0F172A)
                                        .withValues(alpha: 0.035),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          namaAwal,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: AppTheme.blue,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 11),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              nama,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    color: AppTheme.ink,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item['kelas'] is String &&
                                                      (item['kelas'] as String)
                                                          .isNotEmpty
                                                  ? item['kelas'] as String
                                                  : 'Tanpa kelas',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    color: AppTheme.sub,
                                                    fontSize: 11,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusChip(
                                        status == 'approved'
                                            ? 'Disetujui'
                                            : status == 'rejected'
                                            ? 'Ditolak'
                                            : 'Pending',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '“${item['quote'] ?? ''}”',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.ink,
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (status == 'pending') ...[
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFFE11D48,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFE11D48),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            textStyle:
                                                GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                ),
                                          ),
                                          onPressed: () => _reject(id),
                                          child: const Text('Tolak'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF16803C,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 6,
                                            ),
                                            textStyle:
                                                GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                ),
                                          ),
                                          onPressed: () => _approve(id),
                                          child: const Text('Setujui'),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: AppTheme.sub,
                                          size: 20,
                                        ),
                                        onPressed: () => _delete(id),
                                        tooltip: 'Hapus',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int? _intCount(Object? value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  String _testimoniEmptySubtitle(String status) => switch (status) {
    'pending' => 'Belum ada testimoni yang menunggu persetujuan.',
    'approved' => 'Belum ada testimoni yang disetujui.',
    'rejected' => 'Belum ada testimoni yang ditolak.',
    _ => 'Testimoni yang dikirim siswa akan muncul di sini.',
  };

  List<Map<String, dynamic>> _filterTestimoni(
    List<Map<String, dynamic>> items,
    String query,
  ) {
    if (query.isEmpty) return items;
    final q = query.toLowerCase();
    return items
        .where((item) {
          final haystack = [
            item['nama']?.toString() ?? '',
            item['kelas']?.toString() ?? '',
            item['quote']?.toString() ?? '',
          ].join(' ').toLowerCase();
          return haystack.contains(q);
        })
        .toList(growable: false);
  }
}
