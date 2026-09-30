import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_config.dart';
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
  });

  final AuthUser user;
  final bool isKetua;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Anggota',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
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
            const Expanded(
              child: TabBarView(
                children: [
                  _AnggotaList(),
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
  const _AnggotaList();

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
                onStatus: () => _changeStatus(context, ref, p),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _changeStatus(
      BuildContext context, WidgetRef ref, Pendaftaran p) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(p.ekskul?.namaEkskul ?? 'Ubah Status',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final status in [
              ('diterima', 'Aktifkan kembali'),
              ('peringatan', 'Beri peringatan'),
              ('nonaktif', 'Nonaktifkan'),
            ])
              ListTile(
                title: Text(status.$2,
                    style: GoogleFonts.inter(fontSize: 14)),
                onTap: () => Navigator.of(context).pop(status.$1),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    try {
      await ref
          .read(apiClientProvider)
          .post('/ketua/anggota/${p.id}/status', data: {'status': selected});
      ref.invalidate(ketuaAnggotaProvider);
      ref.invalidate(ketuaDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status anggota diperbarui.')),
        );
      }
    } catch (e) {
      await showErrorDialog(context, ref, e);
    }
  }
}

class _AnggotaTile extends StatelessWidget {
  const _AnggotaTile({required this.pendaftaran, required this.onStatus});

  final Pendaftaran pendaftaran;
  final VoidCallback onStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(AppConfig.brandBg),
            child: Text(
              (pendaftaran.siswaNama?.isNotEmpty ?? false)
                  ? pendaftaran.siswaNama![0]
                  : 'S',
              style: GoogleFonts.inter(
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
                  style: GoogleFonts.inter(
                    color: AppTheme.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pendaftaran.statusLabel} · ${pendaftaran.tanggalDaftar ?? ''}',
                  style: GoogleFonts.inter(
                    color: AppTheme.sub,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(pendaftaran.statusLabel),
        ],
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
        final pendings = items
            .where((e) => e['status'] == 'pending')
            .toList();
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
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.siswaNama ?? 'Pendaftar Baru',
                    style: GoogleFonts.inter(
                      color: AppTheme.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (p.alasan?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      '“${p.alasan}”',
                      style: GoogleFonts.inter(
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
      BuildContext context, WidgetRef ref, Pendaftaran p, String status) async {
    try {
      await ref
          .read(apiClientProvider)
          .post('/ketua/pendaftaran/${p.id}', data: {'status': status});
      ref.invalidate(ketuaPendaftaranProvider);
      ref.invalidate(ketuaAnggotaProvider);
      ref.invalidate(ketuaDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'diterima' ? 'Diterima.' : 'Ditolak.')),
        );
      }
    } catch (e) {
      await showErrorDialog(context, ref, e);
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
        final pendings = items
            .where((e) => e['status'] == 'pending')
            .toList();
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
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${p['nama'] ?? '-'}',
                          style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
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
                          onPressed: () =>
                              _proses(context, ref, p, 'ditolak'),
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
                          onPressed: () =>
                              _proses(context, ref, p, 'diterima'),
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

  Future<void> _proses(BuildContext context, WidgetRef ref,
      Map<String, dynamic> p, String status) async {
    try {
      await ref
          .read(apiClientProvider)
          .post('/ketua/pengajuan-keluar/${p['id']}',
              data: {'status': status});
      ref.invalidate(ketuaPengajuanProvider);
      ref.invalidate(ketuaAnggotaProvider);
      ref.invalidate(ketuaDashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'diterima' ? 'Diterima.' : 'Ditolak.')),
        );
      }
    } catch (e) {
      await showErrorDialog(context, ref, e);
    }
  }
}