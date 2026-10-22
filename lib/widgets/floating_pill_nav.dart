import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Item model for [FloatingPillNav]
class FloatingPillNavItem {
  const FloatingPillNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Floating pill bottom navigation bar with a raised center button.
///
/// The center button sits in a notch/cavity cut into the pill bar.
class FloatingPillNav extends StatelessWidget {
  const FloatingPillNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.centerIndex = 2,
    this.centerIcon = Icons.calendar_month_outlined,
    this.centerBackgroundColor = AppTheme.blue,
    this.barHeight = 72,
    this.centerButtonSize = 64,
    this.horizontalMargin = 16,
    this.verticalMargin = 16,
    this.notchDepth = 43,
  });

  final List<FloatingPillNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int centerIndex;
  final IconData centerIcon;
  final Color centerBackgroundColor;
  final double barHeight;
  final double centerButtonSize;
  final double horizontalMargin;
  final double verticalMargin;

  /// How deep the notch cuts into the bar (pixels below the bar's top edge).
  final double notchDepth;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final safeIndex = currentIndex.clamp(0, items.length - 1);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final notchRadius = centerButtonSize / 2 + 8;
    final totalHeight =
        (barHeight / 2) + centerButtonSize / 2 + verticalMargin + bottomPadding;

    // Frosted glass colors
    final barColor = isDark
        ? const Color(0xB01E1E2E) // dark: deep translucent
        : const Color(0xB0FFFFFF); // light: white translucent
    final borderColor = isDark
        ? const Color(0x30FFFFFF)
        : const Color(0x20000000);
    final unselectedColor = isDark
        ? const Color(0xFFA6AFBD)
        : const Color(0xFF475569);

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // --- Frosted glass bar ---
          Positioned(
            left: horizontalMargin,
            right: horizontalMargin,
            bottom: verticalMargin + bottomPadding,
            child: CustomPaint(
              foregroundPainter: _NotchedPillBorderPainter(
                notchRadius: notchRadius,
                notchDepth: notchDepth,
                borderColor: borderColor,
              ),
              child: ClipPath(
                clipper: _NotchedPillClipper(
                  notchRadius: notchRadius,
                  notchDepth: notchDepth,
                  barHeight: barHeight,
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: barColor,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildItem(context, 0, safeIndex,
                              unselectedColor),
                        ),
                        Expanded(
                          child: _buildItem(context, 1, safeIndex,
                              unselectedColor),
                        ),
                        const Expanded(child: SizedBox.shrink()),
                        Expanded(
                          child: _buildItem(context, 3, safeIndex,
                              unselectedColor),
                        ),
                        Expanded(
                          child: _buildItem(context, 4, safeIndex,
                              unselectedColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // --- Center button (positioned within bounds for hit test) ---
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: centerButtonSize,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (centerIndex >= 0 && centerIndex < items.length) {
                    onTap(centerIndex);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: centerButtonSize,
                  height: centerButtonSize,
                  decoration: BoxDecoration(
                    color: centerBackgroundColor,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x332563EB),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(centerIcon, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    int index,
    int safeIndex,
    Color unselectedColor,
  ) {
    if (index == centerIndex) return const SizedBox.shrink();
    if (index < 0 || index >= items.length) return const SizedBox.shrink();

    final item = items[index];
    final isSelected = index == safeIndex;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(999),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? item.selectedIcon : item.icon,
            size: 22,
            color: isSelected ? AppTheme.blue : unselectedColor,
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppTheme.blue : unselectedColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws the outline border following the notched pill shape, including the notch curve.
class _NotchedPillBorderPainter extends CustomPainter {
  _NotchedPillBorderPainter({
    required this.notchRadius,
    required this.notchDepth,
    required this.borderColor,
  }) : strokeWidth = 0.8;

  final double notchRadius;
  final double notchDepth;
  final Color borderColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final r = size.height / 2;
    final cx = size.width / 2;
    final halfWidth = notchRadius;

    final path = Path();

    path.moveTo(r, 0);
    path.lineTo(cx - halfWidth - 6, 0);

    path.cubicTo(
      cx - halfWidth + 4, 0,
      cx - halfWidth + 2, notchDepth,
      cx, notchDepth,
    );

    path.cubicTo(
      cx + halfWidth - 2, notchDepth,
      cx + halfWidth - 4, 0,
      cx + halfWidth + 6, 0,
    );

    path.lineTo(size.width - r, 0);

    path.arcToPoint(
      Offset(size.width, r),
      radius: Radius.circular(r),
    );

    path.lineTo(size.width, size.height - r);
    path.arcToPoint(
      Offset(size.width - r, size.height),
      radius: Radius.circular(r),
    );

    path.lineTo(r, size.height);
    path.arcToPoint(
      Offset(0, size.height - r),
      radius: Radius.circular(r),
    );

    path.lineTo(0, r);
    path.arcToPoint(
      Offset(r, 0),
      radius: Radius.circular(r),
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NotchedPillBorderPainter old) {
    return old.notchRadius != notchRadius ||
        old.notchDepth != notchDepth ||
        old.borderColor != borderColor ||
        old.strokeWidth != strokeWidth;
  }
}

/// Clips the bar into a pill shape with a notch cut from the top center.
class _NotchedPillClipper extends CustomClipper<Path> {
  _NotchedPillClipper({
    required this.notchRadius,
    required this.notchDepth,
    required this.barHeight,
  });

  final double notchRadius;
  final double notchDepth;
  final double barHeight;

  @override
  Path getClip(Size size) {
    final r = size.height / 2;
    final cx = size.width / 2;
    final halfWidth = notchRadius;

    final path = Path();

    path.moveTo(r, 0);

    // Top edge → notch entry
    path.lineTo(cx - halfWidth - 6, 0);

    // Smooth curve into the deep notch
    path.cubicTo(
      cx - halfWidth + 4, 0,
      cx - halfWidth + 2, notchDepth,
      cx, notchDepth,
    );

    // Curve out of the notch
    path.cubicTo(
      cx + halfWidth - 2, notchDepth,
      cx + halfWidth - 4, 0,
      cx + halfWidth + 6, 0,
    );

    // Top edge → top-right corner
    path.lineTo(size.width - r, 0);

    path.arcToPoint(
      Offset(size.width, r),
      radius: Radius.circular(r),
    );

    path.lineTo(size.width, size.height - r);
    path.arcToPoint(
      Offset(size.width - r, size.height),
      radius: Radius.circular(r),
    );

    path.lineTo(r, size.height);
    path.arcToPoint(
      Offset(0, size.height - r),
      radius: Radius.circular(r),
    );

    path.lineTo(0, r);
    path.arcToPoint(
      Offset(r, 0),
      radius: Radius.circular(r),
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _NotchedPillClipper oldClipper) {
    return oldClipper.notchRadius != notchRadius ||
        oldClipper.notchDepth != notchDepth ||
        oldClipper.barHeight != barHeight;
  }
}
