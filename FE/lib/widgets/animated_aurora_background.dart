import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedAuroraBackground extends StatelessWidget {
  const AnimatedAuroraBackground({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) {
      final drift = Curves.easeInOut.transform(animation.value);
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(
                const Color(0xFFE7ECFF),
                const Color(0xFFFFE8F5),
                drift,
              )!,
              Color.lerp(
                const Color(0xFFF9F1FF),
                const Color(0xFFE9F7FF),
                drift,
              )!,
              Color.lerp(
                const Color(0xFFD8FAF1),
                const Color(0xFFE4DFFF),
                drift,
              )!,
            ],
          ),
        ),
        child: Stack(
          children: [
            _AuroraOrb(
              alignment: Alignment(-1.12 + drift * .22, -.92 + drift * .12),
              size: 250,
              color: const Color(0xFF88A0FF).withValues(alpha: .34),
            ),
            _AuroraOrb(
              alignment: Alignment(.98 - drift * .18, -.36 + drift * .22),
              size: 205,
              color: const Color(0xFFD19EFF).withValues(alpha: .28),
            ),
            _AuroraOrb(
              alignment: Alignment(.52 + drift * .20, 1.08 - drift * .10),
              size: 270,
              color: const Color(0xFF6EE5C7).withValues(alpha: .25),
            ),
            _FloatingPill(
              alignment: Alignment(-.92 + drift * .13, .20),
              turn: drift * .55,
              color: const Color(0xFFFF86B9),
              icon: Icons.favorite_rounded,
            ),
            _FloatingPill(
              alignment: Alignment(.94 - drift * .12, .62),
              turn: -.22 - drift * .48,
              color: const Color(0xFF736BFF),
              icon: Icons.medication_rounded,
            ),
            _Sparkle(
              alignment: Alignment(-.58, -.45 + drift * .16),
              color: const Color(0xFFFFB742),
              size: 18,
            ),
            _Sparkle(
              alignment: Alignment(.78, -.80 + drift * .12),
              color: const Color(0xFF37DDBD),
              size: 14,
            ),
            _Sparkle(
              alignment: Alignment(.12 + drift * .18, .87),
              color: const Color(0xFFFF72B4),
              size: 13,
            ),
            Positioned.fill(child: child!),
          ],
        ),
      );
    },
  );
}

class _AuroraOrb extends StatelessWidget {
  const _AuroraOrb({
    required this.alignment,
    required this.size,
    required this.color,
  });
  final Alignment alignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    ),
  );
}

class _FloatingPill extends StatelessWidget {
  const _FloatingPill({
    required this.alignment,
    required this.turn,
    required this.color,
    required this.icon,
  });
  final Alignment alignment;
  final double turn;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Align(
      alignment: alignment,
      child: Transform.rotate(
        angle: turn,
        child: Container(
          width: 46,
          height: 31,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withValues(alpha: .92), color],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: .78)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: .48),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Transform.rotate(
            angle: -turn,
            child: Icon(icon, color: Colors.white, size: 16),
          ),
        ),
      ),
    ),
  );
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({
    required this.alignment,
    required this.color,
    required this.size,
  });
  final Alignment alignment;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Align(
      alignment: alignment,
      child: Icon(Icons.auto_awesome_rounded, color: color, size: size),
    ),
  );
}
