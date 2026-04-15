import 'package:flutter/material.dart';
import 'dart:ui';

class ThemeToggleCapsule extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;
  const ThemeToggleCapsule({super.key, required this.isDark, required this.onToggle});

  @override
  State<ThemeToggleCapsule> createState() => _ThemeToggleCapsuleState();
}

class _ThemeToggleCapsuleState extends State<ThemeToggleCapsule> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            width: 70,
            height: 36,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF1A1A2E).withValues(alpha: 0.65) : Colors.white.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: widget.isDark ? Colors.white24 : Colors.black12),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  alignment: widget.isDark ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isDark ? Colors.indigoAccent : Colors.orangeAccent,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isDark ? Colors.indigoAccent : Colors.orangeAccent).withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Icon(
                      widget.isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
