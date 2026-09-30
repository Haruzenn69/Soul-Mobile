import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';

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
    return MaterialApp(
      title: 'SOUL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}