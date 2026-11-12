import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../models/models.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'onboarding_dialog.dart';
import 'profil/profil_edit_screen.dart';
import 'splash_screen.dart';

/// Widget penentu gerbang autentikasi (AuthGate).
/// Memantau status login pengguna (`AuthStatus`) dan mengarahkan tampilan ke SplashScreen,
/// LoginScreen, MainShell, dialog Onboarding, atau dialog kelengkapan profil secara dinamis.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau status autentikasi dari authControllerProvider
    final state = ref.watch(authControllerProvider);

    // Jika status pengguna unauthenticated, reset stack navigasi ke rute awal
    if (state.status == AuthStatus.unauthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final navigator = Navigator.of(context);
        if (!navigator.mounted) return;
        try {
          navigator.popUntil((route) => route.isFirst);
        } catch (_) {}
      });
    }

    // Switch berdasarkan status autentikasi saat ini
    return switch (state.status) {
      AuthStatus.unknown => const SplashScreen(),
      AuthStatus.unauthenticated => const LoginScreen(),
      AuthStatus.authenticated =>
        state.user!.needsOnboarding
            ? _OnboardingPrompt(user: state.user!)
            : _ProfileCompletionPrompt(user: state.user!),
    };
  }
}

/// Widget perantara untuk menampilkan dialog onboarding bagi pengguna baru/belum onboarding.
class _OnboardingPrompt extends StatefulWidget {
  const _OnboardingPrompt({required this.user});

  final AuthUser user;

  @override
  State<_OnboardingPrompt> createState() => _OnboardingPromptState();
}

class _OnboardingPromptState extends State<_OnboardingPrompt> {
  bool _promptShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_promptShown) return;
    _promptShown = true;
    // Menampilkan dialog onboarding setelah frame selesai dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showOnboardingPrompt();
    });
  }

  Future<void> _showOnboardingPrompt() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OnboardingDialog(user: widget.user),
    );
  }

  @override
  Widget build(BuildContext context) => MainShell(user: widget.user);
}

/// Widget perantara untuk mempromosikan dialog kelengkapan data profil diri pengguna.
class _ProfileCompletionPrompt extends ConsumerStatefulWidget {
  const _ProfileCompletionPrompt({required this.user});

  final AuthUser user;

  @override
  ConsumerState<_ProfileCompletionPrompt> createState() =>
      _ProfileCompletionPromptState();
}

class _ProfileCompletionPromptState
    extends ConsumerState<_ProfileCompletionPrompt> {
  bool _promptShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_promptShown) return;
    if (!widget.user.needsProfileCompletion) return;
    _promptShown = true;
    // Menampilkan dialog ajakan melengkapi profil jika data belum lengkap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showProfilePrompt();
    });
  }

  Future<void> _showProfilePrompt() async {
    if (!widget.user.needsProfileCompletion) return;
    final completeProfile = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.person_pin_circle_outlined),
        title: const Text('Lengkapi data diri'),
        content: const Text(
          'Data diri kamu belum lengkap. Lengkapi profil agar informasi akun '
          'tetap terbaru. Kamu juga bisa melewatinya dan mengisi nanti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Nanti saja'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Lengkapi sekarang'),
          ),
        ],
      ),
    );

    if (!mounted || completeProfile != true) return;
    // Navigasi ke halaman edit profil jika pengguna memilih melengkapi sekarang
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProfilEditScreen(user: widget.user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MainShell(user: widget.user);
}
