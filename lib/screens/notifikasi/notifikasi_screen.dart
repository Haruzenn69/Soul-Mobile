import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_config.dart';
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
            action: IconButton(
              tooltip: 'Tandai semua dibaca',
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.blueBg,
                foregroundColor: AppTheme.blue,
              ),
              onPressed: () async {
                try {
                  await ref
                      .read(apiClientProvider)
                      .post('/siswa/notifikasi/read-all');
                  ref.invalidate(notifikasiProvider);
                  ref.invalidate(siswaDashboardProvider);
                  if (isKetua) ref.invalidate(ketuaDashboardProvider);
                } catch (error) {
                  if (context.mounted) {
                    await showErrorDialog(context, ref, error);
                  }
                }
              },
              icon: const Icon(Icons.done_all_rounded),
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
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.notifikasi, required this.onTap});

  final Notifikasi notifikasi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = notifikasi.isRead ? Colors.grey : AppTheme.blue;
    return Material(
      color: notifikasi.isRead
          ? Colors.white
          : const Color(AppConfig.brandBg).withValues(alpha: 0.45),
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
                  ? const Color(0xFFE8EDF5)
                  : const Color(0xFFBFDBFE),
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
                              color: AppTheme.ink,
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
                        color: AppTheme.sub,
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
                        color: AppTheme.sub.withValues(alpha: 0.7),
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
