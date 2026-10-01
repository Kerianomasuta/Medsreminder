import 'package:flutter/material.dart';

class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    onTapDown: (_) => setState(() => pressed = true),
    onTapCancel: () => setState(() => pressed = false),
    onTapUp: (_) => setState(() => pressed = false),
    child: AnimatedScale(
      duration: const Duration(milliseconds: 100),
      scale: pressed ? .96 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(0, pressed ? 3 : 0, 0),
        child: widget.child,
      ),
    ),
  );
}
