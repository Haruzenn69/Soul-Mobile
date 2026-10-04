import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class AnggotaScreen extends ConsumerWidget {
  const AnggotaScreen({
    super.key,
    required this.user,
    this.isKetua = true,
    this.initialTab = 0,
  });

  final AuthUser user;
  final bool isKetua;
  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab.clamp(0, 2),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Anggota',
              subtitle: 'Kelola keanggotaan dan permohonan siswa.',
              eyebrow: 'PENGELOLAAN EKSKUL',
              topPadding: 25,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Container(
                key: const ValueKey('anggota-pill-tabs'),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppTheme.line),
                ),
                child: TabBar(
                  key: ValueKey('anggota-tab-bar'),
                  dividerHeight: 0,
                  overlayColor: WidgetStatePropertyAll(Colors.transparent),
                  labelColor: AppTheme.blue,
                  unselectedLabelColor: AppTheme.sub,
                  indicatorColor: Colors.transparent,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppTheme.blueBg,
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  labelPadding: EdgeInsets.zero,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  tabs: [
                    Tab(height: 30, text: 'Anggota'),
                    Tab(height: 30, text: 'Pendaftaran'),
                    Tab(height: 30, text: 'Pengajuan'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _AnggotaList(user: user),
                  _PendaftaranList(),
                  _PengajuanList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnggotaList extends ConsumerStatefulWidget {
  const _AnggotaList({required this.user});

  final AuthUser user;

  @override
  ConsumerState<_AnggotaList> createState() => _AnggotaListState();
}

class _AnggotaListState extends ConsumerState<_AnggotaList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(ketuaAnggotaProvider);

    return ApiAsyncView(
      value: data,
      onRetry: () => ref.invalidate(ketuaAnggotaProvider),
      builder: (context, d) {
        final items = listOf(d, 'anggotas');
        final filtered = _filterByStudentName(items, _query, (item) {
          final p = Pendaftaran.fromJson(item);
          return p.siswaNama;
        });
        return Column(
          children: [
            _NameSearchField(
              hint: 'Cari nama anggota...',
              onChanged: (value) => setState(() => _query = value),
            ),
            _ListCountLabel(count: filtered.length, label: 'anggota'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                ref.invalidate(ketuaAnggotaProvider);
                try {
                  await ref.read(ketuaAnggotaProvider.future);
                } catch (_) {}
              },
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 24),
                        children: [
                          EmptyState(
                            title: items.isEmpty
                                ? 'Belum ada anggota'
                                : 'Nama anggota tidak ditemukan',
                            subtitle: items.isEmpty
                                ? null
                                : 'Coba kata kunci nama yang lain.',
                            icon: items.isEmpty
                                ? Icons.groups_outlined
                                : Icons.search_off_rounded,
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final p = Pendaftaran.fromJson(filtered[i]);
                          return _AnggotaTile(
                            pendaftaran: p,
                            isSelf: p.siswaRaw?['id'] == widget.user.siswa?.id,
                            onStatus: (status) =>
                                _changeStatus(context, ref, p, status),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    Pendaftaran p,
    String status,
  ) async {
    final actionLabel = switch (status) {
      'diterima' => 'Aktifkan',
      'peringatan' => 'Beri peringatan',
      'nonaktif' => 'Nonaktifkan',
      _ => 'Ubah status',
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionLabel ${p.siswaNama ?? 'anggota'}?'),
        content: Text(switch (status) {
          'peringatan' => 'Siswa akan menerima notifikasi peringatan. Status keanggotaannya tetap aktif.',
          'nonaktif' => 'Siswa tidak lagi dihitung sebagai anggota aktif dan akan menerima notifikasi.',
          _ => 'Siswa akan menerima notifikasi bahwa status keanggotaannya aktif kembali.',
        }),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref
          .read(apiClientProvider)
          .post('/ketua/anggota/${p.id}/status', data: {'status': status});
      ref.invalidate(ketuaAnggotaProvider);
      ref.invalidate(ketuaDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status berhasil diubah: $actionLabel.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        await showErrorDialog(context, ref, e);
      }
    }
  }
}

class _AnggotaTile extends StatelessWidget {
  const _AnggotaTile({
    required this.pendaftaran,
    required this.isSelf,
    required this.onStatus,
  });

  final Pendaftaran pendaftaran;
  final bool isSelf;
  final ValueChanged<String> onStatus;

  List<(String, String)> get _statusActions => switch (pendaftaran.status) {
    'diterima' => [
      ('peringatan', 'Beri peringatan'),
      ('nonaktif', 'Nonaktifkan'),
    ],
    'peringatan' => [
      ('diterima', 'Aktifkan kembali'),
      ('nonaktif', 'Nonaktifkan'),
    ],
    'nonaktif' || 'keluar' => [('diterima', 'Aktifkan kembali')],
    _ => const [],
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: AppTheme.blueBg,
              child: Text(
                (pendaftaran.siswaNama?.isNotEmpty ?? false)
                    ? pendaftaran.siswaNama![0].toUpperCase()
                    : 'S',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pendaftaran.siswaNama ?? 'Anggota',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    pendaftaran.tanggalDaftar ?? 'Tanggal tidak tersedia',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.sub,
                      fontSize: 10.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      StatusChip(pendaftaran.statusLabel),
                      if (isSelf) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.blueBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Anda',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (!isSelf && _statusActions.isNotEmpty)
              PopupMenuButton<String>(
                tooltip: 'Ubah status anggota',
                onSelected: onStatus,
                itemBuilder: (context) => [
                  for (final action in _statusActions)
                    PopupMenuItem<String>(
                      value: action.$1,
                      child: Text(action.$2),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PendaftaranList extends ConsumerStatefulWidget {
  const _PendaftaranList();

  @override
  ConsumerState<_PendaftaranList> createState() => _PendaftaranListState();
}

class _PendaftaranListState extends ConsumerState<_PendaftaranList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(ketuaPendaftaranProvider);

    return ApiAsyncView(
      value: data,
      onRetry: () => ref.invalidate(ketuaPendaftaranProvider),
      builder: (context, d) {
        final items = listOf(d, 'pendaftarans');
        final pendings = items.where((e) => e['status'] == 'pending').toList();
        final filtered = _filterByStudentName(pendings, _query, (item) {
          return Pendaftaran.fromJson(item).siswaNama;
        });
        return Column(
          children: [
            _NameSearchField(
              hint: 'Cari nama pendaftar...',
              onChanged: (value) => setState(() => _query = value),
            ),
            _ListCountLabel(
              count: filtered.length,
              label: 'pendaftar menunggu',
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                ref.invalidate(ketuaPendaftaranProvider);
                try {
                  await ref.read(ketuaPendaftaranProvider.future);
                } catch (_) {}
              },
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 24),
                        children: [
                          EmptyState(
                            title: pendings.isEmpty
                                ? 'Tidak ada pendaftar menunggu'
                                : 'Nama pendaftar tidak ditemukan',
                            subtitle: pendings.isEmpty
                                ? null
                                : 'Coba kata kunci nama yang lain.',
                            icon: pendings.isEmpty
                                ? Icons.how_to_reg_outlined
                                : Icons.search_off_rounded,
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final p = Pendaftaran.fromJson(filtered[i]);
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: const Color(0xFFE8EDF5),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 21,
                                      backgroundColor: AppTheme.blueBg,
                                      child: Text(
                                        _initials(p.siswaNama),
                                        style: GoogleFonts.plusJakartaSans(
                                          color: AppTheme.blue,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.siswaNama ?? 'Pendaftar Baru',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: AppTheme.ink,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            p.tanggalDaftar ??
                                                'Permintaan bergabung',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: AppTheme.sub,
                                              fontSize: 10.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.person_add_alt_1_outlined,
                                      color: AppTheme.blue,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                if (p.alasan?.isNotEmpty == true) ...[
                                  const SizedBox(height: 12),
                                  _RequestNote(text: p.alasan!),
                                ],
                                if (p.alasan?.isNotEmpty != true) ...[
                                  const SizedBox(height: 12),
                                  const _RequestNote(
                                    text: 'Tidak ada catatan pendaftaran.',
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _proses(context, ref, p, 'ditolak'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFFE11D48,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFFECDD3),
                                          ),
                                        ),
                                        child: const Text('Tolak'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _proses(
                                          context,
                                          ref,
                                          p,
                                          'diterima',
                                        ),
                                        child: const Text('Terima'),
                                      ),
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
    );
  }

  Future<void> _proses(
    BuildContext context,
    WidgetRef ref,
    Pendaftaran p,
    String status,
  ) async {
    try {
      await ref
          .read(apiClientProvider)
          .post('/ketua/pendaftaran/${p.id}', data: {'status': status});
      ref.invalidate(ketuaPendaftaranProvider);
      ref.invalidate(ketuaAnggotaProvider);
      ref.invalidate(ketuaDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'diterima' ? 'Diterima.' : 'Ditolak.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        await showErrorDialog(context, ref, e);
      }
    }
  }
}

class _PengajuanList extends ConsumerStatefulWidget {
  const _PengajuanList();

  @override
  ConsumerState<_PengajuanList> createState() => _PengajuanListState();
}

class _PengajuanListState extends ConsumerState<_PengajuanList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(ketuaPengajuanProvider);

    return ApiAsyncView(
      value: data,
      onRetry: () => ref.invalidate(ketuaPengajuanProvider),
      builder: (context, d) {
        final items = listOf(d, 'pengajuans');
        final pendings = items.where((e) => e['status'] == 'pending').toList();
        final filtered = _filterByStudentName(pendings, _query, (item) {
          return _studentName(item);
        });
        return Column(
          children: [
            _NameSearchField(
              hint: 'Cari nama siswa...',
              onChanged: (value) => setState(() => _query = value),
            ),
            _ListCountLabel(
              count: filtered.length,
              label: 'pengajuan menunggu',
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                ref.invalidate(ketuaPengajuanProvider);
                try {
                  await ref.read(ketuaPengajuanProvider.future);
                } catch (_) {}
              },
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 24),
                        children: [
                          EmptyState(
                            title: pendings.isEmpty
                                ? 'Tidak ada pengajuan keluar'
                                : 'Nama siswa tidak ditemukan',
                            subtitle: pendings.isEmpty
                                ? null
                                : 'Coba kata kunci nama yang lain.',
                            icon: pendings.isEmpty
                                ? Icons.logout_outlined
                                : Icons.search_off_rounded,
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final p = filtered[i];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: const Color(0xFFE8EDF5),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 21,
                                      backgroundColor: AppTheme.blueBg,
                                      child: Text(
                                        _initials(_studentName(p)),
                                        style: GoogleFonts.plusJakartaSans(
                                          color: AppTheme.blue,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _studentName(p) ?? '-',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: AppTheme.ink,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Permohonan keluar dari ekskul',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: AppTheme.sub,
                                              fontSize: 10.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusChip(
                                      _statusLabel(p['status']?.toString()),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _RequestNote(
                                  text:
                                      p['alasan']
                                              ?.toString()
                                              .trim()
                                              .isNotEmpty ==
                                          true
                                      ? p['alasan'].toString()
                                      : 'Tidak ada alasan yang dicantumkan.',
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _proses(context, ref, p, 'ditolak'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFFE11D48,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFFECDD3),
                                          ),
                                        ),
                                        child: const Text('Tolak'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _proses(
                                          context,
                                          ref,
                                          p,
                                          'diterima',
                                        ),
                                        child: const Text('Terima'),
                                      ),
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
    );
  }

  Future<void> _proses(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> p,
    String status,
  ) async {
    try {
      await ref
          .read(apiClientProvider)
          .post('/ketua/pengajuan-keluar/${p['id']}', data: {'status': status});
      ref.invalidate(ketuaPengajuanProvider);
      ref.invalidate(ketuaAnggotaProvider);
      ref.invalidate(ketuaDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'diterima' ? 'Diterima.' : 'Ditolak.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        await showErrorDialog(context, ref, e);
      }
    }
  }
}

class _NameSearchField extends StatefulWidget {
  const _NameSearchField({required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<_NameSearchField> createState() => _NameSearchFieldState();
}

class _NameSearchFieldState extends State<_NameSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: TextField(
      key: ValueKey(widget.hint),
      controller: _controller,
      onChanged: (value) {
        widget.onChanged(value);
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Hapus pencarian',
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    ),
  );
}

class _ListCountLabel extends StatelessWidget {
  const _ListCountLabel({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 2, 20, 3),
    child: Row(
      children: [
        Text(
          '$count $label',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.sub,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        const Tooltip(
          message: 'Tarik daftar ke bawah untuk memperbarui',
          child: Icon(
            Icons.swipe_down_alt_rounded,
            size: 16,
            color: AppTheme.sub,
          ),
        ),
      ],
    ),
  );
}

class _RequestNote extends StatelessWidget {
  const _RequestNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: AppTheme.sub,
        fontSize: 12,
        height: 1.4,
      ),
    ),
  );
}

String _initials(String? name) {
  final parts = (name ?? '').trim().split(RegExp(r'\s+'));
  if (parts.first.isEmpty) return 'S';
  final first = parts.first.substring(0, 1);
  if (parts.length == 1 || parts.last.isEmpty) return first.toUpperCase();
  return '$first${parts.last.substring(0, 1)}'.toUpperCase();
}

String _statusLabel(String? status) => switch (status) {
  'pending' => 'Menunggu',
  'diterima' => 'Disetujui',
  'ditolak' => 'Ditolak',
  _ => status ?? '-',
};

String? _studentName(Map<String, dynamic> item) {
  final siswa = item['siswa'];
  if (siswa is Map) {
    return siswa['nama']?.toString();
  }
  return item['nama']?.toString();
}

List<Map<String, dynamic>> _filterByStudentName(
  List<Map<String, dynamic>> items,
  String query,
  String? Function(Map<String, dynamic>) nameOf,
) {
  if (query.isEmpty) return items;
  final normalizedQuery = query.toLowerCase();
  return items
      .where((item) {
        return (nameOf(item) ?? '').toLowerCase().contains(normalizedQuery);
      })
      .toList(growable: false);
}
