import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers.dart';
import '../../data/providers.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class NotifikasiScreen extends ConsumerWidget {
  const NotifikasiScreen({super.key, required this.isKetua});

  final bool isKetua;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notif = ref.watch(notifikasiProvider);

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
                            try {
                              await client.delete('/ketua/notifikasi/delete-all');
                            } catch (_) {
                              await client.post('/ketua/notifikasi/delete-all');
                            }
                          }
                        }
                      } else {
                        try {
                          await client.delete('/siswa/notifikasi');
                        } catch (_) {
                          try {
                            await client.delete('/siswa/notifikasi/all');
                          } catch (_) {
                            try {
                              await client.delete('/siswa/notifikasi/delete-all');
                            } catch (e) {
                              if (context.mounted) {
                                await showErrorDialog(context, ref, e);
                              }
                              return;
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
                      onTap: () async {
                        if (n.isRead) return;
                        try {
                          await ref
                              .read(apiClientProvider)
                              .post('/siswa/notifikasi/${n.id}/read');
                          ref.invalidate(notifikasiProvider);
                          ref.invalidate(siswaDashboardProvider);
                          if (isKetua) ref.invalidate(ketuaDashboardProvider);
                        } catch (error) {
                          if (context.mounted) {
                            await showErrorDialog(context, ref, error);
                          }
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
  });

  final Notifikasi notifikasi;
  final VoidCallback onTap;
  final VoidCallback onDelete;

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
                        IconButton(
                          tooltip: 'Hapus notifikasi',
                          visualDensity: VisualDensity.compact,
                          onPressed: onDelete,
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: AppTheme.mutedText(context),
                            size: 19,
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
