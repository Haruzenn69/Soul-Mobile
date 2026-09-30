import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/api_client.dart';
import '../core/providers.dart';
import '../theme/app_theme.dart';

class ApiAsyncView<T> extends ConsumerWidget {
  const ApiAsyncView({
    super.key,
    required this.value,
    required this.builder,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return value.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.blue),
      ),
      error: (e, _) {
        if (e is ApiException && e.isUnauthorized) {
          Future.microtask(() => ref
              .read(authControllerProvider.notifier)
              .logout());
        }
        return BuildErrorCard(message: _messageOf(e));
      },
      data: (data) => builder(context, data),
    );
  }

  String _messageOf(Object e) {
    if (e is ApiException) return e.message;
    return 'Terjadi kesalahan. Coba lagi.';
  }
}

class BuildErrorCard extends StatelessWidget {
  const BuildErrorCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: AppTheme.sub, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppTheme.sub,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.actionText});

  final String title;
  final VoidCallback? action;
  final String? actionText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: AppTheme.ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: action,
            child: Text(actionText ?? 'Lihat semua',
                style: GoogleFonts.inter(
                    color: AppTheme.blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color = AppTheme.blue,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
          ],
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppTheme.sub,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = _colorOf(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _colorOf(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('aktif') || s.contains('diterima') || s == 'hadir') {
      return const Color(0xFF16803C);
    }
    if (s.contains('pending') || s.contains('menunggu')) {
      return const Color(0xFFB45309);
    }
    if (s.contains('peringatan')) {
      return const Color(0xFFC77700);
    }
    if (s.contains('ditolak') || s.contains('nonaktif') || s.contains('alpha')) {
      return const Color(0xFFE11D48);
    }
    if (s.contains('terkirim') || s.contains('diserahkan') || s.contains('keluar')) {
      return const Color(0xFF64748B);
    }
    return AppTheme.blue;
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black26, size: 44),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppTheme.sub,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppTheme.sub.withValues(alpha: 0.7),
                  fontSize: 12.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> showErrorDialog(
  BuildContext context,
  WidgetRef ref,
  Object error,
) async {
  if (error is ApiException && error.isUnauthorized) {
    await ref.read(authControllerProvider.notifier).logout();
    return;
  }
  if (!context.mounted) return;
  final message = error is ApiException
      ? error.message
      : 'Terjadi kesalahan. Coba lagi.';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}