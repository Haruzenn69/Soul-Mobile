import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_config.dart';

class AppTheme {
  // Shared palette from Laravel's Tailwind theme tokens.
  static const blue = Color(AppConfig.brandBlue);
  static const blueDark = Color(AppConfig.brandBlueDark);
  static const blueBg = Color(AppConfig.brandBg);
  static const sky = Color(0xFF38BDF8);
  static const yellow = Color(0xFFFACC15);
  static const ink = Color(0xFF0F172A);
  static const sub = Color(0xFF64748B);
  static const canvas = Color(0xFFF8FAFC);
  static const line = Color(0xFFE3EAF4);
  static const lightSurfaceVariant = Color(0xFFF1F5FB);
  static const lightAccentSurface = Color(0xFFEDF4FF);
  static const darkCanvas = Color(0xFF171717);
  static const darkSurface = Color(0xFF24262B);
  static const darkSurfaceVariant = Color(0xFF2C3038);
  static const darkLine = Color(0xFF3B414A);
  static const darkInk = Color(0xFFF5F5F5);
  static const darkSub = Color(0xFFA6AFBD);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color warningSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF332A1B) : const Color(0xFFFFFBEB);
  static Color warningBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFF5B4828) : const Color(0xFFFDE68A);
  static Color warningText(BuildContext context) =>
      isDark(context) ? const Color(0xFFFCD275) : const Color(0xFF92400E);

  static Color dangerSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF351F25) : const Color(0xFFFFF1F2);
  static Color dangerBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFF63313D) : const Color(0xFFFECDD3);
  static Color dangerText(BuildContext context) =>
      isDark(context) ? const Color(0xFFFF9AAA) : const Color(0xFFBE123C);

  static Color successSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF1D3327) : const Color(0xFFECFDF5);
  static Color successBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFF315740) : const Color(0xFFA7F3D0);
  static Color successText(BuildContext context) =>
      isDark(context) ? const Color(0xFF8ADDAB) : const Color(0xFF15803D);

  static Color infoSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF1D2F40) : const Color(0xFFE0F2FE);
  static Color infoBorder(BuildContext context) =>
      isDark(context) ? const Color(0xFF31516D) : const Color(0xFFBFDBFE);
  static Color infoText(BuildContext context) =>
      isDark(context) ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);

  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color surfaceVariant(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;
  static Color text(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color accent(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color mutedText(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;
  static Color outline(BuildContext context) =>
      Theme.of(context).colorScheme.outline;
  static Color accentSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF202B3A)
      : lightAccentSurface;
  static LinearGradient brandHeroGradient(BuildContext context) {
    final colors = isDark(context)
        ? const [Color(0xFF17283D), Color(0xFF1E3A5F), Color(0xFF1D4ED8)]
        : const [sky, Color(0xFF60A5FA), blue];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  static Color brandHeroShadow(BuildContext context) =>
      blue.withValues(alpha: isDark(context) ? 0.1 : 0.18);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: blue,
          primary: blue,
          surface: Colors.white,
        ).copyWith(
          primary: blue,
          secondary: sky,
          surface: Colors.white,
          surfaceContainerHighest: lightSurfaceVariant,
          outline: line,
        );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      textTheme: base.textTheme.apply(
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
        bodyColor: ink,
        displayColor: ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xF7FFFFFF),
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        toolbarHeight: 60,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: ink,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(color: sub),
        shape: const Border(bottom: BorderSide(color: line)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: line),
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF334155),
          side: const BorderSide(color: line),
          minimumSize: const Size(48, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: blue,
          minimumSize: const Size(44, 44),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: line),
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(color: sub, fontSize: 13),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F8FC),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF94A3B8),
          fontSize: 13,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF475569),
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: blue, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE11D48)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE11D48), width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: lightAccentSurface,
        height: 78,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: blue,
        unselectedLabelColor: sub,
        dividerColor: Colors.transparent,
        indicatorColor: blue,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: blue,
        linearTrackColor: blueBg,
        refreshBackgroundColor: Colors.white,
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: blue,
          brightness: Brightness.dark,
          primary: const Color(0xFF60A5FA),
          surface: darkSurface,
        ).copyWith(
          primary: const Color(0xFF60A5FA),
          secondary: const Color(0xFF7DD3FC),
          surface: darkSurface,
          surfaceContainerHighest: darkSurfaceVariant,
          outline: darkLine,
        );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: darkCanvas,
      textTheme: base.textTheme.apply(
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
        bodyColor: darkInk,
        displayColor: darkInk,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkCanvas,
        foregroundColor: darkInk,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        toolbarHeight: 60,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: darkInk,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(color: darkSub),
        shape: const Border(bottom: BorderSide(color: darkLine)),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: darkLine),
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkInk,
          side: const BorderSide(color: darkLine),
          minimumSize: const Size(48, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF93C5FD),
          minimumSize: const Size(44, 44),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: darkLine),
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: darkInk,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: darkSub,
          fontSize: 13,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        hintStyle: GoogleFonts.plusJakartaSans(color: darkSub, fontSize: 13),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: const Color(0xFFCBD5E1),
          fontSize: 13,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFB7185)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFB7185), width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFF26374D),
        height: 78,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          ),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFF93C5FD),
        unselectedLabelColor: darkSub,
        dividerColor: Colors.transparent,
        indicatorColor: Color(0xFF60A5FA),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF60A5FA),
        linearTrackColor: Color(0xFF1E3A5F),
      ),
      dividerTheme: const DividerThemeData(color: darkLine, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkSurface,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: darkInk),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
