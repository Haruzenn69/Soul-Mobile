import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/paginated_list.dart';

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
    const tabCount = 3;
    return DefaultTabController(
      length: tabCount,
      initialIndex: initialTab.clamp(0, tabCount - 1),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Anggota',
              subtitle: 'Kelola anggota, pendaftaran, dan pengajuan keluar siswa.',
              eyebrow: 'PENGELOLAAN EKSKUL',
              topPadding: 25,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Container(
                key: const ValueKey('anggota-pill-tabs'),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppTheme.outline(context)),
                ),
                child: TabBar(
                  key: ValueKey('anggota-tab-bar'),
                  dividerHeight: 0,
                  overlayColor: WidgetStatePropertyAll(Colors.transparent),
                  labelColor: AppTheme.blue,
                  unselectedLabelColor: AppTheme.mutedText(context),
                  indicatorColor: Colors.transparent,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppTheme.accentSurface(context),
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
                  tabs: const [
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
                  const _PendaftaranList(),
                  const _PengajuanList(),
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
  String _status = 'aktif';
  String _arsip = 'tanpa';
  bool _isAscending = true;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(ketuaAnggotaProvider);

    return ApiAsyncView(
      value: data,
      onRetry: () => ref.invalidate(ketuaAnggotaProvider),
      builder: (context, d) {
        final items = listOf(d, 'anggotas');
        final filteredByStatus = items.where((item) {
          final p = Pendaftaran.fromJson(item);
          final st = p.status.toLowerCase();
          if (_status == 'semua') return true;
          if (_status == 'aktif') return st == 'diterima' || st == 'aktif';
          if (_status == 'peringatan') return st == 'peringatan';
          if (_status == 'nonaktif') return st == 'nonaktif';
          if (_status == 'keluar') return st == 'keluar';
          return true;
        }).toList();

        final filteredByArsip = filteredByStatus.where((item) {
          final p = Pendaftaran.fromJson(item);
          final isArsip = p.status == 'keluar' || p.status == 'nonaktif' || (p.siswaRaw != null && p.siswaRaw!['is_arsip'] == true);
          if (_arsip == 'arsip') return isArsip;
          return !isArsip;
        }).toList();

        final filtered = _filterByStudentName(filteredByArsip, _query, (item) {
          final p = Pendaftaran.fromJson(item);
          return p.siswaNama;
        });

        final sorted = [...filtered];
        sorted.sort((a, b) {
          final nameA = Pendaftaran.fromJson(a).siswaNama ?? '';
          final nameB = Pendaftaran.fromJson(b).siswaNama ?? '';
          return _isAscending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
        });

        return Column(
          children: [
            NameSearchField(
              hint: 'Cari nama anggota...',
              onChanged: (value) => setState(() => _query = value),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          PopupMenuButton<String>(
                            onSelected: (val) => setState(() => _status = val),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'aktif', child: Text('Aktif')),
                              const PopupMenuItem(value: 'peringatan', child: Text('Peringatan')),
                              const PopupMenuItem(value: 'nonaktif', child: Text('Nonaktif')),
                              const PopupMenuItem(value: 'keluar', child: Text('Keluar')),
                              const PopupMenuItem(value: 'semua', child: Text('Semua Status')),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.surface(context),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppTheme.outline(context)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.filter_list_rounded, size: 16, color: AppTheme.blue),
                                  const SizedBox(width: 6),
                                  Text('Status',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down, size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            onSelected: (val) => setState(() => _arsip = val),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'tanpa', child: Text('Tanpa Arsip')),
                              const PopupMenuItem(value: 'arsip', child: Text('Arsip')),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.surface(context),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppTheme.outline(context)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.archive_outlined, size: 16, color: AppTheme.blue),
                                  const SizedBox(width: 6),
                                  Text('Arsip',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down, size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppTheme.blue,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _status[0].toUpperCase() + _status.substring(1),
                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppTheme.blue,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _arsip == 'tanpa' ? 'Tanpa Arsip' : 'Arsip',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
            Tooltip(
              message: _isAscending ? 'Urutkan A-Z (Klik untuk Z-A)' : 'Urutkan Z-A (Klik untuk A-Z)',
              child: InkWell(
                onTap: () => setState(() => _isAscending = !_isAscending),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.outline(context)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isAscending ? 'A-Z' : 'Z-A',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: 14,
                        color: AppTheme.blue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
                ],
              ),
            ),
            ListCountLabel(count: sorted.length, label: 'anggota'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(ketuaAnggotaProvider);
                  try {
                    await ref.read(ketuaAnggotaProvider.future);
                  } catch (_) {}
                },
                child: sorted.isEmpty
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
                    : PaginatedList<Map<String, dynamic>>(
                        items: sorted,
                        pageSize: 25,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, raw, i) {
                          final p = Pendaftaran.fromJson(raw);
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
            PersonAvatar(
              name: pendaftaran.siswaNama ?? 'Siswa',
              photoUrl: pendaftaran.siswaRaw?['foto']?.toString(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          pendaftaran.siswaNama ?? 'Anggota',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.text(context),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      StatusChip(pendaftaran.statusLabel),
                      if (isSelf) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentSurface(context),
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
                  const SizedBox(height: 3),
                  Text(
                    pendaftaran.tanggalDaftar ?? 'Tanggal tidak tersedia',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.mutedText(context),
                      fontSize: 10.5,
                    ),
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
  String _status = 'semua';
  bool _isAscending = true;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(ketuaPendaftaranProvider(_status));

    return ApiAsyncView(
      value: data,
      onRetry: () => ref.invalidate(ketuaPendaftaranProvider(_status)),
      builder: (context, d) {
        final items = listOf(d, 'pendaftarans');
        final filtered = _filterByStudentName(items, _query, (item) {
          return Pendaftaran.fromJson(item).siswaNama;
        });
        final sorted = [...filtered];
        sorted.sort((a, b) {
          final nameA = Pendaftaran.fromJson(a).siswaNama ?? '';
          final nameB = Pendaftaran.fromJson(b).siswaNama ?? '';
          return _isAscending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
        });
        return Column(
          children: [
            NameSearchField(
              hint: 'Cari nama pendaftar...',
              onChanged: (value) => setState(() => _query = value),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          PopupMenuButton<String>(
                            onSelected: (value) => setState(() => _status = value),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'semua', child: Text('Semua Status')),
                              const PopupMenuItem(value: 'pending', child: Text('Menunggu')),
                              const PopupMenuItem(value: 'diterima', child: Text('Disetujui')),
                              const PopupMenuItem(value: 'ditolak', child: Text('Ditolak')),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.surface(context),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppTheme.outline(context)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.filter_list_rounded, size: 16, color: AppTheme.blue),
                                  const SizedBox(width: 6),
                                  Text('Status',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down, size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppTheme.blue,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              switch (_status) {
                                'pending' => 'Menunggu',
                                'diterima' => 'Disetujui',
                                'ditolak' => 'Ditolak',
                                _ => 'Semua',
                              },
                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: _isAscending ? 'Urutkan A-Z (Klik untuk Z-A)' : 'Urutkan Z-A (Klik untuk A-Z)',
                    child: InkWell(
                      onTap: () => setState(() => _isAscending = !_isAscending),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surface(context),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.outline(context)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isAscending ? 'A-Z' : 'Z-A',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.blue,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                              size: 14,
                              color: AppTheme.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListCountLabel(
              count: sorted.length,
              label: _pendaftaranLabel(_status),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(ketuaPendaftaranProvider(_status));
                  try {
                    await ref.read(ketuaPendaftaranProvider(_status).future);
                  } catch (_) {}
                },
                child: sorted.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 24),
                        children: [
                          EmptyState(
                            title: items.isEmpty
                                ? _pendaftaranEmptyTitle(_status)
                                : 'Nama pendaftar tidak ditemukan',
                            subtitle: items.isEmpty
                                ? _pendaftaranEmptySubtitle(_status)
                                : 'Coba kata kunci nama yang lain.',
                            icon: items.isEmpty
                                ? (_status == 'semua'
                                      ? Icons.history_outlined
                                      : Icons.how_to_reg_outlined)
                                : Icons.search_off_rounded,
                          ),
                        ],
                      )
                    : PaginatedList<Map<String, dynamic>>(
                        items: sorted,
                        pageSize: 25,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, raw, i) {
                          final p = Pendaftaran.fromJson(raw);
                          final status = raw['status']?.toString() ?? 'pending';
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.surface(context),
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: AppTheme.outline(context),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    PersonAvatar(
                                      name: p.siswaNama ?? 'Pendaftar',
                                      photoUrl: p.siswaRaw?['foto']?.toString(),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  p.siswaNama ??
                                                      'Pendaftar Baru',
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                        color: AppTheme.text(
                                                          context,
                                                        ),
                                                        fontSize: 13.5,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              StatusChip(_statusLabel(status)),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            p.tanggalDaftar ??
                                                'Permintaan bergabung',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: AppTheme.mutedText(
                                                context,
                                              ),
                                              fontSize: 10.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusChip(_statusLabel(status)),
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
                                if (status == 'pending') ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _proses(
                                            context,
                                            ref,
                                            p,
                                            'ditolak',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                AppTheme.dangerText(context),
                                            side: BorderSide(
                                              color: AppTheme.dangerBorder(
                                                context,
                                              ),
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
      for (final s in const ['semua', 'pending', 'diterima', 'ditolak']) {
        ref.invalidate(ketuaPendaftaranProvider(s));
      }
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
  String _status = 'semua';
  bool _isAscending = true;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(ketuaPengajuanProvider(_status));

    return ApiAsyncView(
      value: data,
      onRetry: () => ref.invalidate(ketuaPengajuanProvider(_status)),
      builder: (context, d) {
        final items = listOf(d, 'pengajuans');
        final filtered = _filterByStudentName(items, _query, (item) {
          return _studentName(item);
        });
        final sorted = [...filtered];
        sorted.sort((a, b) {
          final nameA = _studentName(a) ?? '';
          final nameB = _studentName(b) ?? '';
          return _isAscending ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
        });
        return Column(
          children: [
            NameSearchField(
              hint: 'Cari nama siswa...',
              onChanged: (value) => setState(() => _query = value),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          PopupMenuButton<String>(
                            onSelected: (value) => setState(() => _status = value),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'semua', child: Text('Semua Status')),
                              const PopupMenuItem(value: 'pending', child: Text('Menunggu')),
                              const PopupMenuItem(value: 'diterima', child: Text('Disetujui')),
                              const PopupMenuItem(value: 'ditolak', child: Text('Ditolak')),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.surface(context),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: AppTheme.outline(context)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.filter_list_rounded, size: 16, color: AppTheme.blue),
                                  const SizedBox(width: 6),
                                  Text('Status',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down, size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppTheme.blue,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              switch (_status) {
                                'pending' => 'Menunggu',
                                'diterima' => 'Disetujui',
                                'ditolak' => 'Ditolak',
                                _ => 'Semua',
                              },
                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: _isAscending ? 'Urutkan A-Z (Klik untuk Z-A)' : 'Urutkan Z-A (Klik untuk A-Z)',
                    child: InkWell(
                      onTap: () => setState(() => _isAscending = !_isAscending),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surface(context),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.outline(context)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isAscending ? 'A-Z' : 'Z-A',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.blue,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                              size: 14,
                              color: AppTheme.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListCountLabel(
              count: sorted.length,
              label: _pengajuanLabel(_status),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(ketuaPengajuanProvider(_status));
                  try {
                    await ref.read(ketuaPengajuanProvider(_status).future);
                  } catch (_) {}
                },
                child: sorted.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 24),
                        children: [
                          EmptyState(
                            title: items.isEmpty
                                ? _pengajuanEmptyTitle(_status)
                                : 'Nama siswa tidak ditemukan',
                            subtitle: items.isEmpty
                                ? _pengajuanEmptySubtitle(_status)
                                : 'Coba kata kunci nama yang lain.',
                            icon: items.isEmpty
                                ? (_status == 'semua'
                                      ? Icons.history_outlined
                                      : Icons.logout_outlined)
                                : Icons.search_off_rounded,
                          ),
                        ],
                      )
                    : PaginatedList<Map<String, dynamic>>(
                        items: sorted,
                        pageSize: 25,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, p, i) {
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.surface(context),
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: AppTheme.outline(context),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    PersonAvatar(
                                      name: _studentName(p) ?? 'Siswa',
                                      photoUrl: _studentPhoto(p),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  _studentName(p) ?? '-',
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                        color: AppTheme.text(
                                                          context,
                                                        ),
                                                        fontSize: 13.5,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              StatusChip(
                                                _statusLabel(
                                                  p['status']?.toString(),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Permohonan keluar dari ekskul',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: AppTheme.mutedText(
                                                context,
                                              ),
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
                                if (p['status'] == 'pending') ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _proses(
                                            context,
                                            ref,
                                            p,
                                            'ditolak',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                AppTheme.dangerText(context),
                                            side: BorderSide(
                                              color: AppTheme.dangerBorder(
                                                context,
                                              ),
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
      for (final s in const ['semua', 'pending', 'diterima', 'ditolak']) {
        ref.invalidate(ketuaPengajuanProvider(s));
      }
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

class _RequestNote extends StatelessWidget {
  const _RequestNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: AppTheme.surfaceVariant(context),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: AppTheme.mutedText(context),
        fontSize: 12,
        height: 1.4,
      ),
    ),
  );
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

String? _studentPhoto(Map<String, dynamic> item) {
  final siswa = item['siswa'];
  if (siswa is Map && siswa['foto'] != null) {
    return siswa['foto'].toString();
  }
  return item['foto']?.toString();
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

int? _int(Object? value) {
  if (value == null) return null;
  return int.tryParse(value.toString());
}

String _pendaftaranLabel(String status) => switch (status) {
  'pending' => 'pendaftar menunggu',
  'diterima' => 'pendaftar disetujui',
  'ditolak' => 'pendaftar ditolak',
  _ => 'pendaftaran',
};

String _pendaftaranEmptyTitle(String status) => switch (status) {
  'pending' => 'Tidak ada pendaftar menunggu',
  'diterima' => 'Belum ada pendaftar disetujui',
  'ditolak' => 'Belum ada pendaftar ditolak',
  _ => 'Belum ada riwayat pendaftaran',
};

String _pendaftaranEmptySubtitle(String status) => switch (status) {
  'pending' =>
    'Permintaan bergabung yang belum kamu proses akan muncul di sini.',
  'diterima' => 'Pendaftar yang telah kamu terima tercatat di sini.',
  'ditolak' => 'Pendaftar yang kamu tolak tercatat di sini.',
  _ => 'Semua permintaan dan riwayat pendaftaran tercatat di sini.',
};

String _pengajuanLabel(String status) => switch (status) {
  'pending' => 'pengajuan menunggu',
  'diterima' => 'pengajuan disetujui',
  'ditolak' => 'pengajuan ditolak',
  _ => 'pengajuan keluar',
};

String _pengajuanEmptyTitle(String status) => switch (status) {
  'pending' => 'Tidak ada pengajuan keluar',
  'diterima' => 'Belum ada pengajuan disetujui',
  'ditolak' => 'Belum ada pengajuan ditolak',
  _ => 'Belum ada riwayat pengajuan',
};

String _pengajuanEmptySubtitle(String status) => switch (status) {
  'pending' => 'Permintaan keluar yang belum kamu proses akan muncul di sini.',
  'diterima' => 'Pengajuan keluar yang disetujui tercatat di sini.',
  'ditolak' => 'Pengajuan keluar yang ditolak tercatat di sini.',
  _ => 'Semua riwayat pengajuan keluar tercatat di sini.',
};
