import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'core/notification_service.dart';

/// Titik masuk (Entry Point) utama aplikasi Soul.
/// Menginisialisasi sistem binding Flutter, layanan notifikasi lokal,
/// penanganan custom error widget, dan membungkus aplikasi dengan ProviderScope.
void main() async {
  // Memastikan binding Flutter terinisialisasi sebelum async call
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Inisialisasi notification service
    await NotificationService().init();
  } catch (_) {}
  
  // Custom Error Widget untuk menampilkan detail error di layar secara elegan
  ErrorWidget.builder = (details) => Material(
    color: const Color(0xFF7F1D1D),
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SelectableText(
          '${details.exception}\n\n${details.stack ?? ""}\n\n'
          '${details.informationCollector?.call().join('\n') ?? ""}',
          style: const TextStyle(color: Colors.yellow, fontSize: 13),
        ),
      ),
    ),
  );
  
  // Menjalankan root widget aplikasi dengan Riverpod ProviderScope
  runApp(const ProviderScope(child: SoulApp()));
}

/// Root Widget aplikasi Soul.
/// Mengatur konfigurasi MaterialApp, tema terang/gelap (ThemeMode),
/// pengaturan System UI Overlay (status bar & navigation bar), serta router utama.
class SoulApp extends ConsumerWidget {
  const SoulApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau state perubahan mode tema (Light/Dark) dari themeModeProvider
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Soul',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final background = Theme.of(context).scaffoldBackgroundColor;
        // Mengatur gaya warna System UI Overlay sesuai mode terang/gelap
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: background,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: background,
            systemNavigationBarIconBrightness: dark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarDividerColor: Theme.of(context)
                .colorScheme
                .outline,
            systemNavigationBarContrastEnforced: false,
            systemStatusBarContrastEnforced: false,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      // Menetapkan AuthGate sebagai rute awal penentu autentikasi pengguna
      home: const AuthGate(),
    );
  }
}
