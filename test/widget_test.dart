import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soul/core/providers.dart';
import 'package:soul/data/providers.dart';
import 'package:soul/main.dart';
import 'package:soul/models/models.dart';
import 'package:soul/screens/katalog/katalog_screen.dart';
import 'package:soul/screens/login_screen.dart';
import 'package:soul/screens/main_shell.dart';

class _TestAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

void main() {
  testWidgets('app boots and shows splash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SoulApp()));
    await tester.pump();
    expect(find.text('SOUL'), findsOneWidget);
  });

  testWidgets('login screen scrolls without overflow with keyboard open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_TestAuthController.new),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Log In Akun'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navbar builds a tab when selected after initial render', (
    tester,
  ) async {
    const user = AuthUser(
      id: 1,
      username: 'student',
      email: 'student@example.test',
      role: 'siswa',
      needsOnboarding: false,
      needsProfileCompletion: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_TestAuthController.new),
          siswaDashboardProvider.overrideWith((ref) async => {}),
          siswaPresensiProvider.overrideWith((ref) async => {}),
          katalogProvider.overrideWith((ref) async => {}),
        ],
        child: const MaterialApp(home: MainShell(user: user)),
      ),
    );
    await tester.pump();

    expect(find.byType(KatalogScreen), findsNothing);
    await tester.tap(find.text('Ekskul'));
    await tester.pumpAndSettle();

    expect(find.byType(KatalogScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
