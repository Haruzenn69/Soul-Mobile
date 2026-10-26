import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SizedBox(
          width: 140,
          height: 140,
          child: Image.asset(
            'assets/images/logo-light.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.shield_moon_rounded,
              color: AppTheme.blue,
              size: 80,
            ),
          ),
        ),
      ),
    );
  }
}
