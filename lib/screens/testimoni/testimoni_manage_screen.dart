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
      appBar: AppBar(
        title: const Text('Kelola Testimoni'),
        actions: [
          IconButton(
            onPressed: _tambahTestimoni,
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Testimoni',
          ),
        ],
      ),
      body: ApiAsyncView(
        value: state,
        onRetry: () => ref.invalidate(ketuaTestimoniProvider(_selectedStatus)),
        builder: (context, data) {
          final pendingCount = (data['pending_count'] as num?)?.toInt() ?? 0;
          final items = listOf(data, 'testimonis');

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip('semua', 'Semua'),
                      const SizedBox(width: 8),
                      _buildChip(
                        'pending',
                        'Pending${pendingCount > 0 ? ' ($pendingCount)' : ''}',
                      ),
                      const SizedBox(width: 8),
                      _buildChip('approved', 'Disetujui'),
                      const SizedBox(width: 8),
                      _buildChip('rejected', 'Ditolak'),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(ketuaTestimoniProvider(_selectedStatus));
                    try {
                      await ref
                          .read(ketuaTestimoniProvider(_selectedStatus).future);
                    } catch (_) {}
                  },
                  child: items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 60),
                            EmptyState(
                              title: 'Belum ada testimoni',
                              subtitle: 'Testimoni yang dikirim siswa akan muncul di sini.',
                              icon: Icons.reviews_outlined,
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final item = items[i];
                            final id = (item['id'] as num?)?.toInt() ?? 0;
                            final status =
                                item['status'] as String? ?? 'pending';

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item['nama'] ?? '-'}${item['kelas'] != null ? ' · ${item['kelas']}' : ''}',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: AppTheme.ink,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      StatusChip(status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '“${item['quote'] ?? ''}”',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.sub,
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
                                              horizontal: 10,
                                              vertical: 4,
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
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                          ),
                                          onPressed: () => _approve(id),
                                          child: const Text('Setujui'),
                                        ),
                                        const SizedBox(width: 8),
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

  Widget _buildChip(String value, String label) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedStatus = value);
      },
    );
  }
}
