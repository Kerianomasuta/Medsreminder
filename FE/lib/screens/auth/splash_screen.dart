import 'package:flutter/material.dart';

import 'auth_backdrop.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => AuthBackdrop(
    child: Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: .82, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutBack,
        builder: (_, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 116,
              height: 116,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .9),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x335279C5),
                    blurRadius: 30,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Image.asset('assets/images/medsreminder_logo.png'),
            ),
            const SizedBox(height: 20),
            const Text(
              'MedsReminder',
              style: TextStyle(
                color: Color(0xFF123A70),
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    ),
  );
}
