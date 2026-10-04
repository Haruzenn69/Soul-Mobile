import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class KetuaFaqScreen extends ConsumerStatefulWidget {
  const KetuaFaqScreen({super.key});

  @override
  ConsumerState<KetuaFaqScreen> createState() => _KetuaFaqScreenState();
}

class _KetuaFaqScreenState extends ConsumerState<KetuaFaqScreen> {
  String _status = 'semua';
  String _query = '';
  late Future<Map<String, dynamic>> _faqs;

  @override
  void initState() {
    super.initState();
    _faqs = _loadFaqs();
  }

  Future<Map<String, dynamic>> _loadFaqs() {
    return ref
        .read(apiClientProvider)
        .get('/ketua/faq', query: {'status': _status});
  }

  Future<void> _reload() {
    final future = _loadFaqs();
    if (mounted) setState(() => _faqs = future);
    return future.then<void>((_) {}, onError: (_) {});
  }

  List<Map<String, dynamic>> _items(Map<String, dynamic> response) {
    final body = response['data'];
    if (body is! Map) return const [];
    final value = body['faqs'];
    final list = value is Map ? value['data'] : value;
    if (list is! List) return const [];
    return list.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  Future<void> _addFaq() async {
    final question = TextEditingController();
    final answer = TextEditingController();
    final input = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah FAQ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: question,
                decoration: const InputDecoration(labelText: 'Pertanyaan'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: answer,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Jawaban'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final q = question.text.trim();
              final a = answer.text.trim();
              if (q.isNotEmpty && a.isNotEmpty) {
                Navigator.pop(context, (q, a));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    question.dispose();
    answer.dispose();
    if (input == null || !mounted) return;

    try {
      await ref
          .read(apiClientProvider)
          .post(
            '/ketua/faq',
            data: {'pertanyaan': input.$1, 'jawaban': input.$2},
          );
      _reload();
    } catch (error) {
      if (mounted) await showErrorDialog(context, ref, error);
    }
  }

  Future<void> _answerFaq(Map<String, dynamic> faq) async {
    final answer = TextEditingController(
      text: faq['jawaban']?.toString() ?? '',
    );
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jawab pertanyaan'),
        content: TextField(
          controller: answer,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Jawaban'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final value = answer.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    answer.dispose();
    if (text == null || !mounted) return;

    try {
      await ref
          .read(apiClientProvider)
          .post('/ketua/faq/${faq['id']}/answer', data: {'jawaban': text});
      _reload();
    } catch (error) {
      if (mounted) await showErrorDialog(context, ref, error);
    }
  }

  Future<void> _deleteFaq(Map<String, dynamic> faq) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus FAQ?'),
        content: const Text('FAQ ini akan dihapus dari profil ekskul.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(apiClientProvider).delete('/ketua/faq/${faq['id']}');
      _reload();
    } catch (error) {
      if (mounted) await showErrorDialog(context, ref, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola FAQ Ekskul')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFaq,
        backgroundColor: AppTheme.blue,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        tooltip: 'Tambah FAQ',
        child: const Icon(Icons.add_rounded),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _faqs,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return BuildErrorCard(
              message: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Gagal memuat FAQ. Coba lagi.',
              onRetry: _reload,
            );
          }
          final data = snapshot.data!;
          final items = _items(data);
          final filtered = _filterFaq(items, _query);
          final body = data['data'];

          return Column(
            children: [
              NameSearchField(
                hint: 'Cari FAQ...',
                onChanged: (value) => setState(() => _query = value),
              ),
              StatusFilterChips(
                items: [
                  StatusFilter('semua', 'Semua', _intCount(body?['total'])),
                  StatusFilter(
                    'pending',
                    'Belum dijawab',
                    _intCount(body?['pending_count']),
                  ),
                  StatusFilter(
                    'answered',
                    'Sudah dijawab',
                    _intCount(body?['answered_count']),
                  ),
                ],
                selected: _status,
                onSelected: (value) {
                  if (_status == value) return;
                  setState(() {
                    _status = value;
                    _faqs = _loadFaqs();
                  });
                },
              ),
              ListCountLabel(count: filtered.length, label: 'FAQ'),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: filtered.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.only(top: 40),
                          children: [
                            EmptyState(
                              title: items.isEmpty
                                  ? 'Belum ada FAQ'
                                  : 'FAQ tidak ditemukan',
                              subtitle: items.isEmpty
                                  ? _faqEmptySubtitle(_status)
                                  : 'Coba kata kunci yang lain.',
                              icon: items.isEmpty
                                  ? Icons.help_outline
                                  : Icons.search_off_rounded,
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final faq = filtered[index];
                            final pending = faq['status'] == 'pending';
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
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.help_outline,
                                          color: AppTheme.blue,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 11),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              faq['pertanyaan']?.toString() ??
                                                  '',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    color: AppTheme.ink,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    height: 1.3,
                                                  ),
                                            ),
                                            if (!pending &&
                                                faq['jawaban'] != null) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                faq['jawaban'].toString(),
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                      color: AppTheme.sub,
                                                      fontSize: 12,
                                                      height: 1.5,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      StatusChip(
                                        pending
                                            ? 'Belum dijawab'
                                            : 'Sudah dijawab',
                                      ),
                                      const Spacer(),
                                      if (pending)
                                        IconButton(
                                          onPressed: () => _answerFaq(faq),
                                          tooltip: 'Jawab',
                                          icon: const Icon(Icons.reply),
                                        ),
                                      IconButton(
                                        onPressed: () => _deleteFaq(faq),
                                        tooltip: 'Hapus',
                                        icon: const Icon(Icons.delete_outline),
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

  String _faqEmptySubtitle(String status) => switch (status) {
    'pending' => 'Belum ada pertanyaan yang perlu dijawab.',
    'answered' => 'Belum ada FAQ yang sudah dijawab.',
    _ => 'Pertanyaan siswa dan FAQ yang dibuat akan tampil di sini.',
  };

  List<Map<String, dynamic>> _filterFaq(
    List<Map<String, dynamic>> items,
    String query,
  ) {
    if (query.isEmpty) return items;
    final q = query.toLowerCase();
    return items
        .where((item) {
          final haystack = [
            item['pertanyaan']?.toString() ?? '',
            item['jawaban']?.toString() ?? '',
          ].join(' ').toLowerCase();
          return haystack.contains(q);
        })
        .toList(growable: false);
  }
}
