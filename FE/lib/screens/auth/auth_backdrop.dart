import 'package:flutter/material.dart';

class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEAF2FF), Color(0xFFF5F2FF), Color(0xFFE8FBF6)],
            ),
          ),
        ),
        const Positioned(
          top: -90,
          left: -70,
          child: _Orb(260, Color(0x5578A7F5)),
        ),
        const Positioned(
          bottom: -100,
          right: -60,
          child: _Orb(290, Color(0x4461D8BE)),
        ),
        const Positioned(
          top: 70,
          right: 60,
          child: _Orb(130, Color(0x33B58AF4)),
        ),
        SafeArea(child: child),
      ],
    ),
  );
}

class _Orb extends StatelessWidget {
  const _Orb(this.size, this.color);
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}
