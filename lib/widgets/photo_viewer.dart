import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PhotoViewDialog extends StatefulWidget {
  const PhotoViewDialog({
    super.key,
    required this.imageUrl,
    this.title,
    this.caption,
    this.onReplace,
  });

  final String imageUrl;
  final String? title;
  final String? caption;
  final VoidCallback? onReplace;

  static void show(
    BuildContext context, {
    required String imageUrl,
    String? title,
    String? caption,
    VoidCallback? onReplace,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) => PhotoViewDialog(
        imageUrl: imageUrl,
        title: title,
        caption: caption,
        onReplace: onReplace,
      ),
    );
  }

  @override
  State<PhotoViewDialog> createState() => _PhotoViewDialogState();
}

class _PhotoViewDialogState extends State<PhotoViewDialog> {
  double _scale = 1;

  void _onInteraction(double scale) {
    if ((scale - _scale).abs() > 0.2) {
      setState(() => _scale = scale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          color: const Color(0xFF0B1322),
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                onInteractionUpdate: (details) => _onInteraction(details.scale),
                child: Center(
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white70,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gagal memuat gambar',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 160,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            if (widget.title != null &&
                                widget.title!.isNotEmpty)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Text(
                                    widget.title!,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            if (_scale > 1.01) ...[
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${(_scale * 100).round()}%',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black38,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              tooltip: 'Tutup',
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (widget.caption != null &&
                        widget.caption!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.caption!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (widget.onReplace != null) ...[
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1D4ED8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: const StadiumBorder(),
                          elevation: 3,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onReplace?.call();
                        },
                        icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                        label: Text(
                          'Ganti Gambar',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
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