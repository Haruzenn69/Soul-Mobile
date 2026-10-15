import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../models/models.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'onboarding_dialog.dart';
import 'profil/profil_edit_screen.dart';
import 'splash_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);

    if (state.status == AuthStatus.unauthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigator = Navigator.of(context);
        if (navigator.mounted) navigator.popUntil((route) => route.isFirst);
      });
    }

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
    if (_promptShown || !widget.user.needsProfileCompletion) return;
    _promptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showProfilePrompt();
    });
  }

  Future<void> _showProfilePrompt() async {
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
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProfilEditScreen(user: widget.user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MainShell(user: widget.user);
}
