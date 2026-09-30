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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifikasi',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(apiClientProvider)
                          .post('/siswa/notifikasi/read-all');
                      ref.invalidate(notifikasiProvider);
                      ref.invalidate(siswaDashboardProvider);
                      if (isKetua) ref.invalidate(ketuaDashboardProvider);
                    } catch (_) {}
                  },
                  child: const Text('Tandai semua'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ApiAsyncView(
              value: notif,
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
                          await ref.read(apiClientProvider).post(
                              '/siswa/notifikasi/${n.id}/read');
                          ref.invalidate(notifikasiProvider);
                          ref.invalidate(siswaDashboardProvider);
                        } catch (_) {}
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.notifications_none,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notifikasi.judul,
                            style: GoogleFonts.inter(
                              color: AppTheme.ink,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
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
                      style: GoogleFonts.inter(
                        color: AppTheme.sub,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notifikasi.createdLabel,
                      style: GoogleFonts.inter(
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