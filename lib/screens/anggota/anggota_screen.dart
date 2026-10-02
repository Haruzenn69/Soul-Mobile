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
            ),
            const TabBar(
              labelColor: AppTheme.blue,
              unselectedLabelColor: AppTheme.sub,
              indicatorColor: AppTheme.blue,
              labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(text: 'Anggota'),
                Tab(text: 'Pendaftaran'),
                Tab(text: 'Pengajuan'),
              ],
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

class _AnggotaList extends ConsumerWidget {
  const _AnggotaList({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(ketuaAnggotaProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(ketuaAnggotaProvider),
      child: ApiAsyncView(
        value: data,
        builder: (context, d) {
          final items = listOf(d, 'anggotas');
          if (items.isEmpty) {
            return const EmptyState(
              title: 'Belum ada anggota',
              icon: Icons.groups_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = Pendaftaran.fromJson(items[i]);
              return _AnggotaTile(
                pendaftaran: p,
                isSelf: p.siswaRaw?['id'] == user.siswa?.id,
                onStatus: (status) => _changeStatus(context, ref, p, status),
              );
            },
          );
        },
      ),
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
                  StatusChip(pendaftaran.statusLabel),
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

class _PendaftaranList extends ConsumerWidget {
  const _PendaftaranList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(ketuaPendaftaranProvider);

    return ApiAsyncView(
      value: data,
      builder: (context, d) {
        final items = listOf(d, 'pendaftarans');
        final pendings = items.where((e) => e['status'] == 'pending').toList();
        if (pendings.isEmpty) {
          return const EmptyState(
            title: 'Tidak ada pendaftar menunggu',
            icon: Icons.how_to_reg_outlined,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pendings.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final p = Pendaftaran.fromJson(pendings[i]);
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.siswaNama ?? 'Pendaftar Baru',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (p.alasan?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      '“${p.alasan}”',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.sub,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _proses(context, ref, p, 'ditolak'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE11D48),
                            side: const BorderSide(color: Color(0xFFFECDD3)),
                          ),
                          child: const Text('Tolak'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _proses(context, ref, p, 'diterima'),
                          child: const Text('Terima'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
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

class _PengajuanList extends ConsumerWidget {
  const _PengajuanList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(ketuaPengajuanProvider);

    return ApiAsyncView(
      value: data,
      builder: (context, d) {
        final items = listOf(d, 'pengajuans');
        final pendings = items.where((e) => e['status'] == 'pending').toList();
        if (pendings.isEmpty) {
          return const EmptyState(
            title: 'Tidak ada pengajuan keluar',
            icon: Icons.logout_outlined,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pendings.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final p = pendings[i];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${p['nama'] ?? '-'}',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.ink,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      StatusChip('${p['status']}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${p['alasan'] ?? '-'}',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.sub,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _proses(context, ref, p, 'ditolak'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE11D48),
                            side: const BorderSide(color: Color(0xFFFECDD3)),
                          ),
                          child: const Text('Tolak'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _proses(context, ref, p, 'diterima'),
                          child: const Text('Terima'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
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
