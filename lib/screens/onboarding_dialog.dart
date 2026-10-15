import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/providers.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class OnboardingDialog extends ConsumerStatefulWidget {
  const OnboardingDialog({super.key, required this.user});

  final AuthUser user;

  @override
  ConsumerState<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends ConsumerState<OnboardingDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _saving = false;
  bool _hidePassword = true;
  bool _hideConfirmation = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(apiClientProvider)
          .post(
            '/auth/onboarding/setup',
            data: {
              'username': _usernameController.text.trim(),
              'password': _passwordController.text,
              'password_confirmation': _confirmationController.text,
            },
          );
      await ref.read(authControllerProvider.notifier).refreshSession();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (error is ApiException && error.isForbidden) {
        await ref.read(authControllerProvider.notifier).refreshSession();
        final authState = ref.read(authControllerProvider);
        if (mounted &&
            authState.status == AuthStatus.authenticated &&
            authState.user?.needsOnboarding == false) {
          Navigator.of(context).pop();
          return;
        }
      }
      if (mounted) await showErrorDialog(context, ref, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _returnToLogin() async {
    setState(() => _saving = true);
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user.siswa?.nama.trim();
    return PopScope(
      canPop: false,
      child: AlertDialog(
        icon: const Icon(Icons.lock_person_outlined),
        title: const Text('Amankan akunmu'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Login pertama kali${name?.isNotEmpty == true ? ', selamat datang $name' : ''}. '
                    'Buat username dan password baru untuk mengamankan akun.',
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _usernameController,
                    enabled: !_saving,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newUsername],
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      helperText:
                          'Minimal 3 karakter; gunakan huruf, angka, - atau _.',
                    ),
                    validator: (value) {
                      final username = value?.trim() ?? '';
                      if (username.length < 3) {
                        return 'Username minimal 3 karakter.';
                      }
                      if (username.length > 50 ||
                          !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(username)) {
                        return 'Gunakan hanya huruf, angka, - atau _.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_saving,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'Password baru',
                      helperText: 'Kosongkan jika ingin menggantinya nanti.',
                      suffixIcon: IconButton(
                        tooltip: _hidePassword
                            ? 'Tampilkan password'
                            : 'Sembunyikan password',
                        onPressed: _saving
                            ? null
                            : () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final password = value ?? '';
                      if (password.isNotEmpty && password.length < 8) {
                        return 'Password minimal 8 karakter.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmationController,
                    enabled: !_saving,
                    obscureText: _hideConfirmation,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi password baru',
                      suffixIcon: IconButton(
                        tooltip: _hideConfirmation
                            ? 'Tampilkan password'
                            : 'Sembunyikan password',
                        onPressed: _saving
                            ? null
                            : () => setState(
                                () => _hideConfirmation = !_hideConfirmation,
                              ),
                        icon: Icon(
                          _hideConfirmation
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final password = _passwordController.text;
                      final confirmation = value ?? '';
                      if (password.isEmpty && confirmation.isEmpty) return null;
                      if (confirmation != password) {
                        return 'Konfirmasi password tidak sama.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _returnToLogin,
            child: const Text('Kembali ke login'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan dan lanjutkan'),
          ),
        ],
      ),
    );
  }
}
