import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  void _reload() {
    if (mounted) setState(() => _faqs = _loadFaqs());
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
      appBar: AppBar(
        title: const Text('Kelola FAQ Ekskul'),
        actions: [
          IconButton(
            onPressed: _addFaq,
            icon: const Icon(Icons.add),
            tooltip: 'Tambah FAQ',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _faqs,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: _reload,
                child: const Text('Gagal memuat FAQ. Coba lagi.'),
              ),
            );
          }
          final data = snapshot.data!;
          final items = _items(data);
          final body = data['data'];
          final pendingCount = body is Map
              ? (body['pending_count'] as num?)?.toInt() ?? 0
              : 0;

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _statusChip('semua', 'Semua'),
                    const SizedBox(width: 8),
                    _statusChip(
                      'pending',
                      'Belum dijawab${pendingCount > 0 ? ' ($pendingCount)' : ''}',
                    ),
                    const SizedBox(width: 8),
                    _statusChip('answered', 'Sudah dijawab'),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 64),
                            EmptyState(
                              title: 'Belum ada FAQ',
                              subtitle: 'Pertanyaan siswa dan FAQ yang dibuat akan tampil di sini.',
                              icon: Icons.help_outline,
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final faq = items[index];
                            final pending = faq['status'] == 'pending';
                            return Card(
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      faq['pertanyaan']?.toString() ?? '',
                                      style: const TextStyle(
                                        color: AppTheme.ink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (!pending && faq['jawaban'] != null) ...[
                                      const SizedBox(height: 8),
                                      Text(faq['jawaban'].toString()),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Chip(
                                          label: Text(
                                            pending
                                                ? 'Belum dijawab'
                                                : 'Sudah dijawab',
                                          ),
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
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

  Widget _statusChip(String status, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _status == status,
      onSelected: (_) {
        if (_status == status) return;
        setState(() {
          _status = status;
          _faqs = _loadFaqs();
        });
      },
    );
  }
}
