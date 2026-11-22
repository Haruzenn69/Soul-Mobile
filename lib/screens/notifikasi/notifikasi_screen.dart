import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../aktivitas/siswa_aktivitas_screen.dart';
import '../kegiatan/kegiatan_screen.dart';
import '../laporan/laporan_screen.dart';
import '../anggota/anggota_screen.dart';
import '../profil/profil_screen.dart';
import '../profil/pengajuan_kepengurusan_screen.dart';
import '../profil_ekskul/profil_ekskul_screen.dart';
import '../testimoni/testimoni_manage_screen.dart';
import '../faq/ketua_faq_screen.dart';
import '../katalog/katalog_screen.dart';
import '../../widgets/common.dart';

class NotifikasiScreen extends ConsumerWidget {
  const NotifikasiScreen({super.key, required this.isKetua});

  final bool isKetua;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notif = ref.watch(notifikasiProvider);
    final authUser = ref.watch(authControllerProvider).user;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Notifikasi',
            subtitle: 'Pembaruan penting seputar aktivitas ekskulmu.',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Hapus semua notifikasi',
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.dangerSurface(context),
                    foregroundColor: AppTheme.dangerText(context),
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Hapus semua notifikasi?'),
                        content: const Text(
                          'Semua riwayat notifikasi akan dihapus secara permanen.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: const Text('Hapus Semua'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;
                    try {
                      final client = ref.read(apiClientProvider);
                      if (isKetua) {
                        try {
                          await client.delete('/ketua/notifikasi');
                        } catch (_) {
                          try {
                            await client.delete('/ketua/notifikasi/all');
                          } catch (_) {
                            await client.delete('/ketua/notifikasi/delete-all');
                          }
                        }
                      } else {
                        try {
                          await client.delete('/siswa/notifikasi');
                        } catch (_) {
                          try {
                            await client.delete('/siswa/notifikasi/all');
                          } catch (_) {
                            await client.delete('/siswa/notifikasi/delete-all');
                          }
                        }
                      }
                      ref.invalidate(notifikasiProvider);
                      ref.invalidate(siswaDashboardProvider);
                      if (isKetua) ref.invalidate(ketuaDashboardProvider);
                    } catch (error) {
                      if (context.mounted) {
                        await showErrorDialog(context, ref, error);
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Tandai semua dibaca',
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.accentSurface(context),
                    foregroundColor: AppTheme.blue,
                  ),
                  onPressed: () async {
                    try {
                      final client = ref.read(apiClientProvider);
                      if (isKetua) {
                        try {
                          await client.post('/ketua/notifikasi/read-all');
                        } catch (_) {
                          try {
                            await client.put('/ketua/notifikasi/read-all');
                          } catch (_) {
                            await client.patch('/ketua/notifikasi/read-all');
                          }
                        }
                      } else {
                        try {
                          await client.post('/siswa/notifikasi/read-all');
                        } catch (_) {
                          try {
                            await client.put('/siswa/notifikasi/read-all');
                          } catch (_) {
                            try {
                              await client.patch('/siswa/notifikasi/read-all');
                            } catch (_) {
                              await client.post('/siswa/notifikasi/read');
                            }
                          }
                        }
                      }
                      ref.invalidate(notifikasiProvider);
                      ref.invalidate(siswaDashboardProvider);
                      if (isKetua) ref.invalidate(ketuaDashboardProvider);
                    } catch (error) {
                      if (context.mounted) {
                        await showErrorDialog(context, ref, error);
                      }
                    }
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: ApiAsyncView(
              value: notif,
              onRetry: () => ref.invalidate(notifikasiProvider),
              builder: (context, data) {
                final items = listOf(data, 'notifikasis');
                if (items.isEmpty) {
                  return const EmptyState(
                    title: 'Belum ada notifikasi',
                    icon: Icons.notifications_none_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final n = Notifikasi.fromJson(items[i]);
                    return _NotifCard(
                      notifikasi: n,
                      onDelete: () => _deleteNotification(context, ref, n),
                      onMarkRead: () =>
                          _markNotificationRead(context, ref, n, isKetua),
                      onTap: () async {
                        await _markNotificationRead(context, ref, n, isKetua);
                        if (context.mounted) {
                          await _openRelevantNotification(
                            context,
                            ref,
                            n,
                            isKetua,
                            authUser,
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markNotificationRead(
    BuildContext context,
    WidgetRef ref,
    Notifikasi notification,
    bool isKetua,
  ) async {
    if (notification.isRead) return;
    try {
      final client = ref.read(apiClientProvider);
      if (isKetua) {
        await client.post('/ketua/notifikasi/${notification.id}/read');
      } else {
        await client.post('/siswa/notifikasi/${notification.id}/read');
      }
      ref.invalidate(notifikasiProvider);
      ref.invalidate(siswaDashboardProvider);
      if (isKetua) ref.invalidate(ketuaDashboardProvider);
    } catch (error) {
      if (context.mounted) await showErrorDialog(context, ref, error);
    }
  }

  Future<void> _openRelevantNotification(
    BuildContext context,
    WidgetRef ref,
    Notifikasi notification,
    bool isKetua,
    AuthUser? user,
  ) async {
    final text = '${notification.judul} ${notification.pesan}'.toLowerCase();
    if (user == null) return;

    Widget? destination;
    if (text.contains('profil') ||
        text.contains('password') ||
        text.contains('akun')) {
      destination = ProfilScreen(user: user);
    } else if (text.contains('laporan')) {
      if (isKetua) destination = LaporanScreen(user: user);
    } else if (text.contains('kegiatan') ||
        text.contains('agenda') ||
        text.contains('presensi')) {
      destination = isKetua
          ? KegiatanScreen(user: user)
          : const SiswaAktivitasScreen();
    } else if (text.contains('pendaftaran') ||
        text.contains('anggota') ||
        text.contains('keluar dari ekskul') ||
        text.contains('pengajuan')) {
      if (isKetua) destination = AnggotaScreen(user: user);
    } else if (text.contains('kepengurusan') || text.contains('pengurus')) {
      destination = isKetua
          ? const PengajuanKepengurusanScreen()
          : ProfilScreen(user: user);
    } else if (text.contains('testimoni')) {
      if (isKetua) destination = const TestimoniManageScreen();
    } else if (text.contains('faq') || text.contains('pertanyaan')) {
      if (isKetua) destination = const KetuaFaqScreen();
    } else if (text.contains('ekskul') || text.contains('katalog')) {
      if (isKetua) {
        destination = ProfilEkskulScreen(user: user);
      } else {
        destination = KatalogScreen(user: user);
      }
    }

    if (destination != null && context.mounted) {
      await Navigator.of(context)
          .push<void>(MaterialPageRoute<void>(builder: (_) => destination!));
    }
  }

  Future<void> _deleteNotification(
    BuildContext context,
    WidgetRef ref,
    Notifikasi notification,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus notifikasi?'),
        content: const Text('Notifikasi ini akan dihapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final client = ref.read(apiClientProvider);
      if (isKetua) {
        try {
          await client.delete('/ketua/notifikasi/${notification.id}');
        } catch (_) {
          await client.post('/ketua/notifikasi/${notification.id}/delete');
        }
      } else {
        try {
          await client.delete('/siswa/notifikasi/${notification.id}');
        } catch (_) {
          await client.post('/siswa/notifikasi/${notification.id}/delete');
        }
      }
      ref.invalidate(notifikasiProvider);
      ref.invalidate(siswaDashboardProvider);
      if (isKetua) ref.invalidate(ketuaDashboardProvider);
    } catch (error) {
      if (context.mounted) await showErrorDialog(context, ref, error);
    }
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({
    required this.notifikasi,
    required this.onTap,
    required this.onDelete,
    required this.onMarkRead,
  });

  final Notifikasi notifikasi;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final color = notifikasi.isRead ? Colors.grey : AppTheme.blue;
    return Material(
      color: notifikasi.isRead
          ? AppTheme.surface(context)
          : AppTheme.blue.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: notifikasi.isRead
                  ? AppTheme.outline(context)
                  : AppTheme.blue.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.notifications_none, color: color, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notifikasi.judul,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.text(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!notifikasi.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notifikasi.pesan,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.mutedText(context),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notifikasi.createdLabel.isNotEmpty
                          ? notifikasi.createdLabel
                          : '-',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.mutedText(context)
                            .withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.bottomEnd,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          TextButton.icon(
                            onPressed: onDelete,
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.dangerText(context),
                              backgroundColor: AppTheme.dangerSurface(context),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 17,
                            ),
                            label: const Text('Hapus'),
                          ),
                          if (!notifikasi.isRead)
                            FilledButton.icon(
                              onPressed: onMarkRead,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                minimumSize: const Size(0, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              icon: const Icon(Icons.done_rounded, size: 17),
                              label: const Text('Tandai dibaca'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
