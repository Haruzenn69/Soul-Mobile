import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() {
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
  runApp(const ProviderScope(child: SoulApp()));
}

class SoulApp extends ConsumerWidget {
  const SoulApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'SOUL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final background = Theme.of(context).scaffoldBackgroundColor;
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
      home: const AuthGate(),
    );
  }
}
