import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_config.dart';
import '../core/api_client.dart';
import '../core/providers.dart';
import '../theme/app_theme.dart';

class ActiveEkskulSelector extends StatelessWidget {
  const ActiveEkskulSelector({
    super.key,
    required this.ekskuls,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> ekskuls;
  final int? selectedId;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final available = ekskuls
        .where((item) => item['id'] is num)
        .toList(growable: false);
    if (available.length < 2) return const SizedBox.shrink();

    final selected =
        available.any((item) => (item['id'] as num).toInt() == selectedId)
        ? selectedId
        : (available.first['id'] as num).toInt();
    final selectedEkskul = available.firstWhere(
      (item) => (item['id'] as num).toInt() == selected,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outline(context)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.blue.withValues(
                alpha: AppTheme.isDark(context) ? 0.08 : 0.035,
              ),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.accentSurface(context),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: AppTheme.accent(context),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih ekskul',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.text(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Lihat aktivitas dari ekskul yang kamu ikuti',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.mutedText(context),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant(context),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.outline(context)),
                  ),
                  child: Text(
                    '${available.length} ekskul',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.mutedText(context),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: available.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final ekskul = available[index];
                  final id = (ekskul['id'] as num).toInt();
                  final isSelected = id == selected;
                  final name = ekskul['nama_ekskul']?.toString() ?? 'Ekskul';
                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label: '$name${isSelected ? ', dipilih' : ''}',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: ValueKey('active-ekskul-$id'),
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onChanged(id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          constraints: const BoxConstraints(maxWidth: 190),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.accentSurface(context)
                                : AppTheme.surfaceVariant(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.blue.withValues(alpha: 0.55)
                                  : AppTheme.outline(context),
                              width: isSelected ? 1.3 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.groups_2_outlined,
                                color: isSelected
                                    ? AppTheme.accent(context)
                                    : AppTheme.mutedText(context),
                                size: 16,
                              ),
                              const SizedBox(width: 7),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 125,
                                ),
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: isSelected
                                        ? AppTheme.accent(context)
                                        : AppTheme.text(context),
                                    fontSize: 10.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.accent(context),
                                  size: 15,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 13,
                  color: AppTheme.accent(context),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Menampilkan data ${selectedEkskul['nama_ekskul']?.toString() ?? 'ekskul'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.mutedText(context),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 21,
    this.backgroundColor = AppTheme.blueBg,
    this.foregroundColor = AppTheme.blue,
  });

  final String name;
  final String? photoUrl;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackground =
        backgroundColor == AppTheme.blueBg &&
            theme.brightness == Brightness.dark
        ? AppTheme.accentSurface(context)
        : backgroundColor;
    final effectiveForeground =
        foregroundColor == AppTheme.blue && theme.brightness == Brightness.dark
        ? const Color(0xFF93C5FD)
        : foregroundColor;
    final normalizedUrl = photoUrl?.trim();
    final hasPhoto = normalizedUrl != null && normalizedUrl.isNotEmpty;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();

    Widget fallback() => Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: GoogleFonts.plusJakartaSans(
          color: effectiveForeground,
          fontSize: radius * 0.66,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: effectiveBackground,
      child: !hasPhoto
          ? fallback()
          : ClipOval(
              child: Image.network(
                AppConfig.imageUrl(normalizedUrl),
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback(),
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : fallback(),
              ),
            ),
    );
  }
}

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
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            color: AppTheme.accent(context),
            strokeWidth: 2.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Memuat data...',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.mutedText(context),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentSurface(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    eyebrow!.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.accent(context),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.85,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
              ],
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.text(context),
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.mutedText(context),
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
                color: AppTheme.dangerSurface(context),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                color: AppTheme.dangerText(context),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.mutedText(context),
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
                  foregroundColor: AppTheme.accent(context),
                  side: BorderSide(color: AppTheme.accent(context)),
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
              color: AppTheme.text(context),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (action != null)
          Material(
            color: AppTheme.accentSurface(context),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: action,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionText ?? 'Lihat semua',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.accent(context),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppTheme.accent(context),
                      size: 14,
                    ),
                  ],
                ),
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
    final valueColor =
        color == AppTheme.blue &&
            Theme.of(context).brightness == Brightness.dark
        ? AppTheme.accent(context)
        : color;
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.isDark(context)
              ? AppTheme.outline(context)
              : AppTheme.outline(context).withValues(alpha: 0.82),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.blue.withValues(
              alpha: AppTheme.isDark(context) ? 0.035 : 0.045,
            ),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: compact ? 32 : 38,
              height: compact ? 32 : 38,
              decoration: BoxDecoration(
                color: valueColor.withValues(
                  alpha: AppTheme.isDark(context) ? 0.14 : 0.1,
                ),
                borderRadius: BorderRadius.circular(compact ? 11 : 13),
              ),
              child: Icon(icon, color: valueColor, size: compact ? 18 : 21),
            ),
            SizedBox(height: compact ? 8 : 12),
          ],
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: valueColor,
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
              color: AppTheme.mutedText(context),
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
    final color = _colorOf(label, context);
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

  Color _colorOf(String raw, BuildContext context) {
    final s = raw.toLowerCase().trim();
    if (s.contains('nonaktif') ||
        s.contains('tidak aktif') ||
        s.contains('ditolak') ||
        s.contains('alpha') ||
        s.contains('belum aktif')) {
      return AppTheme.dangerText(context);
    }
    if (s == 'izin') {
      return AppTheme.infoText(context);
    }
    if (s == 'sakit') {
      return AppTheme.warningText(context);
    }
    if (s == 'aktif' ||
        s.contains('aktif') ||
        s == 'hadir' ||
        s.contains('diterima')) {
      return AppTheme.successText(context);
    }
    if (s.contains('pending') || s.contains('menunggu')) {
      return AppTheme.warningText(context);
    }
    if (s.contains('peringatan')) {
      return AppTheme.warningText(context);
    }
    if (s.contains('terkirim') ||
        s.contains('diserahkan') ||
        s.contains('keluar')) {
      return AppTheme.mutedText(context);
    }
    return AppTheme.infoText(context);
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
                color: AppTheme.accentSurface(context),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: AppTheme.accent(context), size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.text(context),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.mutedText(context).withValues(alpha: 0.7),
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _chip(items[i], context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(StatusFilter item, BuildContext context) {
    final isSelected = selected == item.value;
    return GestureDetector(
      key: ValueKey('status-chip-${item.value}'),
      onTap: () => onSelected(item.value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent(context)
              : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? AppTheme.accent(context)
                : AppTheme.outline(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.label,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.white : AppTheme.text(context),
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
                      : AppTheme.accentSurface(context),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${item.count}',
                  style: GoogleFonts.plusJakartaSans(
                    color: isSelected ? Colors.white : AppTheme.accent(context),
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
            color: AppTheme.mutedText(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Tooltip(
          message: 'Tarik daftar ke bawah untuk memperbarui',
          child: Icon(
            Icons.swipe_down_alt_rounded,
            size: 16,
            color: AppTheme.mutedText(context),
          ),
        ),
      ],
    ),
  );
}

class ContentCard extends StatelessWidget {
  const ContentCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outline(context)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.blue, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.text(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.mutedText(context),
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
