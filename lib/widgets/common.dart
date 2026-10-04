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
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return value.when(
      skipLoadingOnRefresh: true,
      loading: () => const _LoadingState(),
      error: (e, _) {
        if (e is ApiException && e.isUnauthorized) {
          Future.microtask(
            () => ref.read(authControllerProvider.notifier).logout(),
          );
        }
        return BuildErrorCard(message: _messageOf(e), onRetry: onRetry);
      },
      data: (data) => builder(context, data),
    );
  }

  String _messageOf(Object e) {
    if (e is ApiException) return e.message;
    return 'Terjadi kesalahan. Coba lagi.';
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            color: AppTheme.blue,
            strokeWidth: 2.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Memuat data...',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.sub,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.action,
    this.topPadding = 12,
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final Widget? action;
  final double topPadding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(16, topPadding, 16, 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.blue,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
              ],
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.sub,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 8), action!],
      ],
    ),
  );
}

class BuildErrorCard extends StatelessWidget {
  const BuildErrorCard({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                color: Color(0xFFE11D48),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.sub,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba Lagi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.blue,
                  side: const BorderSide(color: AppTheme.blue),
                ),
              ),
            ],
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: action,
            child: Text(
              actionText ?? 'Lihat semua',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.blue,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
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
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 22),
            SizedBox(height: compact ? 1 : 10),
          ],
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontSize: compact ? 18 : 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 0 : 2),
          Text(
            label,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
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
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _colorOf(String raw) {
    final s = raw.toLowerCase().trim();
    if (s.contains('nonaktif') ||
        s.contains('tidak aktif') ||
        s.contains('ditolak') ||
        s.contains('alpha') ||
        s.contains('belum aktif')) {
      return const Color(0xFFE11D48);
    }
    if (s == 'izin') {
      return AppTheme.blue;
    }
    if (s == 'sakit') {
      return const Color(0xFFC77700);
    }
    if (s == 'aktif' ||
        s.contains('aktif') ||
        s == 'hadir' ||
        s.contains('diterima')) {
      return const Color(0xFF16803C);
    }
    if (s.contains('pending') || s.contains('menunggu')) {
      return const Color(0xFFB45309);
    }
    if (s.contains('peringatan')) {
      return const Color(0xFFC77700);
    }
    if (s.contains('terkirim') ||
        s.contains('diserahkan') ||
        s.contains('keluar')) {
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppTheme.blueBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: AppTheme.blue, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
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
                style: GoogleFonts.plusJakartaSans(
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
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class StatusFilter {
  const StatusFilter(this.value, this.label, this.count);

  final String value;
  final String label;
  final int? count;
}

class StatusFilterChips extends StatelessWidget {
  const StatusFilterChips({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final List<StatusFilter> items;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _chip(items[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(StatusFilter item) {
    final isSelected = selected == item.value;
    return GestureDetector(
      key: ValueKey('status-chip-${item.value}'),
      onTap: () => onSelected(item.value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.blue : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppTheme.blue : const Color(0xFFE0E7EF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.label,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.white : AppTheme.ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (item.count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.22)
                      : AppTheme.blueBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${item.count}',
                  style: GoogleFonts.plusJakartaSans(
                    color: isSelected ? Colors.white : AppTheme.blue,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NameSearchField extends StatefulWidget {
  const NameSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<NameSearchField> createState() => _NameSearchFieldState();
}

class _NameSearchFieldState extends State<NameSearchField> {
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

class ListCountLabel extends StatelessWidget {
  const ListCountLabel({super.key, required this.count, required this.label});

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
