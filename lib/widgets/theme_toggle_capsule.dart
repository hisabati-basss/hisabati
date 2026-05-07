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
            height: 32,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF2C2C2E).withValues(alpha: 0.5) : const Color(0xFFE5E5EA).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: widget.isDark ? Colors.white10 : Colors.black12),
            ),
            child: Stack(
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  alignment: widget.isDark ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isDark ? Colors.indigoAccent : Colors.orangeAccent,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.isDark ? Colors.indigoAccent : Colors.orangeAccent).withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: Icon(
                      widget.isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                      size: 13,
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
